class PaymentPolicy < ApplicationPolicy
  def index?
    supervisor? # Supervisor o superior
  end

  def show?
    supervisor?
  end

  def create?
    cashier? # Cajeros y superiores pueden registrar pagos
  end

  def update?
    false # Los pagos no se editan
  end

  def destroy?
    manager? # Solo Gerente o Admin pueden eliminar pagos
  end

  # Ver todos los pagos (reportes)
  def view_all_payments?
    accountant? # Contador, Gerente o Admin
  end

  class Scope < Scope
    def resolve
      if user.admin? || user.manager? || user.accountant?
        scope.all
      elsif user.supervisor?
        scope.all
      else
        # Cajeros ven solo sus pagos
        scope.where(user_id: user.id)
      end
    end
  end
end
