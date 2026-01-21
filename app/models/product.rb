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

  # Relaciones para sistema master/presentation
  belongs_to :master_product, 
             class_name: "Product", 
             optional: true
  
  has_many :presentations, 
           class_name: "Product",
           foreign_key: "master_product_id",
           dependent: :restrict_with_error

  # Esto permite que el formulario de Product acepte datos para barcodes
  accepts_nested_attributes_for :barcodes, allow_destroy: true, reject_if: :all_blank

  # Enum para tipo de producto
  enum :product_type, {
    base: 0,         # Producto normal (sin relación)
    master: 1,       # Unidad base (rollo, pieza, litro)
    presentation: 2  # Presentación (paquete, caja, six-pack)
  }

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

  # Validaciones para productos vinculados
  validates :conversion_factor, numericality: { greater_than: 0 }
  
  validate :presentation_must_have_master
  validate :master_cannot_have_master
  validate :cannot_be_own_master
  validate :conversion_factor_for_presentation

  # Validaciones para productos vinculados
  validates :conversion_factor, numericality: { greater_than: 0 }
  
  validate :presentation_must_have_master
  validate :master_cannot_have_master
  validate :cannot_be_own_master
  validate :conversion_factor_for_presentation



  # ========== SCOPES PARA PRODUCTOS ACTIVOS/INACTIVOS ==========
  scope :active, -> { where(active: true) }
  scope :inactive, -> { where(active: false) }
  scope :base_products, -> { where(product_type: :base) }
  scope :master_products, -> { where(product_type: :master) }
  scope :presentation_products, -> { where(product_type: :presentation) }

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

  def can_be_deleted_safely?
    # No puede eliminar si tiene presentaciones vinculadas
    return false if master? && presentations.any?
    
    # Regla existente
    can_be_deleted?
  end

 # ========================================
  # MÉTODOS PÚBLICOS - PRODUCTOS VINCULADOS
  # ========================================
  
  # Obtener el producto que maneja el inventario real
  # - Si es base o master: retorna self
  # - Si es presentation: retorna el master
  def inventory_product
    presentation? ? master_product : self
  end
  
  # Calcular stock disponible en un almacén
  def available_stock(warehouse)
    if base? || master?
      # Stock directo del inventario
      inventory = inventories.find_by(warehouse: warehouse)
      inventory&.quantity || 0
    elsif presentation?
      # Stock calculado desde el maestro
      return 0 unless master_product
      
      master_inventory = master_product.inventories.find_by(warehouse: warehouse)
      return 0 unless master_inventory
      
      # Cuántas presentaciones completas caben
      (master_inventory.quantity / conversion_factor).floor
    end
  end
  
  # Calcular cuántas unidades base se necesitan para esta cantidad
  # Ej: 10 paquetes × 4 rollos/paquete = 40 rollos
  def calculate_base_units(quantity)
    if base? || master?
      quantity
    elsif presentation?
      quantity * conversion_factor
    else
      quantity
    end
  end
  
  # Verificar si se puede vender esta cantidad
  def can_sell?(quantity, warehouse)
    available = available_stock(warehouse)
    quantity <= available
  end
  
  # Detalle de stock para productos master (útil para reportes)
  def stock_breakdown(warehouse)
    return nil unless master?
    
    inventory = inventories.find_by(warehouse: warehouse)
    total_units = inventory&.quantity || 0
    
    breakdown = {
      total_base_units: total_units,
      presentations: []
    }
    
    # Calcular cuántas de cada presentación caben
    presentations.each do |pres|
      full_packs = (total_units / pres.conversion_factor).floor
      breakdown[:presentations] << {
        name: pres.name,
        conversion_factor: pres.conversion_factor,
        available_packs: full_packs
      }
    end
    
    breakdown
  end

  # ========================================
  # MÉTODOS EXISTENTES
  # ========================================
  # Método útil: stock en unidades de venta
  def stock_for_sale
    (stock_quantity || 0) * (unit_conversion || 1)
  end

  private

  # ========================================
  # VALIDACIONES PERSONALIZADAS
  # ========================================
  
  def presentation_must_have_master
    if presentation? && master_product_id.blank?
      errors.add(:master_product_id, 
        "es obligatorio para productos tipo 'Presentación'")
    end
  end
  
  def master_cannot_have_master
    if master? && master_product_id.present?
      errors.add(:master_product_id, 
        "un producto maestro no puede tener otro maestro")
    end
  end
  
  def cannot_be_own_master
    if persisted? && master_product_id == id
      errors.add(:master_product_id, 
        "un producto no puede ser su propio maestro")
    end
  end
  
  def conversion_factor_for_presentation
    if presentation? && conversion_factor <= 1.0
      errors.add(:conversion_factor, 
        "debe ser mayor a 1.0 para presentaciones (ej: 1 paquete = 4 unidades)")
    end
  end
end
