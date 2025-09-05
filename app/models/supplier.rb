class Supplier < ApplicationRecord
  has_many :purchases, dependent: :restrict_with_exception

  validates :name, presence: true, uniqueness: true
  validates :contact_info, presence: true

  # Validación de longitud mínima
  validates :name, length: { minimum: 4, message: "debe tener al menos 4 caracteres" }
end