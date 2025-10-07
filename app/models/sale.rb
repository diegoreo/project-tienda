class Sale < ApplicationRecord
  belongs_to :customer, optional: true
  belongs_to :user, optional: true # quien hizo la venta
  belongs_to :warehouse
  has_many :sale_items, dependent: :destroy
  has_many :products, through: :sale_items
  has_many :payments, dependent: :destroy
  
  accepts_nested_attributes_for :sale_items, allow_destroy: true, reject_if: :all_blank
  
  # Enums
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
  validates :customer, presence: true, if: -> { payment_method == 'credit' }
  validate :customer_has_credit, if: -> { payment_method == 'credit' && customer.present? }
  
  # Scopes
  scope :completed, -> { where(status: :completed) }
  scope :today, -> { where(sale_date: Date.current) }
  scope :by_payment_method, ->(method) { where(payment_method: method) }
  
  # Métodos
  def calculate_total
    sale_items.reject(&:marked_for_destruction?).sum(&:subtotal)
  end
  
  def process_sale!
    return if status == 'cancelled'
    
    transaction do
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
        customer.current_debt += total
        customer.save!
      end
      
      update_column(:total, calculate_total)
    end
  end
  
  def can_be_cancelled?
    status == 'completed'
  end
  
  def cancel_sale!
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
      
      # Revertir deuda si es crédito
      if payment_method == 'credit' && customer.present?
        customer.current_debt -= total
        customer.save!
      end
      
      update!(status: :cancelled)
    end
  end
  
  private
  
  def customer_has_credit
    return unless customer
    
    unless customer.can_buy_on_credit?(total)
      errors.add(:base, "El cliente no tiene crédito suficiente. Disponible: #{customer.available_credit}")
    end
  end
end