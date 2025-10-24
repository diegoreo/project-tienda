class WarehousesController < ApplicationController
  def index
    # Autorizar el acceso al índice de almacenes
    authorize Warehouse
    
    @warehouses = Warehouse.all
  end

  def new
    @warehouse = Warehouse.new
    authorize @warehouse
  end

  def create
    @warehouse = Warehouse.new(warehouse_params)
    authorize @warehouse
    
    if @warehouse.save
      redirect_to warehouses_url, notice: "Tu almacén se creó correctamente!"
    else
      render :new, status: :unprocessable_content
    end
  end

  def edit
    @warehouse = Warehouse.find(params[:id])
    authorize @warehouse
  end

  def update
    @warehouse = Warehouse.find(params[:id])
    authorize @warehouse
    
    if @warehouse.update(warehouse_params)
      redirect_to warehouses_url, notice: "Tu almacén se actualizó correctamente"
    else
      render :edit, status: :unprocessable_content
    end
  end

  def destroy
    @warehouse = Warehouse.find(params[:id])
    authorize @warehouse
    
    @warehouse.destroy
    redirect_to warehouses_url, notice: "Tu almacén se eliminó correctamente", status: :see_other
  end

  private

  def warehouse_params
    params.require(:warehouse).permit(:name, :location)
  end
end