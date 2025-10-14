class InventoryAdjuster
  # Aplica un ajuste y actualiza el inventario
  # Todos los parámetros son obligatorios excepto :note
  def self.apply!(inventory:, quantity:, adjustment_type:, reason:, performed_by:, note: nil)
    raise ArgumentError, "Cantidad debe ser mayor a 0" if quantity.to_d <= 0

    InventoryAdjustment.transaction do
      # Crear el ajuste
      adjustment = InventoryAdjustment.create!(
        inventory:       inventory,
        quantity:        quantity.to_d,  # aseguramos decimal
        adjustment_type: adjustment_type,
        reason:          reason,
        performed_by:    performed_by,
        note:            note
      )

      # Actualizar inventario
      case adjustment_type.to_sym
      when :increase
        inventory.increment!(:quantity, quantity.to_d)
      when :decrease
        inventory.decrement!(:quantity, quantity.to_d)
      else
        raise ArgumentError, "Tipo de ajuste inválido"
      end

      adjustment
    end
  end
end