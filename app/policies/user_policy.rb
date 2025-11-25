class UserPolicy < ApplicationPolicy
  # Solo admin puede ver el listado de usuarios
  def index?
    user.role == "admin"
  end

  # Solo admin puede ver detalles de usuarios
  def show?
    user.role == "admin"
  end

  # Solo admin puede crear usuarios
  def new?
    user.role == "admin"
  end

  def create?
    user.role == "admin"
  end

  # Solo admin puede editar usuarios
  def edit?
    user.role == "admin"
  end

  def update?
    user.role == "admin"
  end

  # Solo admin puede eliminar/desactivar usuarios
  def destroy?
    user.role == "admin"
  end

  # Solo admin puede activar/desactivar usuarios
  def toggle_active?
    user.role == "admin"
  end

  # Scope para admin (ve todos los usuarios)
  class Scope < Scope
    def resolve
      if user.role == "admin"
        scope.all
      else
        scope.none
      end
    end
  end
end
