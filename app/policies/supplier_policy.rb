class SupplierPolicy < ApplicationPolicy
  # Scope para filtrar proveedores según el rol
  class Scope < Scope
    def resolve
      # Todos pueden ver todos los proveedores
      scope.all
    end
  end

  # Ver lista de proveedores - TODOS pueden ver
  def index?
    true  # Todos los usuarios autenticados
  end

  # Ver un proveedor específico - TODOS pueden ver
  def show?
    true  # Todos los usuarios autenticados
  end

  # Crear nuevo proveedor - Solo supervisor y superiores
  def create?
    supervisor?
  end

  # Formulario de nuevo proveedor - Mismo permiso que create
  def new?
    create?
  end

  # Editar proveedor - Solo supervisor y superiores
  def update?
    supervisor?
  end

  # Formulario de editar - Mismo permiso que update
  def edit?
    update?
  end

  # Eliminar proveedor - Solo gerente y admin
  def destroy?
    manager?
  end
end