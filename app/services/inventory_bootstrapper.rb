class InventoryBootstrapper
  # Atajo para llamar al servicio en una sola línea:
  # InventoryBootstrapper.call(product: ..., warehouse: ..., reason: ...)
  def self.call(product:, warehouse: nil, reason: nil)
    new(product, warehouse, reason).call
  end

  def initialize(product, warehouse = nil, reason = nil)
    @product   = product
    @warehouse = warehouse || Warehouse.first
    @reason    = reason
  end

  def call
    return unless @warehouse

    # Cantidad inicial expresada en unidades de venta
    initial_qty = (@product.stock_quantity || 0) * (@product.unit_conversion || 1)

    Inventory.transaction do
      # Encuentra el inventario o lo crea (lock = evita conflictos en concurrencia)
      inventory = Inventory.lock.find_or_initialize_by(product: @product, warehouse: @warehouse)

      previous  = inventory.quantity || 0
      delta     = initial_qty - previous   # diferencia entre lo que había y lo nuevo

      # Actualiza inventario con el valor calculado
      inventory.quantity = initial_qty
      inventory.save!

      # Si hay diferencia, registramos un movimiento
      if delta != 0
        InventoryMovement.create!(
          inventory:     inventory,
          movement_type: :incoming,                # enum: entrada
          reason:        @reason || :initial_stock,   # motivo por defecto stock inicial
          quantity:      delta,              # diferencia
          source:        @product,           # quién originó el movimiento (polymorphic)
          note:          "Carga inicial desde Product.stock_quantity"
        )
      end
    end
  end
end
