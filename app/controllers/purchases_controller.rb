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
    # Inicializa al menos un item para el formulario
    @purchase.purchase_items.build
  end

  # POST /purchases
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

  # GET /purchases/:id/edit
  def edit
    # Permitir agregar items vacíos en el formulario
    @purchase.purchase_items.build if @purchase.purchase_items.empty?
  end

  # PATCH/PUT /purchases/:id
  def update
    if @purchase.update(purchase_params)
      # Reprocesar inventarios: 
      # Ojo, aquí dependerá de si quieres restar el stock antiguo y sumar el nuevo
      # Para simplicidad, podrías dejar que solo cree nuevos movimientos por items añadidos
      redirect_to purchase_path(@purchase), notice: "Compra actualizada correctamente"
    else
      render :edit, status: :unprocessable_content
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
      :supplier_id,
      :warehouse_id,
      :purchase_date,
      purchase_items_attributes: [
        :id, 
        :product_id, 
        :quantity, 
        :unit_cost, 
        :conversion_factor, 
        :quantity_sale_units, 
        :_destroy
      ]
    )
  end
end
