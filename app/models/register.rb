class Register < ApplicationRecord
  # ========== RELACIONES ==========
  belongs_to :warehouse
  has_many :register_sessions, dependent: :restrict_with_error
  has_many :sales, through: :register_sessions

  # ========== VALIDACIONES ==========
  validates :code, presence: true, uniqueness: { case_sensitive: false }
  validates :name, presence: true
  validates :initial_balance, numericality: { greater_than_or_equal_to: 0 }
  validates :warehouse_id, presence: true

  # ========== SCOPES ==========
  scope :active, -> { where(active: true) }
  scope :inactive, -> { where(active: false) }
  scope :by_warehouse, ->(warehouse_id) { where(warehouse_id: warehouse_id) }
  scope :ordered, -> { order(:code) }

  # ========== MÉTODOS DE INSTANCIA ==========

  # Nombre completo para mostrar
  def display_name
    "#{code} - #{name}"
  end

  # Activar caja
  def activate!
    update(active: true)
  end

  # Desactivar caja (solo si no hay sesión abierta)
  def deactivate!
    if current_session.present?
      errors.add(:base, "No se puede desactivar una caja con sesión abierta")
      return false
    end
    update(active: false)
  end

  # Obtener la sesión actual (si está abierta)
  def current_session
    register_sessions.where(closed_at: nil).first
  end

  # Verificar si tiene una sesión abierta
  def session_open?
    current_session.present?
  end

  # Verificar si está disponible para abrir
  def available_for_opening?
    active? && !session_open?
  end

  # Verificar si se puede eliminar
  def can_be_destroyed?
    register_sessions.empty?
  end

  # ========== MÉTODOS DE ESTADÍSTICAS ==========

  # Total de sesiones
  def total_sessions
    register_sessions.count
  end

  # Total de sesiones cerradas
  def closed_sessions_count
    register_sessions.where.not(closed_at: nil).count
  end

  # Última sesión
  def last_session
    register_sessions.order(opened_at: :desc).first
  end

  # Total vendido histórico
  def total_sales_amount
    register_sessions.sum(:total_sales)
  end
end
