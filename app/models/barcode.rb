class Barcode < ApplicationRecord
  has_paper_trail
  belongs_to :product
  # code sea opcional (puede estar vacío o nulo), pero si existe debe ser único
  validates :code, uniqueness: { case_sensitive: false, message: "ya existe en otro producto" }, allow_blank: true

  validate :unique_code_for_update

private

def unique_code_for_update
  return if code.blank?

  existing = Barcode.where("LOWER(code) = ?", code.downcase).where.not(id: id).first
  if existing
    errors.add(:code, "ya existe en otro producto")
  end
end
end
