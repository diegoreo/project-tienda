class SalePolicy < ApplicationPolicy
  # Ver listado de ventas
  def index?
    # Cajero, Contador, Supervisor, Gerente, Admin (SIN almacenista)
    user.role.in?([ "cajero", "contador", "supervisor", "gerente", "admin" ])
  end

  # Ver detalle de venta
  def show?
    # Cajero, Contador, Supervisor, Gerente, Admin (SIN almacenista)
    user.role.in?([ "cajero", "contador", "supervisor", "gerente", "admin" ])
  end

  # Crear nueva venta
  def create?
    # SOLO: Cajero, Supervisor, Gerente, Admin (SIN contador ni almacenista)
    user.role.in?([ "cajero", "supervisor", "gerente", "admin" ])
  end

  # Formulario de nueva venta
  def new?
    create?
  end

  # Editar venta existente
  def edit?
    # SOLO: Gerente y Admin
    manager?
  end

  # Actualizar venta
  def update?
    # SOLO: Gerente y Admin
    manager?
  end

  # Cancelar venta (soft delete)
  def cancel?
    # SOLO: Supervisor, Gerente, Admin (SIN contador)
    user.role.in?([ "supervisor", "gerente", "admin" ])
  end

  # Eliminar venta (hard delete)
  def destroy?
    # SOLO: Gerente y Admin
    manager?
  end

  # Ver página de pagos de una venta
  def payments?
    # Cajero, Contador, Supervisor, Gerente, Admin (SIN almacenista)
    user.role.in?([ "cajero", "contador", "supervisor", "gerente", "admin" ])
  end

  # Ver costos, márgenes y totales financieros
  def view_costs?
    # Contador, Supervisor, Gerente, Admin (SIN cajero ni almacenista)
    accountant? # Este helper sí funciona bien para view_costs
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      case user.role
      when "cajero", "supervisor", "contador", "gerente", "admin"
        # Todos estos roles ven todas las ventas
        scope.all
      when "almacenista"
        # Almacenista NO tiene acceso a ventas
        scope.none
      else
        scope.none
      end
    end
  end
end
