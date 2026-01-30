class CompanyPolicy < ApplicationPolicy
  def show?
    # Todos los usuarios autenticados pueden ver
    true
  end
  
  def edit?
    # Solo admin o gerente
    user.admin? || user.gerente?
  end
  
  def update?
    edit?
  end
end