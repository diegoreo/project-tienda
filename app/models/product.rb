class Product < ApplicationRecord
  belongs_to :category
  has_many :barcodes, dependent: :destroy
  # Validaciones de presencia (obligatorios)
  validates :name, :price, :stock_quantity, :purchase_unit, :sale_unit, :unit_conversion, presence: true
  # Validación de unicidad del nombre
  validates :name, uniqueness: true
  # price y unit_conversion deben ser mayores o iguales a 0.
  # stock_quantity solo debe ser un número válido, pero puede ser positivo o negativo.
  validates :price, :unit_conversion, numericality: { greater_than_or_equal_to: 0 }
  validates :stock_quantity, numericality: true
  # Validación para evitar valores de conversión en cero
  validates :unit_conversion, numericality: { greater_than: 0 }
  # Opcional: longitud mínima de nombre
  validates :name, length: { minimum: 2 }
 
 
 
  # Método útil: stock en unidades de venta
  def stock_for_sale
    (stock_quantity || 0) * (unit_conversion || 1)
  end
end
