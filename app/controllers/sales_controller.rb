class SalesController < ApplicationController
  before_action :set_sale, only: %i[show edit update destroy cancel payments]

  def index
    authorize Sale

    # Construir query (sin @, solo variable local)
    sales = policy_scope(Sale).includes(:customer, :warehouse, :user, register_session: :register).order(sale_date: :desc, created_at: :desc)

    # Control de visualización de costos
    @show_costs = policy(Sale).view_costs?

    # Filtro por folio
    sales = sales.where(id: params[:folio]) if params[:folio].present?

    # Filtro por rango de fechas
    sales = sales.where("sale_date >= ?", params[:date_from]) if params[:date_from].present?
    sales = sales.where("sale_date <= ?", params[:date_to]) if params[:date_to].present?

    # Filtro por cliente
    sales = sales.where(customer_id: params[:customer_id]) if params[:customer_id].present?

    # Filtro por almacén
    sales = sales.where(warehouse_id: params[:warehouse_id]) if params[:warehouse_id].present?

    # Filtro por método de pago
    sales = sales.where(payment_method: params[:payment_method]) if params[:payment_method].present?

    # Filtro por estado de pago
    sales = sales.where(payment_status: params[:payment_status]) if params[:payment_status].present?

    # Filtro por estado (completada/cancelada)
    sales = sales.where(status: params[:status]) if params[:status].present?

    # Filtro para ventas con deuda pendiente
    if params[:with_pending_amount] == "true"
      sales = sales.where("pending_amount > 0")
    end

    # PAGINACIÓN (25 ventas por página)
    @pagy, @sales = pagy(sales, items: 25)
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
  
    # VALIDACIÓN: Verificar sesión abierta ANTES de mostrar formulario
    @current_session = current_user_open_session
  
    unless @current_session
      redirect_to register_sessions_path, alert: "⚠️ Debe abrir un turno de caja antes de realizar ventas. Por favor, abra un turno primero."
      return
    end
  
    # Si viene de una venta exitosa, restaurar configuración
    if params[:success] == "true"
      @sale = Sale.new(
        customer_id: params[:customer_id],
        warehouse_id: params[:warehouse_id],
        payment_method: params[:payment_method] || "cash",
        sale_date: Date.current
      )
  
      @success_message = "✅ Venta ##{params[:sale_id]} registrada - Total: $#{sprintf('%.2f', params[:total].to_f)}"
    else
      @sale = Sale.new(sale_date: Date.current)
  
      # Establecer cliente por defecto
      default_customer = Customer.where("LOWER(TRIM(name)) LIKE ?", "%general%")
                          .order(created_at: :asc)
                          .first
      @sale.customer_id = default_customer&.id if default_customer
  
      # Establecer almacén por defecto (usar el de la sesión actual)
      @sale.warehouse_id = @current_session.register.warehouse_id
    end
  
    # Crear primer item con valores por defecto
    @sale.sale_items.build(quantity: 1, discount: 0)
  
    # Cargar supervisores que pueden autorizar flujos (Admin, Gerente, Supervisor)
    @authorizers = User.where(role: [:admin, :gerente, :supervisor])
                       .order(:name)
  end

  def create
    @sale = Sale.new(sale_params)
    @sale.sale_date = Date.current
    @sale.user = current_user

    authorize @sale

    # VALIDACIÓN: Verificar sesión abierta ANTES de procesar venta
    @current_session = current_user_open_session

    unless @current_session
      flash[:alert] = "⚠️ Debe aperturar caja antes de realizar ventas."
      redirect_to register_sessions_path
      return
    end

    # Asignar sesión activa del usuario
    @sale.register_session = @current_session

    # Calcular subtotales de cada item
    @sale.sale_items.each do |item|
      item.subtotal = item.calculate_subtotal
    end

    if @sale.save
      # process_sale! ya actualiza los contadores internamente
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
      # Pasar usuario que cancela y razón
      @sale.cancel_sale!(current_user, "Cancelada desde listado")
      redirect_to sales_path, notice: "Venta cancelada correctamente."
    else
      redirect_to @sale, alert: "Esta venta ya está cancelada."
    end
  end

  def cancel
    authorize @sale

    if @sale.can_be_cancelled?
      # Pasar usuario que cancela y razón (opcional)
      # 🔥 cancel_sale! ahora revierte:
      # - Inventario
      # - Deuda del cliente (usando pending_amount)
      cancellation_reason = params[:cancellation_reason] || "Cancelada manualmente"
      @sale.cancel_sale!(current_user, cancellation_reason)
      redirect_to @sale, notice: "Venta cancelada y inventario restaurado."
    else
      redirect_to @sale, alert: "Esta venta ya está cancelada."
    end
  end

  # Acción para mostrar detalle de pagos de una venta
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

  # MÉTODO NUEVO: Obtener sesión abierta del usuario actual
  def current_user_open_session
    if current_user.admin? || current_user.gerente?
      # Admin y gerente pueden usar cualquier sesión abierta
      # Priorizar sesiones del día actual
      RegisterSession.open_sessions
                     .where("opened_at >= ?", Date.current.beginning_of_day)
                     .order(opened_at: :desc)
                     .first
    else
      # Cajeros y supervisores solo sus propias sesiones abiertas
      RegisterSession.open_sessions
                     .where(opened_by: current_user)
                     .order(opened_at: :desc)
                     .first
    end
  end

  # MÉTODO DEPRECADO: Ya no se usa, reemplazado por current_user_open_session
  # Lo dejamos por compatibilidad pero ya no se llama
  def find_active_register_session
    current_user_open_session
  end
end
