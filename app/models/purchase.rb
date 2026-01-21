class Purchase < ApplicationRecord
  has_paper_trail
  belongs_to :supplier
  belongs_to :warehouse
  has_many :purchase_items, dependent: :destroy

  accepts_nested_attributes_for :purchase_items, allow_destroy: true, reject_if: :all_blank

  validates :supplier, :warehouse, :purchase_date, presence: true
  validates :total, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
  validate :purchase_date_cannot_be_future

  # Constante para definir días editables
  EDITABLE_DAYS = 15

  # Verifica si la compra puede editarse
  def editable?
    return true if processed_at.nil? # No procesada aún

    # Procesada hace menos de EDITABLE_DAYS
    processed_at > EDITABLE_DAYS.days.ago
  end

  # Calcula días desde que fue procesada
  def days_since_processed
    return nil if processed_at.nil?
    ((Time.current - processed_at) / 1.day).to_i
  end

  # Calcula el total sumando subtotales de items
  def calculate_total
    purchase_items.reject(&:marked_for_destruction?).sum(&:subtotal)
  end

  # ========================================
  # Procesar compra con soporte para productos vinculados
  # ========================================
  def process_inventory!
    return if processed_at.present? # Ya fue procesada

    transaction do
      purchase_items.each do |item|
        # Obtener el producto que maneja el inventario real
        # - Si es base o master: retorna el mismo producto
        # - Si es presentation: retorna el producto maestro
        inventory_product = item.product.inventory_product
        
        # Calcular unidades base a agregar
        # - Productos base/master: quantity_sale_units directo
        # - Productos presentation: quantity_sale_units ya incluye la conversión
        # Nota: quantity_sale_units = quantity × conversion_factor del producto
        # Si compramos 10 paquetes (conversion_factor: 4), quantity_sale_units = 40 rollos
        base_units = if item.product.presentation?
          # Para presentaciones, quantity_sale_units ya tiene la conversión correcta
          item.product.calculate_base_units(item.quantity_sale_units / item.product.conversion_factor)
        else
          # Para base/master, usar quantity_sale_units directo
          item.quantity_sale_units
        end

        # Buscar o crear inventario del producto correcto (maestro si es presentación)
        inventory = Inventory.find_or_create_by!(
          product: inventory_product,
          warehouse: warehouse
        )

        # Aumentar el stock con unidades base
        inventory.quantity += base_units
        inventory.save!

        # Registrar movimiento con nota descriptiva
        InventoryMovement.create!(
          inventory: inventory,
          movement_type: :incoming,
          reason: :purchase,
          quantity: base_units,
          source: self,
          note: "Compra ##{id} - #{item.quantity} × #{item.product.name}" +
                (item.product.presentation? ? " (#{base_units} unidades base)" : "")
        )
      end

      # Actualizar total y marcar como procesada
      update_columns(
        total: calculate_total,
        processed_at: Time.current
      )
    end
  end

  def purchase_date_cannot_be_future
    return unless purchase_date.present?
    
    if purchase_date > Date.current
      errors.add(:purchase_date, 
        "no puede ser una fecha futura. " \
        "Fecha actual: #{Date.current.strftime('%d/%m/%Y')}"
      )
    end
  end

  # Revertir inventario al eliminar compra
  # ========================================
  def revert_inventory!
    return unless processed_at.present? # Solo revertir si fue procesada

    transaction do
      purchase_items.each do |item|
        # Obtener el producto que maneja el inventario real
        inventory_product = item.product.inventory_product
        
        # Calcular unidades base a revertir
        base_units = if item.product.presentation?
          item.product.calculate_base_units(item.quantity_sale_units / item.product.conversion_factor)
        else
          item.quantity_sale_units
        end

        inventory = Inventory.find_by(
          product: inventory_product,
          warehouse: warehouse
        )

        next unless inventory

        # Calcular nueva cantidad
        new_quantity = inventory.quantity - base_units

        # Advertir si queda negativo (pero permitir)
        if new_quantity < 0
          Rails.logger.warn "Inventario quedará negativo: #{inventory_product.name} = #{new_quantity}"
        end

        # Actualizar inventario
        inventory.quantity = new_quantity
        inventory.save!

        # Registrar movimiento
        InventoryMovement.create!(
          inventory: inventory,
          movement_type: :outgoing,
          reason: :purchase_cancellation,
          quantity: base_units,
          source: self,
          note: "Eliminación de compra ##{id} - #{item.product.name}" +
                (item.product.presentation? ? " (#{base_units} unidades base)" : "")
        )
      end
    end
  end
end