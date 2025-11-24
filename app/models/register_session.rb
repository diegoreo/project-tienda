class RegisterSession < ApplicationRecord
  # ========== RELACIONES ==========
  belongs_to :register
  belongs_to :opened_by, class_name: 'User'
  belongs_to :closed_by, class_name: 'User', optional: true
  has_many :sales, dependent: :restrict_with_error
  
  # ========== ENUMS ==========
  enum :status, {
    open: 0,
    closed: 1
  }
  
  # ========== VALIDACIONES ==========
  validates :register_id, presence: true
  validates :opened_by_id, presence: true
  validates :opened_at, presence: true
  validates :opening_balance, numericality: { greater_than_or_equal_to: 0 }
  validates :status, presence: true
  
  # Validación personalizada: solo una sesión abierta por caja
  validate :only_one_open_session_per_register, on: :create
  # validaciones cierre debe ser 0  o mayor y no negativo
  validates :closing_balance, numericality: { 
    greater_than_or_equal_to: 0,
    message: "debe ser mayor o igual a $0"
  }, if: :closed?

  validates :closed_by_id, presence: { 
    message: "debe estar presente al cerrar la sesión"
  }, if: :closed?

  validates :closed_at, presence: { 
    message: "debe estar presente al cerrar la sesión"
  }, if: :closed?

  # Validaciones personalizadas de cierre
  validate :cannot_close_already_closed_session, if: :closed_at_changed?
  validate :closed_at_must_be_after_opened_at, if: :closed?
  
  # ========== SCOPES ==========
  scope :open_sessions, -> { where(status: :open) }
  scope :closed_sessions, -> { where(status: :closed) }
  scope :by_register, ->(register_id) { where(register_id: register_id) }
  scope :by_date, ->(date) { where('DATE(opened_at) = ?', date) }
  scope :today, -> { where('DATE(opened_at) = ?', Date.current) }
  scope :ordered, -> { order(opened_at: :desc) }
  
  # ========== MÉTODOS DE LECTURA (usan columnas de contador) ==========
  
  # Estos métodos simplemente leen las columnas que ya se actualizan con callbacks
  # No calculan nada, solo retornan el valor almacenado
  
  def total_sales
    read_attribute(:total_sales) || 0.0
  end
  
  def total_cash_sales
    read_attribute(:total_cash_sales) || 0.0
  end
  
  def total_card_sales
    read_attribute(:total_card_sales) || 0.0
  end
  
  def total_credit_sales
    read_attribute(:total_credit_sales) || 0.0
  end
  
  def sales_count
    read_attribute(:sales_count) || 0
  end
  
  def cancelled_sales_count
    read_attribute(:cancelled_sales_count) || 0
  end
  
  def cancelled_sales_total
    read_attribute(:cancelled_sales_total) || 0.0
  end
  
  # ========== MÉTODOS DE ESTADO ==========
  
  # Verificar si está abierta
  def open?
    status == 'open' && closed_at.nil?
  end
  
  # Verificar si está cerrada
  def closed?
    status == 'closed' && closed_at.present?
  end
  
  # ========== MÉTODOS DE BALANCE ==========
  
  # Efectivo esperado en caja al cierre
  def expected_balance
    opening_balance + total_cash_sales
  end
  
  # Calcular balance esperado (actualizar columna)
  def calculate_expected_balance
    opening_balance + total_cash_sales
  end
  
  # Actualizar balance esperado
  def update_expected_balance!
    update_column(:expected_balance, calculate_expected_balance)
  end
  
  # Diferencia entre esperado y contado
  def difference
    return nil unless closed?
    closing_balance - expected_balance
  end
  
  # Calcular diferencia (cierre - esperado)
  def calculate_difference
    return nil if closing_balance.nil? || expected_balance.nil?
    closing_balance - expected_balance
  end
  
  # Actualizar diferencia
  def update_difference!
    update_column(:difference, calculate_difference)
  end
  
  # Verificar si hay faltante
  def has_shortage?
    difference.present? && difference.negative?
  end
  
  # Verificar si hay sobrante
  def has_surplus?
    difference.present? && difference.positive?
  end
  
  # Monto del faltante
  def shortage_amount
    has_shortage? ? difference.abs : 0
  end
  
  # Monto del sobrante
  def surplus_amount
    has_surplus? ? difference : 0
  end
  
  # ========== MÉTODOS DE TIEMPO ==========
  
  # Duración del turno en horas
  def duration_in_hours
    return nil if closed_at.nil?
    ((closed_at - opened_at) / 1.hour).round(2)
  end
  
  # ========== MÉTODOS DE CANCELACIONES ==========
  
  # Calcular porcentaje de cancelaciones
  def cancellation_rate
    total_transactions = sales_count + cancelled_sales_count
    return 0 if total_transactions.zero?
    (cancelled_sales_count.to_f / total_transactions * 100).round(2)
  end
  
  # Verificar si el porcentaje es alto
  def high_cancellation_rate?
    cancellation_rate > 10
  end
  
  # Verificar si es crítico
  def critical_cancellation_rate?
    cancellation_rate > 20
  end
  
  # Color del badge según tasa
  def cancellation_badge_color
    return 'green' if cancellation_rate < 5
    return 'yellow' if cancellation_rate < 10
    return 'orange' if cancellation_rate < 20
    'red'
  end
  
  # ========== MÉTODOS DE ACTUALIZACIÓN DE CONTADORES ==========
  
  # Incrementar contadores cuando se crea una venta
  def increment_sale_counters(sale)
    increment!(:sales_count)
    increment!(:total_sales, sale.total)
    
    case sale.payment_method
    when 'cash'
      increment!(:total_cash_sales, sale.total)
    when 'card'
      increment!(:total_card_sales, sale.total)
    when 'credit'
      increment!(:total_credit_sales, sale.total)
    when 'mixed'
      # Para pagos mixtos, sumar cada parte al contador correspondiente
      increment!(:total_cash_sales, sale.cash_amount) if sale.cash_amount
      increment!(:total_card_sales, sale.card_amount) if sale.card_amount
    end
  end
  
  # Decrementar contadores cuando se cancela una venta
  def decrement_sale_counters(sale)
    decrement!(:sales_count)
    decrement!(:total_sales, sale.total)
    
    case sale.payment_method
    when 'cash'
      decrement!(:total_cash_sales, sale.total)
    when 'card'
      decrement!(:total_card_sales, sale.total)
    when 'credit'
      decrement!(:total_credit_sales, sale.total)
    when 'mixed'
      # Para pagos mixtos, restar cada parte del contador correspondiente
      decrement!(:total_cash_sales, sale.cash_amount) if sale.cash_amount
      decrement!(:total_card_sales, sale.card_amount) if sale.card_amount
    end
  end
  
  # Incrementar contadores de cancelaciones
  def increment_cancelled_counters(sale)
    increment!(:cancelled_sales_count)
    increment!(:cancelled_sales_total, sale.total)
  end
  
  # ========== MÉTODOS DE ESTADÍSTICAS ==========
  
  # Ticket promedio
  def average_ticket
    return 0 if sales_count.zero?
    (total_sales / sales_count).round(2)
  end
  
  # Ventas por hora
  def sales_per_hour
    return 0 if duration_in_hours.nil? || duration_in_hours.zero?
    (sales_count.to_f / duration_in_hours).round(2)
  end
  
  # Total de transacciones (ventas + canceladas)
  def total_transactions
    sales_count + cancelled_sales_count
  end
  
  # ========== MÉTODOS DE CIERRE ==========
  
  # Verificar si puede cerrarse
  def can_be_closed?
    open?
  end
  
  # Nombre para mostrar
  def display_name
    "#{register.display_name} - Sesión ##{id}"
  end
  
  # Cerrar sesión (sin callbacks, se llama desde el controlador)
  def close_session!(closing_balance_amount, closed_by_user, notes = nil)
    return false unless can_be_closed?
    
    transaction do
      update!(
        status: :closed,
        closed_at: Time.current,
        closed_by: closed_by_user,
        closing_balance: closing_balance_amount,
        closing_notes: notes
      )
      
      update_expected_balance!
      update_difference!
    end
  end
  
  private
  
  # Validación: solo una sesión abierta por caja
  def only_one_open_session_per_register
    if register && register.current_session.present?
      errors.add(:base, "Ya existe una sesión abierta para esta caja")
    end
  end

  # No permitir cerrar sesión ya cerrada
  def cannot_close_already_closed_session
    if closed_at_was.present? && closed_at_changed?
      errors.add(:base, "Esta sesión ya está cerrada y no puede cerrarse nuevamente")
    end
  end

  # closed_at debe ser posterior a opened_at
  def closed_at_must_be_after_opened_at
    return unless closed_at.present? && opened_at.present?
    
    if closed_at <= opened_at
      errors.add(:closed_at, "debe ser posterior a la fecha de apertura")
    end
  end
end