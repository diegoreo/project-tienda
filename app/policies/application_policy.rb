class ApplicationPolicy
  attr_reader :user, :record

  def initialize(user, record)
    @user = user
    @record = record
  end

  def index?
    false
  end

  def show?
    false
  end

  def create?
    false
  end

  def new?
    create?
  end

  def update?
    false
  end

  def edit?
    update?
  end

  def destroy?
    false
  end

  class Scope
    def initialize(user, scope)
      @user = user
      @scope = scope
    end

    def resolve
      raise NotImplementedError, "You must define #resolve in #{self.class}"
    end

    private

    attr_reader :user, :scope
  end

  private

  # Helpers para verificar roles (EN ESPAÑOL - coinciden con tu enum)
  # De menor a mayor jerarquía según tu modelo

  # Solo admin
  def admin?
    user.role == "admin"
  end

  # Gerente y admin
  def manager?
    user.role.in?([ "gerente", "admin" ])
  end

  # Contador y superiores
  def accountant?
    user.role.in?([ "contador", "gerente", "admin" ])
  end

  # Supervisor y superiores
  def supervisor?
    user.role.in?([ "supervisor", "contador", "gerente", "admin" ])
  end

  # Almacenista y superiores
  def warehouse?
    user.role.in?([ "almacenista", "supervisor", "contador", "gerente", "admin" ])
  end

  # Cajero y superiores (TODOS los roles)
  def cashier?
    user.role.in?([ "cajero", "almacenista", "supervisor", "contador", "gerente", "admin" ])
  end

  # Verificar si el usuario es dueño del registro
  def owner?
    record.respond_to?(:user_id) && record.user_id == user.id
  end
end
