class Purchase < ApplicationRecord
  belongs_to :supplier
  belongs_to :warehouse
  has_many :purchase_items, dependent: :destroy

  accepts_nested_attributes_for :purchase_items, allow_destroy: true, reject_if: :all_blank

  validates :supplier, :warehouse, :purchase_date, presence: true
  validates :total, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true

  # Constante para definir días editables
  EDITABLE_DAYS = 15

  # Verifica si la compra puede editarse
  def editable?
    return true if processed_at.nil? # No procesada aún

    # Procesada hace menos de EDITABLE_DAYS
    processed_at > EDITABLE_DAYS.days.ago
  end

  # Calcula días desde que fue procesada
  def days_since_processed
    return nil if processed_at.nil?
    ((Time.current - processed_at) / 1.day).to_i
  end

  # Calcula el total sumando subtotales de items
  def calculate_total
    purchase_items.reject(&:marked_for_destruction?).sum(&:subtotal)
  end

  # Procesa la compra: actualiza inventario y registra movimientos
  def process_inventory!
    return if processed_at.present? # Ya fue procesada

    transaction do
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
          movement_type: :incoming,
          reason: :purchase,
          quantity: item.quantity_sale_units,
          source: self,
          note: "Compra ##{id} - #{item.product.name}"
        )
      end

      # Actualizar total y marcar como procesada
      update_columns(
        total: calculate_total,
        processed_at: Time.current
      )
    end
  end
end
