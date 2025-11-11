class RegisterPolicy < ApplicationPolicy
  class Scope < Scope
    def resolve
      if user.admin? || user.gerente?
        scope.all
      elsif user.cajero? || user.supervisor? || user.contador?
        scope.active
      else
        scope.none
      end
    end
  end
  
  # Ver listado de cajas
  def index?
    user.cajero? || user.supervisor? || user.contador? || user.gerente? || user.admin?
  end
  
  # Ver detalle de una caja
  def show?
    index?
  end
  
  # Crear nueva caja
  def create?
    user.gerente? || user.admin?
  end
  
  # Actualizar caja existente
  def update?
    user.gerente? || user.admin?
  end
  
  # Eliminar caja
  def destroy?
    return false unless user.gerente? || user.admin?
    # No se puede eliminar si tiene sesiones
    record.can_be_destroyed?
  end
  
  # Activar/Desactivar caja
  def toggle_active?
    user.gerente? || user.admin?
  end
  
  # Asignar a warehouse
  def assign_warehouse?
    user.gerente? || user.admin?
  end
  
  # Cambiar fondo inicial
  def change_initial_balance?
    user.gerente? || user.admin?
  end
end