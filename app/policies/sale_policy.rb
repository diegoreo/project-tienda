class SalePolicy < ApplicationPolicy
  # Ver listado de ventas
  def index?
    cashier? # Cajeros y superiores pueden ver ventas
  end

  # Ver detalle de venta
  def show?
    cashier? # Cajeros y superiores pueden ver detalles
  end

  # Crear nueva venta
  def create?
    cashier? # Cajero y superiores
  end

  # Editar venta (normalmente no se permite)
  def update?
    false # Las ventas no se editan una vez creadas
  end

  # Cancelar venta
  def destroy?
    # Solo ventas del mismo día y solo supervisor o superior
    return false unless supervisor?
    return true if admin? || manager?
    
    # Supervisor solo puede cancelar del día actual
    record.created_at.to_date == Date.current
  end
  
  # Aplicar descuentos mayores
  def apply_discount?
    supervisor? # Supervisor o superior
  end
  
  # Ver ventas a crédito
  def view_credit_sales?
    cashier? # Cajeros y superiores pueden ver ventas a crédito
  end
  
  # Ver todas las ventas (no solo del turno)
  def view_all_sales?
    cashier? # Cajeros y superiores pueden ver todas las ventas
  end
  
  # Generar reportes de ventas
  def generate_reports?
    accountant? # Contador, Gerente o Admin
  end

  class Scope < Scope
    def resolve
      # Todos los usuarios autenticados pueden ver todas las ventas
      # Los cajeros necesitan consultar ventas anteriores y de otros turnos
      scope.all
    end
  end
end