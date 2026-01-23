class InventoryAdjuster
  # Aplica un ajuste y actualiza el inventario
  # Todos los parámetros son obligatorios excepto :note
  def self.apply!(inventory:, quantity:, adjustment_type:, reason:, performed_by:, note: nil)
    raise ArgumentError, "Cantidad debe ser mayor a 0" if quantity.to_d <= 0

    InventoryAdjustment.transaction do
      # Determinar el inventario que realmente se debe ajustar y la cantidad base
      if inventory.product.presentation?
        # Para presentaciones: ajustar el inventario del maestro
        target_inventory = inventory.product.master_product.inventories.find_by!(
          warehouse_id: inventory.warehouse_id
        )
        # Convertir cantidad de presentación a unidades base
        base_quantity = quantity.to_d * inventory.product.conversion_factor
        adjustment_note = "#{note} (#{quantity} × #{inventory.product.name} = #{base_quantity} unidades base)"
      else
        # Para productos base/master: ajustar directo
        target_inventory = inventory
        base_quantity = quantity.to_d
        adjustment_note = note
      end

      # Crear el ajuste (vinculado al inventario ORIGINAL para historial)
      adjustment = InventoryAdjustment.create!(
        inventory:       inventory, # Mantener referencia al inventario original
        quantity:        quantity.to_d,  # Cantidad en unidades de presentación/producto
        adjustment_type: adjustment_type,
        reason:          reason,
        performed_by:    performed_by,
        note:            adjustment_note
      )

      # Actualizar el inventario CORRECTO (maestro si es presentación)
      case adjustment_type.to_sym
      when :increase
        target_inventory.increment!(:quantity, base_quantity)
      when :decrease
        target_inventory.decrement!(:quantity, base_quantity)
      else
        raise ArgumentError, "Tipo de ajuste inválido"
      end

      adjustment
    end
  end
end
