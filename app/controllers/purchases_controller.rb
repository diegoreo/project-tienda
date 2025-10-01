class PurchasesController < ApplicationController
  before_action :set_purchase, only: %i[show edit update destroy]

  # GET /purchases
  def index
    @purchases = Purchase.includes(:supplier, :warehouse, :purchase_items).all
  end

  # GET /purchases/:id
  def show
  end

  # GET /purchases/new
  def new
    @purchase = Purchase.new
    @purchase.purchase_items.build
  end

  # GET /purchases/:id/edit
  def edit
    unless @purchase.editable?
      days = @purchase.days_since_processed
      redirect_to @purchase, 
        alert: "No se puede editar. Esta compra fue procesada hace #{days} días (límite: #{Purchase::EDITABLE_DAYS} días)."
      return
    end
    
    @purchase.purchase_items.build if @purchase.purchase_items.empty?
  end

  # POST /purchases
  def create
    @purchase = Purchase.new(purchase_params)
    
    # Calcular quantity_sale_units antes de guardar
    @purchase.purchase_items.each do |item|
      item.quantity_sale_units = item.quantity_sale_units_calc
    end
    
    if @purchase.save
      # Procesar inventario
      @purchase.process_inventory!
      redirect_to @purchase, notice: "Compra registrada correctamente."
    else
      render :new, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /purchases/:id
  def update
    unless @purchase.editable?
      redirect_to @purchase, alert: "Compra no editable."
      return
    end
    
    # Guardar valores anteriores ANTES de actualizar (desde la BD)
    old_items_data = @purchase.purchase_items.reload.map do |item|
      {
        id: item.id,
        product_id: item.product_id,
        old_quantity_sale_units: item.quantity_sale_units || 0,
        old_quantity: item.quantity,
        old_conversion: item.conversion_factor
      }
    end
    
    if @purchase.update(purchase_params)
      # Recalcular campos NUEVOS
      @purchase.purchase_items.each do |item|
        next if item.marked_for_destruction?
        
        item.quantity_sale_units = item.quantity_sale_units_calc
        item.subtotal = item.calculate_subtotal
        item.cost_per_piece = item.calculate_cost_per_piece
        item.save!
      end
      
      # Ajustar inventario si ya estaba procesada
      if @purchase.processed_at.present?
        adjust_inventory(old_items_data)
      end
      
      # Actualizar total
      total = @purchase.purchase_items.reject(&:marked_for_destruction?).sum(&:subtotal)
      @purchase.update_column(:total, total)
      
      redirect_to @purchase, notice: "Compra actualizada correctamente."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  # DELETE /purchases/:id
  def destroy
    # Revertir inventario si la compra fue procesada
    if @purchase.processed_at.present?
      revert_purchase_inventory
    end
    
    @purchase.destroy
    redirect_to purchases_path, notice: "Compra eliminada correctamente y el inventario fue ajustado."
  rescue StandardError => e
    redirect_to @purchase, alert: "Error al eliminar la compra: #{e.message}"
  end

  private

  def set_purchase
    @purchase = Purchase.find(params[:id])
  end

  def purchase_params
    params.require(:purchase).permit(
      :supplier_id, :warehouse_id, :purchase_date,
      purchase_items_attributes: [
        :id, :product_id, :quantity, :purchase_price,
        :conversion_factor, :subtotal, :cost_per_piece,
        :_destroy
      ]
    )
  end

  def adjust_inventory(old_items_data)
    @purchase.purchase_items.each do |item|
      next if item.marked_for_destruction?
      
      # Buscar dato anterior
      old_data = old_items_data.find { |d| d[:id] == item.id }
      
      if old_data
        # Item existente - calcular diferencia
        old_qty = old_data[:old_quantity_sale_units].to_f
        new_qty = item.quantity_sale_units.to_f
        difference = new_qty - old_qty
        
        next if difference.zero?
        
        adjust_inventory_for_item(item, difference)
      else
        # Item nuevo agregado en la edición
        adjust_inventory_for_item(item, item.quantity_sale_units.to_f)
      end
    end
    
    # Manejar items eliminados
    old_items_data.each do |old_data|
      item = @purchase.purchase_items.find { |i| i.id == old_data[:id] }
      if item.nil? || item.marked_for_destruction?
        # Item fue eliminado - restar del inventario
        product = Product.find(old_data[:product_id])
        adjust_inventory_for_item_removal(product, old_data[:old_quantity_sale_units].to_f)
      end
    end
  end
  
  def adjust_inventory_for_item(item, difference)
    inventory = Inventory.find_or_create_by!(
      product: item.product,
      warehouse: @purchase.warehouse
    )
    
    inventory.quantity += difference
    inventory.save!
    
    # Registrar movimiento de ajuste
    InventoryMovement.create!(
      inventory: inventory,
      movement_type: difference > 0 ? :incoming : :outgoing,
      reason: :adjustment,
      quantity: difference.abs,
      source: @purchase,
      note: "Ajuste por edición compra ##{@purchase.id} - #{item.product.name}"
    )
  end
  
  def adjust_inventory_for_item_removal(product, quantity)
    inventory = Inventory.find_by(
      product: product,
      warehouse: @purchase.warehouse
    )
    
    return unless inventory
    
    inventory.quantity -= quantity
    inventory.save!
    
    InventoryMovement.create!(
      inventory: inventory,
      movement_type: :outgoing,
      reason: :adjustment,
      quantity: quantity,
      source: @purchase,
      note: "Item eliminado de compra ##{@purchase.id} - #{product.name}"
    )
  end
  
  def revert_purchase_inventory
    ActiveRecord::Base.transaction do
      @purchase.purchase_items.each do |item|
        inventory = Inventory.find_by(
          product: item.product,
          warehouse: @purchase.warehouse
        )
        
        next unless inventory
        
        # Calcular nueva cantidad
        new_quantity = inventory.quantity - item.quantity_sale_units
        
        # Advertir si queda negativo (pero permitir)
        if new_quantity < 0
          Rails.logger.warn "Inventario quedará negativo: #{item.product.name} = #{new_quantity}"
        end
        
        # Actualizar inventario
        inventory.quantity = new_quantity
        inventory.save!
        
        # Registrar movimiento
        InventoryMovement.create!(
          inventory: inventory,
          movement_type: :outgoing,
          reason: :purchase_cancellation,
          quantity: item.quantity_sale_units,
          source: @purchase,
          note: "Eliminación de compra ##{@purchase.id} - #{item.product.name}"
        )
      end
    end
  end
end