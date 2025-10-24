class WarehousePolicy < ApplicationPolicy
  class Scope < Scope
    def resolve
      scope.all  # Todos pueden ver todos
    end
  end

  def index?
    true  # ← TODOS
  end

  def show?
    true  # ← TODOS
  end

  def create?
    supervisor?  # ← Solo supervisor+
  end

  def new?
    create?
  end

  def update?
    supervisor?  # ← Solo supervisor+
  end

  def edit?
    update?
  end

  def destroy?
    manager?  # ← Solo gerente+
  end
end