class Payment < ApplicationRecord
  has_paper_trail
  # Enums
  enum :payment_method, {
    cash: 0,
    card: 1,
    transfer: 2,
    check: 3
  }

  # Relaciones
  belongs_to :customer
  belongs_to :sale, optional: true

  has_many :payment_applications, dependent: false
  has_many :applied_sales, through: :payment_applications, source: :sale

  # Validaciones
  validates :amount, presence: true, numericality: {
    greater_than: 0,
    message: "debe ser mayor a $0"
  }
  validates :payment_date, presence: true
  validates :payment_method, presence: true
  validate :amount_not_exceed_customer_debt
  validate :amount_not_exceed_sale_pending, if: :sale_id?
  # Venta debe tener saldo pendiente
  validate :sale_must_have_pending_amount, if: :sale_id?

  validate :payment_date_cannot_be_future

  # Callbacks - NO USAR callbacks según tu estándar,
  # pero para actualizar deuda es necesario
  # Si prefieres hacerlo manual en el controller, comenta estas líneas
  after_create :update_customer_debt
  before_destroy :revert_customer_debt

  # Scopes
  scope :recent, -> { order(payment_date: :desc, created_at: :desc) }
  scope :by_customer, ->(customer_id) { where(customer_id: customer_id) }
  scope :by_date_range, ->(start_date, end_date) { where(payment_date: start_date..end_date) }

  private

  def amount_not_exceed_customer_debt
    return unless customer && amount

    if amount > customer.current_debt
      errors.add(:amount,
        "⚠️ El abono de $#{amount.round(2)} excede la deuda actual de $#{customer.current_debt.round(2)}. " \
        "El abono máximo permitido es $#{customer.current_debt.round(2)}."
      )
    end
  end

  def amount_not_exceed_sale_pending
    return unless sale && amount

    if amount > sale.pending_amount
      errors.add(:amount,
        "⚠️ El abono de $#{amount.round(2)} excede el saldo pendiente de $#{sale.pending_amount.round(2)}. " \
        "El abono máximo permitido es $#{sale.pending_amount.round(2)}."
      )
    end
  end

  # Venta debe tener saldo pendiente para hacer abono, si esta pagada completamente no se puede hacer abono
  def sale_must_have_pending_amount
    return unless sale

    if sale.pending_amount.nil? || sale.pending_amount.zero?
      errors.add(:base,
        "⚠️ La venta ##{sale.id} ya está completamente pagada. " \
        "No se pueden registrar más abonos a esta venta."
      )
    end
  end

  def update_customer_debt
    # Actualizar deuda del cliente
    customer.update_column(:current_debt, customer.current_debt - amount)

    # Si está asociado a una venta específica → aplicar solo a esa venta
    if sale
      apply_to_specific_sale
    else
      # Si NO está asociado → aplicar automáticamente a ventas pendientes (FIFO)
      apply_to_pending_sales
    end
  end

  # Aplicar a venta específica
  def apply_to_specific_sale
    # Calcular nuevo saldo pendiente
    new_pending = sale.pending_amount - amount

    # Determinar nuevo payment_status
    new_status = if new_pending.zero?
      :paid
    elsif new_pending < sale.total
      :partial
    else
      :pending
    end

    # Registrar la aplicación
    PaymentApplication.create!(
      payment: self,
      sale: sale,
      amount_applied: amount,
      notes: "Aplicado directamente a venta ##{sale.id}"
    )

    # Actualizar la venta
    sale.update_columns(
      pending_amount: [ new_pending, 0 ].max,  # No permitir negativo
      payment_status: new_status
    )
  end

  # Aplicar automáticamente a ventas pendientes (FIFO)
  def apply_to_pending_sales
    # Obtener ventas pendientes del cliente (más antiguas primero)
    pending_sales = customer.pending_sales.reorder(sale_date: :asc, created_at: :asc)

    amount_remaining = amount

    pending_sales.each do |pending_sale|
      break if amount_remaining <= 0

      # Calcular cuánto aplicar a esta venta
      amount_to_apply = [ amount_remaining, pending_sale.pending_amount ].min

      # Actualizar saldo pendiente de la venta
      new_pending = pending_sale.pending_amount - amount_to_apply

      # Determinar nuevo payment_status
      new_status = if new_pending.zero?
        :paid
      elsif new_pending < pending_sale.total
        :partial
      else
        :pending
      end

      # Registrar la aplicación
      PaymentApplication.create!(
        payment: self,
        sale: pending_sale,
        amount_applied: amount_to_apply,
        notes: "Aplicado automáticamente (FIFO) - Abono general"
      )

      # Actualizar la venta
      pending_sale.update_columns(
        pending_amount: new_pending,
        payment_status: new_status
      )

      # Reducir el monto restante
      amount_remaining -= amount_to_apply
    end
  end

  def revert_customer_debt
    # Revertir deuda del cliente
    customer.update_column(:current_debt, customer.current_debt + amount)

    # Cargar las aplicaciones ANTES de hacer cualquier cosa (mantenerlas en memoria)
    applications_to_revert = payment_applications.to_a

    # Revertir todas las aplicaciones de este pago
    applications_to_revert.each do |application|
      # Revertir el saldo de cada venta afectada
      affected_sale = application.sale
      new_pending = affected_sale.pending_amount + application.amount_applied

      # Determinar nuevo payment_status
      new_status = if new_pending >= affected_sale.total
        :pending
      elsif new_pending > 0 && new_pending < affected_sale.total
        :partial
      else
        :paid
      end

      # Actualizar la venta
      affected_sale.update_columns(
        pending_amount: new_pending,
        payment_status: new_status
      )
    end

    # Eliminar las aplicaciones AL FINAL
    PaymentApplication.where(id: applications_to_revert.map(&:id)).delete_all
  end

  def payment_date_cannot_be_future
    return unless payment_date.present?
    
    if payment_date > Date.current
      errors.add(:payment_date, 
        "no puede ser una fecha futura. " \
        "Fecha actual: #{Date.current.strftime('%d/%m/%Y')}"
      )
    end
  end
end
