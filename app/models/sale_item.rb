class SaleItem < ApplicationRecord
  belongs_to :sale
  belongs_to :product
  
  # Validaciones
  validates :quantity, 
    presence: true, 
    numericality: { 
      greater_than: 0,
      message: "debe ser mayor a 0"
    }
  
  validates :unit_price, 
    presence: true, 
    numericality: { 
      greater_than: 0,
      message: "debe ser mayor a $0"
    }
  
  validates :discount, 
    numericality: { 
      greater_than_or_equal_to: 0,
      message: "no puede ser negativo"
    }, 
    allow_nil: true
  
  validates :subtotal, 
    presence: true, 
    numericality: { 
      greater_than_or_equal_to: 0,
      message: "no puede ser negativo"
    }
  
  # 🔥 NUEVA VALIDACIÓN: Descuento no puede exceder subtotal
  validate :discount_cannot_exceed_subtotal
  
  # Métodos de cálculo
  def calculate_subtotal
    (quantity * unit_price) - (discount || 0)
  end
  
  private
  
  # 🔥 NUEVA VALIDACIÓN PERSONALIZADA
  def discount_cannot_exceed_subtotal
    return if discount.nil? || discount.zero?
    return if quantity.nil? || unit_price.nil?
    
    potential_subtotal = (unit_price * quantity).round(2)
    
    if discount > potential_subtotal
      errors.add(:discount, 
        "de $#{discount.round(2)} excede el subtotal de $#{potential_subtotal}. " \
        "El descuento máximo permitido es $#{potential_subtotal}."
      )
    end
  end
end