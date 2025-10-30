class InventoryAdjustmentPolicy < ApplicationPolicy
  # Ver listado de ajustes
  def index?
    cashier? # TODOS pueden ver ajustes históricos
  end

  # Ver detalle de ajuste
  def show?
    cashier? # TODOS pueden ver detalles de ajustes
  end

  # Crear nuevo ajuste
  def create?
    warehouse? # Almacenista+ puede crear ajustes
  end

  # Formulario de nuevo ajuste
  def new?
    create?
  end

  # Eliminar ajuste (generalmente no se debe permitir)
  def destroy?
    manager? # Solo gerente+ puede eliminar ajustes
  end

  # Ver costos en los ajustes
  def view_costs?
    supervisor? # Supervisor+ puede ver costos
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      # TODOS ven todos los ajustes
      scope.all
    end
  end
end