class SalesController < ApplicationController
  before_action :set_sale, only: %i[show edit update destroy cancel]
  
  def index
    @sales = Sale.includes(:customer, :warehouse, :sale_items).order(sale_date: :desc, created_at: :desc)
    
    # Filtro por folio
    @sales = @sales.where(id: params[:folio]) if params[:folio].present?
    
    # Filtro por rango de fechas
    @sales = @sales.where('sale_date >= ?', params[:date_from]) if params[:date_from].present?
    @sales = @sales.where('sale_date <= ?', params[:date_to]) if params[:date_to].present?
    
    # Filtro por cliente
    @sales = @sales.where(customer_id: params[:customer_id]) if params[:customer_id].present?
    
    # Filtro por almacén
    @sales = @sales.where(warehouse_id: params[:warehouse_id]) if params[:warehouse_id].present?
    
    # Filtro por método de pago
    @sales = @sales.where(payment_method: params[:payment_method]) if params[:payment_method].present?
    
    # Filtro por estado de pago
    @sales = @sales.where(payment_status: params[:payment_status]) if params[:payment_status].present?
    
    # Filtro por estado (completada/cancelada)
    @sales = @sales.where(status: params[:status]) if params[:status].present?
  end
  
  def show
  end
  
  def new
    # Si viene de una venta exitosa, restaurar configuración
    if params[:success] == 'true'
      @sale = Sale.new(
        customer_id: params[:customer_id],
        warehouse_id: params[:warehouse_id],
        payment_method: params[:payment_method] || 'cash',
        sale_date: Date.current
      )
      
      @success_message = "✅ Venta ##{params[:sale_id]} registrada - Total: #{view_context.number_to_currency(params[:total])}"
    else
      @sale = Sale.new(sale_date: Date.current)
      
      # Establecer cliente por defecto
      public_customer = Customer.find_by(name: "Público General")
      @sale.customer_id = public_customer.id if public_customer
      # Establecer almacén por defecto (el primero si no hay uno guardado)
      # El JavaScript se encargará de restaurar la preferencia guardada
      @sale.warehouse_id = Warehouse.first&.id
    end
    # Crear primer item con valores por defecto
    @sale.sale_items.build(quantity: 1, discount: 0)
  end
  
  def create
    @sale = Sale.new(sale_params)
    @sale.sale_date = Date.current
    
    @sale.sale_items.each do |item|
      item.subtotal = item.calculate_subtotal
    end
    
    if @sale.save
      @sale.process_sale!
      
      # Redirigir a new con parámetros de éxito
      redirect_to new_sale_path(
        success: true,
        sale_id: @sale.id,
        total: @sale.total,
        customer_id: @sale.customer_id,
        warehouse_id: @sale.warehouse_id,
        payment_method: @sale.payment_method
      ), notice: "Venta registrada correctamente"
    else
      render :new, status: :unprocessable_entity
    end
  end
  
  def edit
    unless @sale.can_be_cancelled?
      redirect_to @sale, alert: "Esta venta ya fue cancelada y no puede editarse."
      return
    end
    
    @sale.sale_items.build if @sale.sale_items.empty?
  end
  
  def update
    # Por seguridad, no permitir editar ventas procesadas
    redirect_to @sale, alert: "No se pueden editar ventas ya procesadas."
  end
  
  def destroy
    if @sale.can_be_cancelled?
      @sale.cancel_sale!
      redirect_to sales_path, notice: "Venta cancelada correctamente."
    else
      redirect_to @sale, alert: "Esta venta ya está cancelada."
    end
  end
  
  def cancel
    if @sale.can_be_cancelled?
      @sale.cancel_sale!
      redirect_to @sale, notice: "Venta cancelada y inventario restaurado."
    else
      redirect_to @sale, alert: "Esta venta ya está cancelada."
    end
  end
  
  private
  
  def set_sale
    @sale = Sale.find(params[:id])
  end
  
  def sale_params
    params.require(:sale).permit(
      :customer_id, :warehouse_id, :payment_method, :notes,
      sale_items_attributes: [
        :id, :product_id, :quantity, :unit_price, :discount, :subtotal, :_destroy
      ]
    )
  end
end