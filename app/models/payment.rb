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
  validates :amount, presence: true, numericality: { greater_than: 0 }
  validates :payment_date, presence: true
  validates :payment_method, presence: true
  validate :amount_not_exceed_customer_debt
  validate :amount_not_exceed_sale_pending, if: :sale_id?
  
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
    if customer && amount && amount > customer.current_debt
      errors.add(:amount, "no puede ser mayor a la deuda actual (#{customer.current_debt})")
    end
  end
  
  def amount_not_exceed_sale_pending
    if sale && amount && amount > sale.pending_amount
      errors.add(:amount, "no puede ser mayor al saldo pendiente de la venta (#{sale.pending_amount})")
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