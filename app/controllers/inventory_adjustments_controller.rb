class InventoryAdjustmentsController < ApplicationController
  include InventoriesHelper
  def index
    @adjustments = inventory.inventory_adjustments
  end

  def show
    @adjustment = inventory.inventory_adjustments.find(params[:id])
  end

  def new
    @adjustment = inventory.inventory_adjustments.new
  end

  def create
    @adjustment = InventoryAdjuster.apply!(
      inventory: inventory,
      quantity: adjustment_params[:quantity],
      adjustment_type: adjustment_params[:adjustment_type],
      reason: adjustment_params[:reason],
      performed_by: adjustment_params[:performed_by],
      note: adjustment_params[:note]
    )
    redirect_to inventory_inventory_adjustments_path(inventory), notice: "Ajuste aplicado correctamente."
  rescue => e
    flash.now[:alert] = "Error al aplicar ajuste: #{e.message}"
    @adjustment = inventory.inventory_adjustments.new(adjustment_params)
    render :new, status: :unprocessable_content
  end

  private
  def adjustment_params
    params.require(:inventory_adjustment).permit(:quantity, :adjustment_type, :reason, :performed_by, :note)
  end

end
