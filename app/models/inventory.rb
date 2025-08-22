class Inventory < ApplicationRecord
  belongs_to :product
  belongs_to :warehouse
  has_many :inventory_movements, dependent: :destroy

  validates :quantity, numericality: true   # puede ser negativo si se vende sin stock
  validates :minimum_quantity, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
end