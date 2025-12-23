class ProductsController < ApplicationController
  def index
    # Autorizar el acceso al índice de productos
    authorize Product

    @categories = Category.order(:name)

    # Usar policy_scope para obtener los productos según el rol
    products = policy_scope(Product)
    Rails.logger.debug "🔵 Paso 1 - Total productos: #{products.count}"

    # Búsqueda con pg_search
    if params[:query].present?
      products = products.search_by_name_description_and_barcode(params[:query])
      Rails.logger.debug "🔵 Paso 2 - Después de buscar '#{params[:query]}': #{products.count}"
    end

    # Filtrado por categoría
    if params[:category_id].present?
      products = products.where(category_id: params[:category_id])
      Rails.logger.debug "🔵 Paso 3 - Después de filtrar categoría: #{products.count}"
    end

    # CALCULAR CONTADORES (después de búsqueda/categoría, antes de estado)
    @active_count = products.active.count
    @inactive_count = products.inactive.count
    Rails.logger.debug "🔵 Paso 4 - Activos: #{@active_count}, Inactivos: #{@inactive_count}"


    # Filtrar por estado: activos (default), inactivos, o todos
    case params[:status]
    when "inactive"
      products = products.inactive
    when "all"
      products = products.all
    else
      products = products.active  # Por defecto mostrar solo activos
    end

    # Orden y preload de asociaciones (agregado :inventories, :barcodes)
    products = products.includes(:purchase_unit, :sale_unit, :category, :inventories, :barcodes)
    .order(created_at: :desc)

    # PAGINACIÓN (20 productos por página)
    @pagy, @products = pagy(products, items: 20)
    Rails.logger.debug "🔵 Paso 7 - Productos en página: #{@products.count}"
  end

  def show
    @product = Product.includes(inventories: :warehouse).find(params[:id])
    authorize @product
  
    respond_to do |format|
      format.html # busca la vista show.html.erb por defecto
      format.json { render json: @product.as_json(only: [ :id, :name, :price ]) }
    end
  end

  def new
    @product = Product.new
    authorize @product

    @product.barcodes.build # para que aparezca un campo vacío de código de barras en el formulario
  end

  def create
    @product = Product.new(product_params)
    authorize @product

    if @product.save
      # Elegir almacén: el seleccionado en el form (top-level) o el primero
      warehouse = params[:initial_warehouse_id].present? ? Warehouse.find_by(id: params[:initial_warehouse_id]) : Warehouse.first
      InventoryBootstrapper.call(product: @product, warehouse: warehouse)
      redirect_to products_path, notice: "Producto creado con éxito."
    else
      render :new, status: :unprocessable_content
    end
  end

  def edit
    @product = Product.find(params[:id])
    authorize @product

    @product.barcodes.build
  end

  def update
    @product = Product.find(params[:id])
    authorize @product

    # Si se está intentando cambiar el precio, verificar permiso especial
    if price_changing? && !policy(@product).update_prices?
      flash[:alert] = "No tienes permiso para modificar precios. Solo Gerentes pueden hacerlo."
      render :edit, status: :unprocessable_content
      return
    end

    if @product.update(product_params)
      redirect_to products_path, notice: "Tu producto se ha actualizado correctamente"
    else
      render :edit, status: :unprocessable_content
    end
  end

  def destroy
    @product = Product.find(params[:id])
    authorize @product

    if @product.can_be_deleted?
      # Si no tiene historial, eliminar permanentemente
      @product.destroy
      redirect_to products_path, notice: "Producto eliminado permanentemente.", status: :see_other
    else
      # Si tiene historial, solo desactivar
      @product.deactivate!
      redirect_to products_path,
                  notice: "Producto desactivado exitosamente. No se puede eliminar porque tiene historial de inventario o compras.",
                  status: :see_other
    end
  end

  def activate
    @product = Product.find(params[:id])
    authorize @product, :update? # Activar requiere el mismo permiso que editar

    @product.activate!
    redirect_to products_path, notice: "Producto reactivado exitosamente.", status: :see_other
  end

  def search
    # Esta acción es para el POS, todos los usuarios autenticados pueden buscar productos
    # No requiere autorización explícita ya que es solo lectura y necesaria para ventas

    query = params[:q]
    warehouse_id = params[:warehouse_id]

    if query.blank?
      render json: []
      return
    end

    # 1. Primero buscar coincidencia exacta por código de barras
    barcode = Barcode.includes(product: [ :inventories, :barcodes ])
                     .find_by("LOWER(code) = ?", query.downcase)

    if barcode && barcode.product && barcode.product.active?
      # Encontró por código de barras - devolver solo este producto si está activo
      render json: [ format_product_for_pos(barcode.product, warehouse_id) ]
      return
    end

    # 2. Si no encontró por código, buscar por nombre con pg_search (solo activos)
    products = Product.active
                      .search_by_name_description_and_barcode(query)
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
      { barcodes_attributes: [ :id, :code, :_destroy ] }
    ]

    # Solo permitir stock_quantity al crear
    base_params << :stock_quantity if action_name == "create"

    params.require(:product).permit(base_params)
  end

  # Verificar si se está intentando cambiar el precio
  def price_changing?
    return false unless params[:product][:price].present?
    params[:product][:price].to_f != @product.price.to_f
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
      unit: product.sale_unit.abbreviation,
      unit_conversion: product.unit_conversion.to_f
    }
  end
end
