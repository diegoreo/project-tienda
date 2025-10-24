class ProductPolicy < ApplicationPolicy
  # Ver listado de productos
  def index?
    true # Todos los usuarios autenticados pueden ver productos
  end

  # Ver detalle de un producto
  def show?
    true # Todos pueden ver los detalles
  end

  # Crear nuevo producto
  def create?
    warehouse? # Almacenista, Supervisor, Gerente o Admin
  end

  # Editar producto
  def update?
    warehouse? # Almacenista, Supervisor, Gerente o Admin
  end

  # Eliminar producto
  def destroy?
    manager? # Solo Gerente o Admin
  end
  
  # Actualizar precios
  def update_prices?
    manager? # Solo Gerente o Admin pueden cambiar precios
  end
  
  # Ver costos de compra
  def view_costs?
    accountant? # Contador, Gerente o Admin
  end

  class Scope < Scope
    def resolve
      scope.all # Todos ven todos los productos
    end
  end
end