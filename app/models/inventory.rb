class Inventory < ApplicationRecord
  belongs_to :product
  belongs_to :warehouse
  has_many :inventory_movements, dependent: :destroy
  has_many :inventory_adjustments, dependent: :destroy


  validates :quantity, numericality: true   # puede ser negativo si se vende sin stock
  validates :minimum_quantity, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true

  # Método para aplicar un ajuste
  def apply_adjustment(quantity:, adjustment_type:, reason:, performed_by:, note: nil)
    InventoryAdjustment.transaction do
      # Crea el ajuste
      inventory_adjustments.create!(
        quantity: quantity,
        adjustment_type: adjustment_type,
        reason: reason,
        performed_by: performed_by,
        note: note
      )

      # Actualiza la cantidad en inventario
      case adjustment_type.to_sym
      when :increase
        increment!(:quantity, quantity)
      when :decrease
        decrement!(:quantity, quantity)
      end
    end
  end
end
