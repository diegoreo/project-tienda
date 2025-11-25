require "csv"

class InventoriesController < ApplicationController
  # Sin callbacks - todo explícito

  def index
    authorize Inventory
    inventories = policy_scope(Inventory).includes(:product, :warehouse)

    # Filtro por búsqueda (nombre de producto o código de barras)
    if params[:query].present?
      inventories = inventories.joins(:product)
        .left_joins(product: :barcodes)
        .where(
          "products.name ILIKE :query OR barcodes.code ILIKE :query",
          query: "%#{params[:query]}%"
        )
        .distinct
    end

    # Filtro por almacén
    if params[:warehouse_id].present?
      inventories = inventories.where(warehouse_id: params[:warehouse_id])
    end

    # Filtro por estado de stock
    case params[:stock_status]
    when "low"
      inventories = inventories.where("quantity <= ?", 10)
    when "medium"
      inventories = inventories.where("quantity > ? AND quantity <= ?", 10, 50)
    when "optimal"
      inventories = inventories.where("quantity > ?", 50)
      # 'all' o nil - mostrar todos (sin filtro)
    end

    # Filtro por categoría
    if params[:category_id].present?
      inventories = inventories.joins(:product).where(products: { category_id: params[:category_id] })
    end

    # Ordenamiento clickeable
    sort_column = params[:sort] || "quantity"
    sort_direction = params[:direction] || "asc"

    # Validar que la dirección sea segura
    sort_direction = %w[asc desc].include?(sort_direction) ? sort_direction : "asc"

    case sort_column
    when "product_name"
      inventories = inventories.joins(:product).order("products.name #{sort_direction}")
    when "warehouse_name"
      inventories = inventories.joins(:warehouse).order("warehouses.name #{sort_direction}")
    when "quantity"
      inventories = inventories.order("quantity #{sort_direction}")
    when "value"
      # Usar Arel.sql() para cálculos dinámicos
      inventories = inventories.joins(:product).order(Arel.sql("inventories.quantity * products.price #{sort_direction}"))
    else
      inventories = inventories.order("quantity #{sort_direction}")
    end

    # Cargar warehouses y categories para los filtros
    @warehouses = Warehouse.order(:name)
    @categories = Category.order(:name)

    # Estadísticas para el header
    @total_inventories = inventories.count
    @low_stock_count = inventories.where("quantity <= ?", 10).count
    @total_warehouses = @warehouses.count

    # Variable para controlar visualización de costos
    @show_costs = policy(Inventory).view_costs?

    # Calcular valor total del inventario (antes de la paginación)
    # Solo si tiene permiso para ver costos
    if @show_costs
      @total_inventory_value = inventories.joins(:product).sum("inventories.quantity * products.price")
    else
      @total_inventory_value = nil
    end

    # Responder a diferentes formatos
    respond_to do |format|
      format.html do
        # SOLO EN HTML: PAGINAR (30 por página)
        @pagy, @inventories = pagy(inventories, items: 30)
      end

      format.csv do
        # EN CSV: NO PAGINAR (exportar todo lo filtrado)
        authorize Inventory, :export?
        @inventories = inventories  # Todo lo filtrado
        send_data generate_csv(@inventories), filename: "inventario-#{Date.today}.csv"
      end
    end
  end

  def show
    @inventory = Inventory.find(params[:id])
    authorize @inventory

    # Variable para controlar visualización de costos
    @show_costs = policy(@inventory).view_costs?
  end

  private

  def generate_csv(inventories)
    require "csv"

    CSV.generate(headers: true) do |csv|
      # Encabezados (adaptar según permisos)
      if @show_costs
        csv << [
          "ID",
          "Producto",
          "Categoría",
          "Almacén",
          "Cantidad",
          "Unidad",
          "Precio Unitario",
          "Valor Total",
          "Estado"
        ]
      else
        csv << [
          "ID",
          "Producto",
          "Categoría",
          "Almacén",
          "Cantidad",
          "Unidad",
          "Estado"
        ]
      end

      # Datos
      inventories.each do |inventory|
        status = if inventory.quantity > 50
                   "Óptimo"
        elsif inventory.quantity > 10
                   "Medio"
        else
                   "Bajo"
        end

        if @show_costs
          csv << [
            inventory.id,
            inventory.product.name,
            inventory.product.category&.name || "Sin categoría",
            inventory.warehouse.name,
            inventory.quantity.to_i,
            inventory.product.sale_unit.abbreviation,
            inventory.product.price.to_f,
            (inventory.quantity * inventory.product.price).to_f,
            status
          ]
        else
          csv << [
            inventory.id,
            inventory.product.name,
            inventory.product.category&.name || "Sin categoría",
            inventory.warehouse.name,
            inventory.quantity.to_i,
            inventory.product.sale_unit.abbreviation,
            status
          ]
        end
      end
    end
  end
end
