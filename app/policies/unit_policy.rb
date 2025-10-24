# app/policies/unit_policy.rb
class UnitPolicy < ApplicationPolicy
  # Scope para filtrar unidades según el rol
  class Scope < Scope
    def resolve
      # Todos pueden ver todas las unidades
      scope.all
    end
  end

  # Ver lista de unidades - TODOS pueden ver
  def index?
    true  # ← Todos los usuarios autenticados
  end

  # Ver una unidad específica - TODOS pueden ver
  def show?
    true  # ← Todos los usuarios autenticados
  end

  # Crear nueva unidad - Solo supervisor y superiores
  def create?
    supervisor?
  end

  # Formulario de nueva unidad - Mismo permiso que create
  def new?
    create?
  end

  # Editar unidad - Solo supervisor y superiores
  def update?
    supervisor?
  end

  # Formulario de editar - Mismo permiso que update
  def edit?
    update?
  end

  # Eliminar unidad - Solo gerente y admin
  def destroy?
    manager?
  end
end