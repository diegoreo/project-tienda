class PurchaseItem < ApplicationRecord
  belongs_to :purchase
  belongs_to :product

  # Validaciones
  validates :quantity, numericality: { greater_than: 0 }
  validates :unit_cost, numericality: { greater_than_or_equal_to: 0 }
  validates :conversion_factor, numericality: { greater_than: 0 }
  validates :quantity_sale_units, numericality: { greater_than_or_equal_to: 0 }

  # Calcula quantity_sale_units antes de validar
  before_validation :set_quantity_sale_units

  private

  def set_quantity_sale_units
    self.quantity_sale_units = (quantity || 0) * (conversion_factor || 0)
  end
end
