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

  # GET /purchases/:id/edit - FALTABA ESTA ACCIÓN
  def edit
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
    if @purchase.update(purchase_params)
      # Recalcular TODOS los campos calculados de cada item
      @purchase.purchase_items.each do |item|
        next if item.marked_for_destruction?
        
        item.quantity_sale_units = item.quantity_sale_units_calc
        item.subtotal = item.calculate_subtotal
        item.cost_per_piece = item.calculate_cost_per_piece
        item.save!
      end
      
      # Recalcular y actualizar el total de la compra
      total = @purchase.purchase_items.reject(&:marked_for_destruction?).sum(&:subtotal)
      @purchase.update_column(:total, total)
      
      redirect_to @purchase, notice: "Compra actualizada correctamente."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  # DELETE /purchases/:id
  def destroy
    @purchase.destroy
    redirect_to purchases_path, notice: "Compra eliminada correctamente"
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
end





#camb
=begin
def create
  @purchase = Purchase.new(purchase_params)

  if @purchase.save
    # Procesar inventarios y movimientos explícitamente
    @purchase.process_inventory!

    redirect_to purchases_path, notice: "Compra registrada correctamente"
  else
    render :new, status: :unprocessable_content
  end
end
=end
