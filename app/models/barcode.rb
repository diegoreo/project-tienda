class Barcode < ApplicationRecord
  belongs_to :product
  #code sea opcional (puede estar vacío o nulo), pero si existe debe ser único
  validates :code, uniqueness: true, allow_blank: true
end
