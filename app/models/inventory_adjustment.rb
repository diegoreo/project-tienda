class InventoryAdjustment < ApplicationRecord
  belongs_to :inventory
  belongs_to :performed_by, class_name: "User" # ← NUEVA LÍNEA

  # Enum para tipo de ajuste: increase (0) o decrease (1)
  enum :adjustment_type, { increase: 0, decrease: 1 }

  # Validaciones ACTUALIZADAS
  validates :performed_by, presence: true # ← Ya no valida string, valida relación
  validates :quantity, numericality: { greater_than: 0 }
  validates :reason, presence: true
end