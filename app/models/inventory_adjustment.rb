class InventoryAdjustment < ApplicationRecord
  belongs_to :inventory

  # Enum para tipo de ajuste: increase (0) o decrease (1)
  enum :adjustment_type, { increase: 0, decrease: 1 }


  # Temporal: en lugar de user, guardamos un string
  validates :performed_by, presence: true
  validates :quantity, numericality: { greater_than: 0 }
  validates :reason, presence: true


end
