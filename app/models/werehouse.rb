class Warehouse < ApplicationRecord
  has_many :purchases, dependent: :restrict_with_exception
  has_many :inventories, dependent: :restrict_with_exception
  has_many :inventory_movements, through: :inventories

  validates :name, presence: true, uniqueness: true
  validates :location, presence: true
end