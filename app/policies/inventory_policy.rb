class InventoryPolicy < ApplicationPolicy
  # Ver listado de inventarios
  def index?
    cashier? # TODOS pueden ver inventarios (incluyendo cajero)
  end

  # Ver detalle de inventario
  def show?
    cashier? # TODOS pueden ver detalles
  end

  # Ver movimientos de inventario
  def view_movements?
    cashier? # TODOS pueden ver movimientos
  end

  # Ver costos de inventario (precio unitario, valor total)
  def view_costs?
    supervisor? # Supervisor+ puede ver costos (ajuste solicitado)
  end

  # Exportar CSV
  def export?
    cashier? # TODOS pueden exportar
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      # TODOS los roles pueden ver inventarios
      scope.all
    end
  end
end
