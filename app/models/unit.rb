class Unit < ApplicationRecord
  has_many :products_as_purchase, class_name: "Product", foreign_key: "purchase_unit_id"
  has_many :products_as_sale, class_name: "Product", foreign_key: "sale_unit_id"

  # Validaciones
  validates :name, presence: { message: "no puede estar en blanco" }
  validates :name, uniqueness: { case_sensitive: false, message: "ya está registrada" }
  validates :name, length: { maximum: 50, message: "es demasiado largo (máximo 50 caracteres)" }
end