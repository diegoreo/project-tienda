class InventoryMovement < ApplicationRecord
  belongs_to :inventory
  belongs_to :source, polymorphic: true, optional: true

  enum movement_type: { in: "in", out: "out" }

  validates :movement_type, presence: true, inclusion: { in: %w[in out] }
  validates :quantity, numericality: { greater_than: 0 }
  validates :reason, presence: true
end