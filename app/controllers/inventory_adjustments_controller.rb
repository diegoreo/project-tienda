class InventoryAdjustmentsController < ApplicationController
  before_action :set_inventory
  
  def index
    authorize InventoryAdjustment
    @adjustments = @inventory.inventory_adjustments.includes(:performed_by)

    # Variable para controlar visualización de costos
    @show_costs = policy(InventoryAdjustment).view_costs?
  end

  def show
    @adjustment = @inventory.inventory_adjustments.includes(:performed_by).find(params[:id])
    authorize @adjustment

    # Variable para controlar visualización de costos
    @show_costs = policy(@adjustment).view_costs?
  end

  def new
    @adjustment = @inventory.inventory_adjustments.new
    authorize @adjustment
  end

  def create
    # Crear instancia temporal para autorización
    @adjustment = @inventory.inventory_adjustments.new
    authorize @adjustment

    @adjustment = InventoryAdjuster.apply!(
      inventory: @inventory,
      quantity: adjustment_params[:quantity],
      adjustment_type: adjustment_params[:adjustment_type],
      reason: adjustment_params[:reason],
      performed_by: current_user,
      note: adjustment_params[:note]
    )
    redirect_to inventory_inventory_adjustments_path(@inventory), notice: "Ajuste aplicado correctamente."
  rescue => e
    flash.now[:alert] = "Error al aplicar ajuste: #{e.message}"
    @adjustment = @inventory.inventory_adjustments.new(adjustment_params)
    render :new, status: :unprocessable_content
  end

  private

  def set_inventory
    @inventory = Inventory.find(params[:inventory_id])
  end

  def adjustment_params
    params.require(:inventory_adjustment).permit(:quantity, :adjustment_type, :reason, :note)
  end
end