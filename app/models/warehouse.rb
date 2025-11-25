class Warehouse < ApplicationRecord
  has_many :registers, dependent: :restrict_with_error
  has_many :register_sessions, through: :registers
  has_many :purchases, dependent: :restrict_with_exception
  has_many :inventories, dependent: :restrict_with_exception
  has_many :inventory_movements, through: :inventories

  validates :name, presence: true, uniqueness: true
  validates :location, presence: true
  # Validación de longitud mínima
  validates :name, length: { minimum: 3, message: "debe tener al menos 3 caracteres" }
  validates :location, length: { minimum: 4, message: "debe tener al menos 4 caracteres" }

  # Validación de unicidad
  validates :name, uniqueness: { case_sensitive: false, message: "ya existe otro almacén con este nombre" }
end
