class CustomerPolicy < ApplicationPolicy
  # Scope para filtrar clientes según el rol
  class Scope < Scope
    def resolve
      # Todos pueden ver todos los clientes
      scope.all
    end
  end

  # Ver lista de clientes - TODOS pueden ver
  def index?
    true  # Todos los usuarios autenticados
  end

  # Ver un cliente específico - TODOS pueden ver
  def show?
    true  # Todos los usuarios autenticados
  end

  # Crear nuevo cliente - Cajero y superiores
  # (Cajeros necesitan poder registrar nuevos clientes al vender)
  def create?
    cashier?  # Cajero, Almacenista, Supervisor, Contador, Gerente, Admin
  end

  # Formulario de nuevo cliente - Mismo permiso que create
  def new?
    create?
  end

  # Editar cliente - Cajero y superiores
  # (Pueden editar datos básicos pero NO el límite de crédito)
  def update?
    cashier?
  end

  # Formulario de editar - Mismo permiso que update
  def edit?
    update?
  end

  # Eliminar cliente - Solo gerente y admin
  def destroy?
    manager?
  end

  # PERMISO ESPECIAL: Modificar límite de crédito
  # Solo gerentes y admins pueden cambiar el límite de crédito
  def update_credit_limit?
    manager?
  end
end