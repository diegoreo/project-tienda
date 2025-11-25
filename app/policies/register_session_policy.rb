class RegisterSessionPolicy < ApplicationPolicy
  class Scope < Scope
    def resolve
      if user.admin? || user.gerente?
        # Admin y gerente ven todas las sesiones
        scope.all
      elsif user.supervisor? || user.contador?
        # Supervisor y contador ven todas las del día
        scope.where("DATE(opened_at) = ?", Date.current)
      elsif user.cajero?
        # Cajero solo ve sus propias sesiones
        scope.where(opened_by: user)
      else
        scope.none
      end
    end
  end

  # Ver listado de sesiones
  def index?
    user.cajero? || user.supervisor? || user.contador? || user.gerente? || user.admin?
  end

  # Ver detalle de una sesión
  def show?
    if user.admin? || user.gerente? || user.contador?
      true
    elsif user.supervisor?
      # Supervisor puede ver sesiones del día
      record.opened_at.to_date == Date.current
    elsif user.cajero? || user.almacenista?
      # 🔥 Cajeros y almacenistas NO pueden ver detalles
      false
    else
      false
    end
  end


  # Abrir turno (crear sesión)
  def create?
    # Solo cajeros y superiores pueden abrir turnos
    user.cajero? || user.supervisor? || user.gerente? || user.admin?
  end

  # Cerrar turno propio
  def close?
    return false unless record.open?

    if user.admin? || user.gerente?
      # Admin y gerente pueden cerrar cualquier sesión
      true
    elsif user.supervisor?
      # Supervisor puede cerrar cualquier sesión del día
      record.opened_at.to_date == Date.current
    elsif user.cajero?
      # Cajero solo puede cerrar su propia sesión
      record.opened_by == user
    else
      false
    end
  end

  # Procesar el cierre (mismo permiso que close?)
  def process_close?
    close?
  end

  # Cerrar turno de otro usuario
  def close_other?
    user.supervisor? || user.gerente? || user.admin?
  end

  # REPORTE BÁSICO - TODOS menos almacenista
  def closure_report?
    return false unless record.closed?

    # Almacenista NO puede ver reportes
    return false if user.almacenista?

    if user.admin? || user.gerente? || user.contador? || user.supervisor?
      true
    elsif user.cajero?
      # Cajero solo ve sus propios reportes
      record.opened_by == user
    else
      false
    end
  end

  # REPORTE DETALLADO - Solo Admin y Gerente
  def closure_report_detailed?
    return false unless record.closed?
    user.gerente? || user.admin?
  end

  # Ver diferencias de efectivo
  def view_cash_differences?
    user.supervisor? || user.contador? || user.gerente? || user.admin?
  end

  # Reabrir sesión cerrada (solo emergencias)
  def reopen?
    user.gerente? || user.admin?
  end

  # Ver reporte de cierre
  # def closure_report?
  # show?
  # end

  # Editar notas de cierre
  def edit_closing_notes?
    return false unless record.closed?
    user.supervisor? || user.gerente? || user.admin?
  end

  # Eliminar sesión (solo si no tiene ventas)
  def destroy?
    return false unless user.gerente? || user.admin?
    record.sales.empty?
  end
end
