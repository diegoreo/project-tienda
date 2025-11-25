# app/policies/purchase_policy.rb
class PurchasePolicy < ApplicationPolicy
  # Ver listado de compras
  def index?
    warehouse? # Almacenista y superiores
  end

  # Ver detalle de compra
  def show?
    warehouse? # Almacenista y superiores
  end

  # Crear nueva compra
  def create?
    warehouse? # Almacenista puede registrar compras
  end

  # Editar compra existente
  def update?
    return false unless warehouse? # Mínimo almacenista

    # El modelo ya tiene la lógica de editabilidad basada en:
    # - Si no está procesada: siempre editable
    # - Si está procesada: editable dentro de EDITABLE_DAYS (15 días)
    #
    # Agregamos lógica adicional de permisos:
    if record.editable?
      # Si es editable según el modelo, verificar permisos por rol
      if record.processed_at.nil?
        # No procesada: almacenista+ puede editar
        warehouse?
      else
        # Ya procesada: solo supervisor+ puede editar
        supervisor?
      end
    else
      # No es editable según el modelo (más de 15 días procesada)
      # Solo gerente puede forzar edición en casos excepcionales
      manager?
    end
  end

  # Eliminar compra
  def destroy?
    manager? # Solo gerente y admin
  end

  # Ver costos y precios de compra
  def view_costs?
    accountant? # Contador, gerente y admin
  end

  # Modificar proveedor de una compra existente
  def change_supplier?
    supervisor? # Solo supervisor y superiores
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      if user.admin? || user.role == "gerente"
        # Admin y gerente ven todo
        scope.all
      elsif user.role == "contador"
        # Contador ve todas las compras (para reportes)
        scope.all
      elsif user.role == "supervisor"
        # Supervisor ve todas las compras de su área
        scope.all
      elsif user.role == "almacenista"
        # Almacenista ve todas las compras
        scope.all
      else
        # Cajero no tiene acceso a compras
        scope.none
      end
    end
  end
end
