class Product < ApplicationRecord
  has_paper_trail
  include PgSearch::Model
  pg_search_scope :search_by_name_description_and_barcode,
    against: [ :name, :description ],
    associated_against: {
      barcodes: :code
    },
    using: {
      tsearch: { prefix: true, dictionary: "spanish" },  # "coc" -> "coca cola"
      trigram: {
        threshold: 0.1           # más flexible para errores tipográficos
      }
    }

  belongs_to :category
  belongs_to :purchase_unit, class_name: "Unit"
  belongs_to :sale_unit, class_name: "Unit"
  has_many :barcodes, dependent: :destroy
  has_many :purchase_items, dependent: :restrict_with_exception
  has_many :inventories, dependent: :restrict_with_exception

  # Esto permite que el formulario de Product acepte datos para barcodes
  accepts_nested_attributes_for :barcodes, allow_destroy: true, reject_if: :all_blank

  # Validaciones de presencia (obligatorios)
  validates :name, :price, :purchase_unit, :sale_unit, :unit_conversion, presence: true
  # Validación de unicidad del nombre
  validates :name, uniqueness: {
    case_sensitive: false,
    message: "ya existe otro producto con este nombre"
  }
  # price debe ser mayor a 0
  validates :price, numericality: {
    greater_than: 0,
    message: "debe ser mayor a $0"
  }

  # stock_quantity solo debe ser un número válido, pero puede ser positivo o negativo.
  validates :price, :unit_conversion, numericality: { greater_than_or_equal_to: 0 }
  validates :stock_quantity, numericality: true, allow_nil: true 
  # Validación para evitar valores de conversión en cero
  validates :unit_conversion, numericality: { greater_than: 0 }
  # Opcional: longitud mínima de nombre
  validates :name, length: { minimum: 2 }

  # ========== SCOPES PARA PRODUCTOS ACTIVOS/INACTIVOS ==========
  scope :active, -> { where(active: true) }
  scope :inactive, -> { where(active: false) }

  # ========== MÉTODOS PARA ACTIVAR/DESACTIVAR ==========
  def deactivate!
    update(active: false)
  end

  def activate!
    update(active: true)
  end

  def can_be_deleted?
    !inventories.exists? && !purchase_items.exists?
  end

  # ========== MÉTODOS EXISTENTES ==========
  # Método útil: stock en unidades de venta
  def stock_for_sale
    (stock_quantity || 0) * (unit_conversion || 1)
  end
end
