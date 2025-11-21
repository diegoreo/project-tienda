class Payment < ApplicationRecord
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
  
  # Callbacks - NO USAR callbacks según tu estándar, 
  # pero para actualizar deuda es necesario
  # Si prefieres hacerlo manual en el controller, comenta estas líneas
  after_create :update_customer_debt
  after_destroy :revert_customer_debt
  
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
    customer.update_column(:current_debt, customer.current_debt - amount)
    
    # Si está asociado a una venta, actualizar su saldo pendiente
    if sale
      new_pending = sale.pending_amount - amount
      
      # Determinar nuevo payment_status
      new_status = if new_pending.zero?
        :paid
      elsif new_pending < sale.total
        :partial
      else
        :pending
      end
      
      sale.update_columns(
        pending_amount: new_pending,
        payment_status: new_status
      )
    end
  end
  
  def revert_customer_debt
    customer.update_column(:current_debt, customer.current_debt + amount)
    
    # Si está asociado a una venta, revertir su saldo
    if sale
      new_pending = sale.pending_amount + amount
      
      # Determinar nuevo payment_status
      new_status = if new_pending >= sale.total
        :pending
      else
        :partial
      end
      
      sale.update_columns(
        pending_amount: new_pending,
        payment_status: new_status
      )
    end
  end
end