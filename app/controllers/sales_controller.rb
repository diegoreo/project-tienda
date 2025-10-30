class SalesController < ApplicationController
  before_action :set_sale, only: %i[show edit update destroy cancel payments]
  
  def index
    authorize Sale
    @sales = policy_scope(Sale).includes(:customer, :warehouse, :sale_items).order(sale_date: :desc, created_at: :desc)
    
    # Control de visualización de costos
    @show_costs = policy(Sale).view_costs?
    
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
    
    # 🆕 Filtro para ventas con deuda pendiente
    if params[:with_pending_amount] == 'true'
      @sales = @sales.where("pending_amount > 0")
    end
  end
  
  def show
    authorize @sale
    
    # Control de visualización de costos
    @show_costs = policy(@sale).view_costs?
    
    # Cargar pagos asociados a esta venta (si existen)
    @payments = @sale.payments.order(payment_date: :desc) if @sale.payments.any?
  end
  
  def new
    authorize Sale
    
    # Si viene de una venta exitosa, restaurar configuración
    if params[:success] == 'true'
      @sale = Sale.new(
        customer_id: params[:customer_id],
        warehouse_id: params[:warehouse_id],
        payment_method: params[:payment_method] || 'cash',
        sale_date: Date.current
      )
      
      @success_message = "✅ Venta ##{params[:sale_id]} registrada - Total: $#{sprintf('%.2f', params[:total].to_f)}"
    else
      @sale = Sale.new(sale_date: Date.current)
      
      # Establecer cliente por defecto
      public_customer = Customer.find_by(name: "Público General")
      @sale.customer_id = public_customer.id if public_customer
      
      # Establecer almacén por defecto
      @sale.warehouse_id = Warehouse.first&.id
    end
    
    # Crear primer item con valores por defecto
    @sale.sale_items.build(quantity: 1, discount: 0)
  end
  
  def create
    @sale = Sale.new(sale_params)
    @sale.sale_date = Date.current
    
    authorize @sale
    
    # Calcular subtotales de cada item
    @sale.sale_items.each do |item|
      item.subtotal = item.calculate_subtotal
    end
    
    if @sale.save
      # 🔥 process_sale! ahora maneja TODO:
      # - Calcula el total
      # - Establece pending_amount según payment_method
      # - Establece payment_status según payment_method
      # - Actualiza inventario
      # - Actualiza deuda del cliente si es crédito
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
    authorize @sale
    
    unless @sale.can_be_cancelled?
      redirect_to @sale, alert: "Esta venta ya fue cancelada y no puede editarse."
      return
    end
    
    @sale.sale_items.build if @sale.sale_items.empty?
  end
  
  def update
    authorize @sale
    
    # Por seguridad, no permitir editar ventas procesadas
    redirect_to @sale, alert: "No se pueden editar ventas ya procesadas."
  end
  
  def destroy
    authorize @sale
    
    if @sale.can_be_cancelled?
      @sale.cancel_sale!
      redirect_to sales_path, notice: "Venta cancelada correctamente."
    else
      redirect_to @sale, alert: "Esta venta ya está cancelada."
    end
  end
  
  def cancel
    authorize @sale
    
    if @sale.can_be_cancelled?
      # 🔥 cancel_sale! ahora revierte:
      # - Inventario
      # - Deuda del cliente (usando pending_amount)
      @sale.cancel_sale!
      redirect_to @sale, notice: "Venta cancelada y inventario restaurado."
    else
      redirect_to @sale, alert: "Esta venta ya está cancelada."
    end
  end
  
  # 🆕 Acción para mostrar detalle de pagos de una venta
  def payments
    authorize @sale
    
    # Control de visualización de costos
    @show_costs = policy(@sale).view_costs?
    
    @payments = @sale.payments.order(payment_date: :desc)
    
    unless @sale.has_pending_amount?
      redirect_to @sale, alert: "Esta venta no tiene saldo pendiente."
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