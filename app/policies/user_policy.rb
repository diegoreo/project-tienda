class UserPolicy < ApplicationPolicy
  def index?
    manager? # Solo Gerente o Admin pueden ver usuarios
  end

  def show?
    # Puedes ver tu propio perfil o si eres gerente/admin
    owner? || manager?
  end

  def create?
    admin? # Solo Admin puede crear usuarios
  end

  def update?
    # Puedes editar tu perfil o si eres admin
    owner? || admin?
  end

  def destroy?
    admin? # Solo Admin puede eliminar usuarios
  end
  
  # Cambiar rol de usuario
  def change_role?
    admin? # Solo Admin
  end
  
  # Ver todos los usuarios
  def view_all?
    manager?
  end
  
  # Resetear contraseña de otro usuario
  def reset_password?
    admin?
  end

  class Scope < Scope
    def resolve
      if user.admin? || user.manager?
        scope.all
      else
        scope.where(id: user.id) # Solo ve su propio usuario
      end
    end
  end
end