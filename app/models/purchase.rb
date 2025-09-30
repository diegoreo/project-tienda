class Purchase < ApplicationRecord
  belongs_to :supplier
  belongs_to :warehouse
  has_many :purchase_items, dependent: :destroy

  accepts_nested_attributes_for :purchase_items, allow_destroy: true, reject_if: :all_blank

  validates :supplier, :warehouse, :purchase_date, presence: true
  validates :total, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true

  # Método para calcular el total de la compra
  def calculate_total
    purchase_items.sum("quantity * purchase_price")
  end
  

  # Método para procesar la compra y actualizar inventarios
  def process_inventory!
    purchase_items.each do |item|
      # Buscar o crear inventario del producto en el almacén
      inventory = Inventory.find_or_create_by!(
        product: item.product,
        warehouse: warehouse
      )

      # Aumentar el stock
      inventory.quantity += item.quantity_sale_units
      inventory.save!

      # Registrar movimiento de inventario
      InventoryMovement.create!(
        inventory: inventory,
        movement_type: "incoming",
        reason: "purchase",
        quantity: item.quantity_sale_units,
        source: self, # referencia a la compra
        note: "Compra ##{id} - #{item.product.name}"
      )
    end

    # Actualizar el total de la compra
    update_column(:total, calculate_total)
  end
end
