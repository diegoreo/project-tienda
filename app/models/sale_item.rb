class SaleItem < ApplicationRecord
  belongs_to :sale
  belongs_to :product
  
  # Validaciones
  validates :quantity, presence: true, numericality: { greater_than: 0 }
  validates :unit_price, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :discount, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
  validates :subtotal, presence: true, numericality: { greater_than_or_equal_to: 0 }
  
  # Métodos de cálculo
  def calculate_subtotal
    (quantity * unit_price) - (discount || 0)
  end
end