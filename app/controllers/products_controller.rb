class ProductsController < ApplicationController
  def index
    @products = Product.all
  end

  def show
    @product = Product.find(params[:id])
  end

  def new
    @product = Product.new
    @product.barcodes.build # para que aparezca un campo vacío de código de barras en el formulario
 
  end

  def create
    @product = Product.new(product_params)
    if @product.save
      redirect_to products_path, notice: "Producto creado con exito."
    else
      render :new, status: :unprocessable_entity
    end
  end

  private
  def product_params
    params.require(:product).permit(
      :name, :description, :price, :stock_quantity,
      :purchase_unit_id, :sale_unit_id, :unit_conversion, :category_id,
      barcodes_attributes: [:code]
    )
  end
  
end