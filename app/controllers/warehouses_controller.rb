class WarehousesController < ApplicationController
  def index
    @warehouses = Warehouse.all
  end

  def new
    @warehouse = Warehouse.new
  end

  def create
    @warehouse = Warehouse.new(warehouse_params)
    if @warehouse.save
      redirect_to warehouses_url, notice: "Tu Almacen se creo correctamente!"
    else
      render :new, status: :unprocessable_content
    end
  end

  def edit
    warehouse
  end

  def update
    if warehouse.update(warehouse_params)
      redirect_to warehouses_url, notice: "tu almacen se actualizo correctamente"
    else
      render :edit, status: :unprocessable_content
    end
  end

  def destroy
    warehouse.destroy
    redirect_to warehouses_url, notice: "Tu almacen se elimino correctamente"
  end

  private

  def warehouse_params
    params.require(:warehouse).permit(
      :name, :location
    )
  end


  def warehouse
    @warehouse = Warehouse.find(params[:id])
  end


end