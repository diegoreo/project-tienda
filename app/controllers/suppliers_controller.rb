class SuppliersController < ApplicationController
  def index
    @suppliers = Supplier.all
  end

  def new
    @supplier = Supplier.new
  end

  def create
    @supplier = Supplier.new(supplier_params)
    if @supplier.save
      redirect_to suppliers_url, notice: "Tu Proveedor se creo correctamente!"
    else
      render :new, status: :unprocessable_content
    end
  end

  def edit
    supplier
  end

  def update
    if supplier.update(supplier_params)
      redirect_to suppliers_url, notice: "Tu proveedor se actualizo correctamente"
    else
      render :edit, status: :unprocessable_content
    end
  end

  def destroy
    supplier.destroy
    redirect_to suppliers_url, notice: "Tu proveedor se elimino correctamente"
  end

  private

  def supplier_params
    params.require(:supplier).permit(
      :name, :contact_info
    )
  end

  def supplier
    @supplier = Supplier.find(params[:id])
  end

end