class CashRegisterFlowPolicy < ApplicationPolicy
  # Permisos por rol:
  # - Admin: TODO (ver, crear, editar, cancelar)
  # - Gerente: Ver, Crear, Editar, Cancelar
  # - Supervisor: Ver, Crear
  # - Contador: Ver
  # - Cajero: Ver solo de sus propias sesiones

  def index?
    user.admin? || user.gerente? || user.supervisor? || user.contador? || user.cajero?
  end

  def show?
    user.admin? || user.gerente? || user.supervisor? || user.contador? || 
    (user.cajero? && record.register_session.opened_by == user)
  end

  def new?
    can_create?
  end

  def create?
    can_create?
  end

  def edit?
    can_edit?
  end

  def update?
    can_edit?
  end

  def destroy?
    false # No se pueden eliminar, solo editar o cancelar
  end

  def cancel?
    can_edit? # Mismo permiso que editar
  end

  # Scope: Qué registros puede ver cada rol
  class Scope < ApplicationPolicy::Scope
    def resolve
      if user.admin? || user.gerente? || user.supervisor? || user.contador?
        # Admin/Gerente/Supervisor/Contador ven todos
        scope.all
      elsif user.cajero?
        # Cajero solo ve movimientos de sus propias sesiones
        scope.joins(:register_session)
             .where(register_sessions: { opened_by_id: user.id })
      else
        # Almacenista no ve nada
        scope.none
      end
    end
  end

  private

  # Solo Admin, Gerente y Supervisor pueden crear movimientos
  def can_create?
    user.admin? || user.gerente? || user.supervisor?
  end

  # Solo Admin y Gerente pueden editar
  # Solo en sesión abierta
  def can_edit?
    (user.admin? || user.gerente?) && 
    record.register_session.open? &&
    !record.cancelled?
  end
end