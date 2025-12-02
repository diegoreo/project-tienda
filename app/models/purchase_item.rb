class PurchaseItem < ApplicationRecord
  has_paper_trail
  belongs_to :purchase
  belongs_to :product

  # Validaciones
  validates :quantity, numericality: { greater_than: 0 }
  validates :purchase_price, numericality: { greater_than_or_equal_to: 0 }
  validates :conversion_factor, numericality: { greater_than: 0 }
  validates :quantity_sale_units, numericality: { greater_than_or_equal_to: 0 }
  validates :cost_per_piece, numericality: { greater_than_or_equal_to: 0 }
  validates :subtotal, numericality: { greater_than_or_equal_to: 0 }

  # Calcula cuántas unidades de venta resultan de la compra
  def quantity_sale_units_calc
    (quantity.to_d * conversion_factor.to_d).round(3)
  end

  # Calcula el subtotal de la fila
  def calculate_subtotal
    (quantity.to_d * purchase_price.to_d).round(2)
  end

  # Calcula el costo por pieza
  def calculate_cost_per_piece
    return 0 if conversion_factor.to_d <= 0
    (purchase_price.to_d / conversion_factor.to_d).round(4)
  end



  private

  def update_calculated_fields
    self.cost_per_piece = calculate_cost_per_piece
    self.subtotal = calculate_subtotal
    self.quantity_sale_units = quantity_sale_units_calc
  end
end








# Calcula quantity_sale_units antes de validar
# before_validation :set_quantity_sale_units

# private

# def set_quantity_sale_units
# self.quantity_sale_units = (quantity || 0) * (conversion_factor || 0)
# end
