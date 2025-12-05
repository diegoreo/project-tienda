class CashRegisterFlow < ApplicationRecord
  has_paper_trail

  # ========== RELACIONES ==========
  belongs_to :register_session
  belongs_to :created_by, class_name: "User"
  belongs_to :authorized_by, class_name: "User"

  # ========== ENUMS ==========
  enum :movement_type, {
    inflow: 0,   # Ingreso (entrada de dinero)
    outflow: 1   # Egreso (salida de dinero)
  }

  # ========== VALIDACIONES ==========
  validates :register_session_id, presence: true
  validates :movement_type, presence: true
  validates :amount, presence: true, numericality: { 
    greater_than: 0,
    message: "debe ser mayor a $0" 
  }
  validates :description, presence: { 
    message: "es obligatoria (explica el motivo del movimiento)" 
  }, length: { 
    minimum: 5, 
    maximum: 500,
    too_short: "debe tener al menos 5 caracteres",
    too_long: "no puede exceder 500 caracteres"
  }
  validates :created_by_id, presence: true
  validates :authorized_by_id, presence: { 
    message: "debe estar presente (Admin/Gerente/Supervisor)" 
  }

  # Validación: Solo se pueden crear movimientos en sesiones abiertas
  validate :session_must_be_open, on: :create

  # No se puede editar si está cancelado
  validate :cannot_edit_if_cancelled, on: :update

  # No se puede editar si la sesión está cerrada
  validate :cannot_edit_if_session_closed, on: :update

  # ========== SIN CALLBACKS - Lógica explícita en controlador/servicios ==========
  
  # ========== SCOPES ==========
  scope :inflows, -> { where(movement_type: :inflow) }
  scope :outflows, -> { where(movement_type: :outflow) }
  scope :ordered, -> { order(created_at: :desc) }
  scope :today, -> { where("DATE(created_at) = ?", Date.current) }
  scope :by_session, ->(session_id) { where(register_session_id: session_id) }
  scope :active, -> { where(cancelled: false) }

  # ========== MÉTODOS DE INSTANCIA ==========

  # Nombre del tipo de movimiento en español
  def type_name
    inflow? ? "Ingreso" : "Egreso"
  end

  # Color del badge según el tipo
  def badge_color
    inflow? ? "green" : "red"
  end

  # Icono según el tipo
  def icon
    inflow? ? "➕" : "➖"
  end

  # Símbolo para mostrar (+ o -)
  def sign
    inflow? ? "+" : "-"
  end

  # Nombre para mostrar
  def display_name
    "#{type_name} - $#{amount}"
  end

  # Descripción corta (primeros 50 caracteres)
  def short_description
    description.truncate(50)
  end

  # Verificar si puede editarse
  def can_be_edited?
    !cancelled? && register_session.open?
  end

  # Validar que la sesión esté abierta
  def session_must_be_open
    if register_session && !register_session.open?
      errors.add(:base, "Solo se pueden registrar movimientos en sesiones abiertas")
    end
  end

  # Actualizar contadores de la sesión
  

  # Verificar si está activo (no cancelado)
  def active?
    !cancelled?
  end


  

  # Verificar si puede cancelarse
  def can_be_cancelled?
    !cancelled? && register_session.open?
  end

  def update_session_counters!
    return if cancelled? # No actualizar si está cancelado

    if inflow?
      # Si es ingreso, SUMAR al total de ingresos
      register_session.increment!(:total_inflows, amount)
    elsif outflow?
      # Si es egreso, SUMAR al total de egresos
      register_session.increment!(:total_outflows, amount)
    end

    # Actualizar el balance esperado
    register_session.update_expected_balance!
  end

  private

  # ... (métodos privados existentes)

  # No permitir editar si está cancelado
  def cannot_edit_if_cancelled
    if cancelled? && !cancelled_changed?
      errors.add(:base, "No se puede editar un movimiento cancelado")
    end
  end

  # No permitir editar si la sesión está cerrada
  def cannot_edit_if_session_closed
    if register_session && !register_session.open?
      errors.add(:base, "No se puede editar movimientos de una sesión cerrada")
    end
  end

  # Verificar si cambió el monto o el tipo
  def saved_change_to_amount_or_type?
    saved_change_to_amount? || saved_change_to_movement_type?
  end

  

end