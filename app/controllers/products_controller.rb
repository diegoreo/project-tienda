class ProductsController < ApplicationController
  def index
    @products = Product.all
  end

  def show
    product
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
      render :new, status: :unprocessable_content
    end
  end

  def edit
    product.barcodes.build
  end

  def update
    if product.update(product_params)
      redirect_to products_path, notice: "Tu producto se ha actualizado correctamnete"
    else
      render :edit, status: :unprocessable_content
    end
  end

  def destroy
    product.destroy
    redirect_to products_path, notice: "El producto se elimino correctamente", status: :see_other
  end

  private
  def product_params
    params.require(:product).permit(
      :name, :description, :price, :stock_quantity,
      :purchase_unit_id, :sale_unit_id, :unit_conversion, :category_id,
      barcodes_attributes: [:id, :code, :_destroy]
    )
  end

  def product
    @product = Product.find(params[:id])
  end
  
end