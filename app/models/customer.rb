class Customer < ApplicationRecord
  # Enums
  enum :customer_type, {
    walk_in: 0,      # Cliente de mostrador (ocasional)
    regular: 1,      # Cliente frecuente
    wholesale: 2     # Cliente mayorista
  }
  
  # Validaciones
  validates :name, presence: true
  validates :phone, format: { with: /\A\d{10}\z/, message: "debe tener 10 dígitos" }, allow_blank: true
  validates :email, format: { with: URI::MailTo::EMAIL_REGEXP }, allow_blank: true
  validates :rfc, format: { with: /\A[A-ZÑ&]{3,4}\d{6}[A-Z0-9]{3}\z/i }, allow_blank: true
  validates :credit_limit, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
  validates :current_debt, numericality: { greater_than_or_equal_to: 0 }
  # Deuda no puede exceder límite
  validate :debt_cannot_exceed_limit
  
  # Relaciones
  has_many :sales, dependent: :restrict_with_exception
  has_many :payments, dependent: :restrict_with_exception
  
  # Scopes
  scope :with_debt, -> { where("current_debt > 0") }
  scope :by_type, ->(type) { where(customer_type: type) }
  scope :active, -> { where(active: true) } # Si tienes campo active
  
  # Métodos
  def available_credit
    return 0 if credit_limit.nil?
    [credit_limit - current_debt, 0].max
  end
  
  def can_buy_on_credit?(amount)
    return false if credit_limit.nil? || credit_limit.zero?
    available_credit >= amount
  end
  
  def full_name_with_debt
    debt_str = current_debt > 0 ? " (Debe: $#{current_debt})" : ""
    "#{name}#{debt_str}"
  end
  
  # Ventas pendientes de pago (pendiente o parcial)
  def pending_sales
    sales.where(payment_status: [:pending, :partial])
         .where("pending_amount > 0")
         .order(sale_date: :desc)
  end
  
  # Total de ventas realizadas
  def total_sales_amount
    sales.sum(:total)
  end
  
  # Total de ventas a crédito (monto original sin contar pagos)
  def total_credit_sales
    sales.where(payment_method: :credit).sum(:total)
  end
  
  # Total pagado históricamente (abonos)
  def total_paid_amount
    payments.sum(:amount)
  end
  
  # Agregar deuda (cuando se crea venta a crédito)
  def add_debt!(amount)
    increment!(:current_debt, amount)
  end
  
  # Reducir deuda (cuando se registra pago)
  def reduce_debt!(amount)
    decrement!(:current_debt, amount)
  end
  
  private
  # 🔥 NUEVA VALIDACIÓN PERSONALIZADA
  def debt_cannot_exceed_limit
    # Solo validar si ambos valores están presentes
    return unless credit_limit.present? && current_debt.present?
    
    # Validar que la deuda no exceda el límite
    if current_debt > credit_limit
      errors.add(:current_debt, 
        "de $#{current_debt.round(2)} excede el límite de crédito de $#{credit_limit.round(2)}"
      )
    end
  end

end