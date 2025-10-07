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
  
  # Relaciones
  has_many :sales, dependent: :restrict_with_exception
  #has_many :payments, dependent: :restrict_with_exception
  
  # Scopes
  scope :with_debt, -> { where("current_debt > 0") }
  scope :by_type, ->(type) { where(customer_type: type) }
  
  # Métodos
  def available_credit
    return 0 if credit_limit.nil?
    credit_limit - current_debt
  end
  
  def can_buy_on_credit?(amount)
    return false if credit_limit.nil? || credit_limit.zero?
    available_credit >= amount
  end
  
  def full_name_with_debt
    debt_str = current_debt > 0 ? " (Debe: $#{current_debt})" : ""
    "#{name}#{debt_str}"
  end
end