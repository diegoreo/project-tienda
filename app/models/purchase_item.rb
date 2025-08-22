class PurchaseItem < ApplicationRecord
  belongs_to :purchase
  belongs_to :product

  validates :quantity, numericality: { greater_than: 0 }
  validates :unit_cost, numericality: { greater_than_or_equal_to: 0 }
  validates :conversion_factor, numericality: { greater_than: 0 }
  validates :quantity_sale_units, numericality: { greater_than_or_equal_to: 0 }
end