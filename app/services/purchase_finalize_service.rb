class PurchaseFinalizeService
  # call(purchase) -> guarda purchase, items, actualiza inventory y crea inventory_movements
  def self.call(purchase)
    new(purchase).call
  end

  def initialize(purchase)
    @purchase = purchase
  end

  def call
    ActiveRecord::Base.transaction do
      # 1) Calcula y asigna derived fields a cada purchase_item
      @purchase.purchase_items.each do |item|
        # Calculamos cantidad en unidades de venta
        item.quantity_sale_units = item.quantity_sale_units_calc

        # Calculamos subtotal y costo por pieza
        item.subtotal = item.quantity.to_f * item.purchase_price.to_f
        item.cost_per_piece = item.conversion_factor.to_f > 0 ? (item.purchase_price.to_f / item.conversion_factor.to_f) : item.purchase_price.to_f
      end

      # 2) Calcula el total y lo asigna
      total = @purchase.purchase_items.sum(&:subtotal)
      @purchase.total = total

      # 3) Guarda purchase + items (validaciones)
      @purchase.save!

      # 4) Actualiza inventarios y registra movimientos por item
      @purchase.purchase_items.each do |item|
        inventory = Inventory.find_or_create_by!(product: item.product, warehouse: @purchase.warehouse)
        inventory.quantity = (inventory.quantity.to_d + item.quantity_sale_units.to_d)
        inventory.save!

        InventoryMovement.create!(
          inventory: inventory,
          movement_type: :incoming,
          reason: :purchase,
          quantity: item.quantity_sale_units,
          source: @purchase,
          note: "Compra ##{@purchase.id} - #{item.product.name}"
        )
      end

      @purchase
    end
  end
end
