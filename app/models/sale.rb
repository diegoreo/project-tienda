class Sale < ApplicationRecord
  belongs_to :customer, optional: true
  belongs_to :user, optional: true # quien hizo la venta
  belongs_to :warehouse
  belongs_to :register_session, optional: true  
  belongs_to :cancelled_by, class_name: 'User', optional: true  
  has_many :sale_items, dependent: :destroy
  has_many :products, through: :sale_items
  has_many :payments, dependent: :destroy
  
  accepts_nested_attributes_for :sale_items, allow_destroy: true, reject_if: :all_blank
  
  enum :payment_status, {
    paid: 0,      # Pagado completamente
    partial: 1,   # Pago parcial
    pending: 2    # Pendiente de pago (crédito)
  }
  
  enum :payment_method, {
    cash: 0,      # Efectivo
    card: 1,      # Tarjeta
    credit: 2,    # Crédito
    mixed: 3      # Mixto (efectivo + tarjeta)
  }
  
  enum :status, {
    completed: 0,   # Completada
    cancelled: 1    # Cancelada
  }
  
  # Validaciones
  validates :sale_date, presence: true
  validates :warehouse, presence: true
  validates :total, numericality: { greater_than_or_equal_to: 0 }
  validates :pending_amount, numericality: { greater_than_or_equal_to: 0 }
  validates :customer, presence: true, if: -> { payment_method == 'credit' }
  validate :customer_has_credit, if: -> { payment_method == 'credit' && customer.present? }
  validate :pending_amount_not_exceed_total
  validate :register_session_must_be_open, if: -> { register_session.present? && new_record? }
  
  # Scopes
  scope :completed, -> { where(status: :completed) }
  scope :cancelled, -> { where(status: :cancelled) }
  scope :active_sales, -> { where(status: :completed) }
  scope :today, -> { where(sale_date: Date.current) }
  scope :by_payment_method, ->(method) { where(payment_method: method) }
  scope :with_pending_payment, -> { where(payment_status: [:pending, :partial]).where("pending_amount > 0") }
  scope :by_register_session, ->(session_id) { where(register_session_id: session_id) }
  scope :cancelled_by_user, ->(user_id) { where(cancelled_by_id: user_id) }

  # ========== MÉTODOS NUEVOS PARA PAGOS ==========
  
  # Monto ya pagado
  def paid_amount
    total - pending_amount
  end
  
  # ¿Está completamente pagada?
  def fully_paid?
    pending_amount.zero?
  end
  
  # ¿Tiene saldo pendiente?
  def has_pending_amount?
    pending_amount > 0
  end
  
  # Actualizar deuda del cliente (llamar desde controller al crear venta)
  def update_customer_debt!
    return unless customer_id && payment_method == "credit"
    
    customer.update_column(:current_debt, customer.current_debt + pending_amount)
  end
  
  # Revertir deuda (si se cancela venta)
  def revert_customer_debt!
    return unless customer_id && has_pending_amount?
    
    customer.update_column(:current_debt, customer.current_debt - pending_amount)
  end
  
  # ========== FIN MÉTODOS NUEVOS ==========
  
  # Métodos existentes
  def calculate_total
    sale_items.reject(&:marked_for_destruction?).sum(&:subtotal)
  end
  
  def process_sale!
    return if cancelled?
    
    transaction do
      # Calcular total
      calculated_total = calculate_total
      
      # Establecer pending_amount según el método de pago
      if payment_method == 'credit'
        self.pending_amount = calculated_total
        self.payment_status = :pending
      else
        self.pending_amount = 0.0
        self.payment_status = :paid
      end
      
      self.total = calculated_total
      save!
      
      # Actualizar inventario
      sale_items.each do |item|
        inventory = Inventory.find_by!(
          product: item.product,
          warehouse: warehouse
        )
        
        inventory.quantity -= item.quantity
        inventory.save!
        
        # Registrar movimiento
        InventoryMovement.create!(
          inventory: inventory,
          movement_type: :outgoing,
          reason: :sale,
          quantity: item.quantity,
          source: self,
          note: "Venta ##{id} - #{item.product.name}"
        )
      end
      
      # Si es venta a crédito, actualizar deuda del cliente
      if payment_method == 'credit' && customer.present?
        update_customer_debt!
      end

      # Actualizar contadores de sesión si existe
      update_register_session_on_creation if register_session.present?
    end
  end
  
  # ========== MÉTODOS DE CANCELACIÓN ==========
  def can_be_cancelled?
    completed?
  end
  
  def cancel_sale!(cancelled_by_user, reason = nil)
    return unless can_be_cancelled?
    
    transaction do
      # Revertir inventario
      sale_items.each do |item|
        inventory = Inventory.find_or_create_by!(
          product: item.product,
          warehouse: warehouse
        )
        
        inventory.quantity += item.quantity
        inventory.save!
        
        InventoryMovement.create!(
          inventory: inventory,
          movement_type: :incoming,
          reason: :adjustment,
          quantity: item.quantity,
          source: self,
          note: "Cancelación venta ##{id} - #{item.product.name}"
        )
      end
      
      # Revertir deuda si hay pendiente
      if has_pending_amount? && customer.present?
        revert_customer_debt!
      end
      
      # Actualizar campos de cancelación
      update!(
        status: :cancelled,
        cancelled_at: Time.current,
        cancelled_by: cancelled_by_user,
        cancellation_reason: reason
      )
      
      # Actualizar contadores de la sesión (SIN callback)
      update_register_session_on_cancellation if register_session.present?
    end
  end
  
  # ========== MÉTODOS DE SESIÓN ==========
  # Actualizar contadores de sesión al cancelar
  def update_register_session_on_cancellation
    register_session.decrement_sale_counters(self)
    register_session.increment_cancelled_counters(self)
  end
  
  # Actualizar contadores de sesión al crear (llamar desde controlador)
  def update_register_session_on_creation
    return unless register_session.present? && completed?
    register_session.increment_sale_counters(self)
  end

  # ========== MÉTODOS DE AUDITORÍA ==========
  def sale_info
    {
      sold_by: user&.name,
      cancelled_by: cancelled_by&.name,
      cancelled_at: cancelled_at,
      cancellation_reason: cancellation_reason
    }
  end

  def self_cancelled?
    cancelled? && user_id == cancelled_by_id
  end
  
  private
  
  def customer_has_credit
    return unless customer
    
    unless customer.can_buy_on_credit?(total)
      errors.add(:base, "El cliente no tiene crédito suficiente. Disponible: #{customer.available_credit}")
    end
  end
  
  def pending_amount_not_exceed_total
    if pending_amount && total && pending_amount > total
      errors.add(:pending_amount, "no puede ser mayor al total de la venta")
    end
  end

  def register_session_must_be_open
    if register_session && !register_session.open?
      errors.add(:base, "No se puede registrar una venta en una sesión cerrada")
    end
  end
end