class Purchase < ApplicationRecord
  belongs_to :supplier
  belongs_to :warehouse

  has_many :purchase_items, dependent: :destroy

  accepts_nested_attributes_for :purchase_items, allow_destroy: true

  validates :purchase_date, presence: true
  validates :total, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
end