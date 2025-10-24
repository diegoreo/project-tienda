class InventoryPolicy < ApplicationPolicy
  # Ver inventario
  def index?
    true # Todos pueden ver inventario
  end

  def show?
    true
  end

  # Crear movimientos de inventario
  def create?
    warehouse? # Almacenista o superior
  end

  # Editar inventario
  def update?
    warehouse? # Almacenista o superior
  end

  # Eliminar registro de inventario
  def destroy?
    manager? # Solo Gerente o Admin
  end
  
  # Hacer ajustes de inventario
  def adjust?
    warehouse? # Almacenista o superior
  end
  
  # Aprobar ajustes de inventario
  def approve_adjustment?
    supervisor? # Supervisor o superior
  end
  
  # Ver reportes de inventario
  def view_reports?
    supervisor? # Supervisor o superior
  end
  
  # Ver valorización de inventario
  def view_valuation?
    accountant? # Contador, Gerente o Admin
  end

  class Scope < Scope
    def resolve
      scope.all
    end
  end
end