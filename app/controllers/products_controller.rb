class ProductsController < ApplicationController
  def index
    @categories = Category.order(:name)
  
    # Base query
    @products = Product.all
  
    # Búsqueda con pg_search
    if params[:query].present?
      @products = @products.search_by_name_description_and_barcode(params[:query])
    end
  
    # Filtrado por categoría
    if params[:category_id].present?
      @products = @products.where(category_id: params[:category_id])
    end
  
    # Orden y preload de asociaciones
    @products = @products.includes(:purchase_unit, :sale_unit, :category)
      .order(created_at: :desc)
  end
  
  

  def show
    product
    respond_to do |format|
      format.html # busca la vista show.html.erb por defecto
      format.json { render json: @product.as_json(only: [:id, :name, :price]) }
    end
  end

  def new
    @product = Product.new
    @product.barcodes.build # para que aparezca un campo vacío de código de barras en el formulario
 
  end

  def create
    @product = Product.new(product_params)
    if @product.save
      # Elegir almacén: el seleccionado en el form (top-level) o el primero
      warehouse = params[:initial_warehouse_id].present? ? Warehouse.find_by(id: params[:initial_warehouse_id]) : Warehouse.first
      InventoryBootstrapper.call(product: @product, warehouse: warehouse)
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

  def search
    query = params[:q]
    warehouse_id = params[:warehouse_id]
    
    if query.blank?
      render json: []
      return
    end
    
    # 1. Primero buscar coincidencia exacta por código de barras
    barcode = Barcode.includes(product: [:inventories, :barcodes])
                     .find_by("LOWER(code) = ?", query.downcase)
    
    if barcode && barcode.product
      # Encontró por código de barras - devolver solo este producto
      render json: [format_product_for_pos(barcode.product, warehouse_id)]
      return
    end
    
    # 2. Si no encontró por código, buscar por nombre con pg_search
    products = Product.search_by_name_description_and_barcode(query)
                      .includes(:inventories, :barcodes)
                      .limit(10)
    
    render json: products.map { |p| format_product_for_pos(p, warehouse_id) }
  end

  private
  def product_params
    base_params = [
      :name,
      :description,
      :price,
      :purchase_unit_id,
      :sale_unit_id,
      :unit_conversion,
      :category_id,
      { barcodes_attributes: [:id, :code, :_destroy] }
    ]
  
    # Solo permitir stock_quantity al crear
    base_params << :stock_quantity if action_name == "create"
  
    params.require(:product).permit(base_params)
  end

  def product
    @product = Product.find(params[:id])
  end

  def format_product_for_pos(product, warehouse_id)
    inventory = product.inventories.find_by(warehouse_id: warehouse_id)
    stock = inventory&.quantity || 0
    
    {
      id: product.id,
      name: product.name,
      price: product.price.to_f,
      stock: stock.to_f,
      has_stock: stock > 0,
      barcodes: product.barcodes.pluck(:code),
      unit: product.sale_unit.abbreviation
    }
  end
  
end