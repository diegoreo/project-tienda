module Purchases
  class CreatePurchase
    def initialize(purchase_params)
      @purchase_params = purchase_params
    end

    def call
      ActiveRecord::Base.transaction do
        # 1️⃣ Crear la compra con sus items
        purchase = Purchase.new(@purchase_params)

        purchase.purchase_items.each do |item|
          # 2️⃣ Calcular quantity_sale_units explícitamente
          item.quantity_sale_units = item.quantity * item.conversion_factor
        end

        purchase.save!

        # 3️⃣ Actualizar inventarios y registrar movimientos
        purchase.purchase_items.each do |item|
          inventory = Inventory.find_or_create_by!(
            product: item.product,
            warehouse: purchase.warehouse
          )

          # aumentar stock
          inventory.quantity += item.quantity_sale_units
          inventory.save!

          # movimiento de entrada
          InventoryMovement.create!(
            inventory: inventory,
            movement_type: "incoming",
            reason: "purchase",
            quantity: item.quantity_sale_units,
            source: purchase,
            note: "Compra ##{purchase.id} - #{item.product.name}"
          )
        end

        # 4️⃣ Guardar el total de la compra
        purchase.update!(total: purchase.calculate_total)

        purchase
      end
    rescue ActiveRecord::RecordInvalid => e
      # podrías manejar errores de validación aquí
      raise e
    end
  end
end
