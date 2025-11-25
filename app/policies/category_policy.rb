class CategoryPolicy < ApplicationPolicy
  # Scope para filtrar categorías según el rol
  class Scope < Scope
    def resolve
      # Todos pueden ver todas las categorías
      scope.all
    end
  end

  # Ver lista de categorías - Todos pueden ver
  def index?
    true
  end

  # Ver una categoría específica - Todos pueden ver
  def show?
    true
  end

  # Crear nueva categoría - Solo supervisor y superiores
  def create?
    supervisor?
  end

  # Formulario de nueva categoría - Mismo permiso que create
  def new?
    create?
  end

  # Editar categoría - Solo supervisor y superiores
  def update?
    supervisor?
  end

  # Formulario de editar - Mismo permiso que update
  def edit?
    update?
  end

  # Eliminar categoría - Solo gerente y admin
  def destroy?
    manager?
  end
end
