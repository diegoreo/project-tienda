class RegisterSessionsController < ApplicationController
  before_action :set_register_session, only: [:show, :close, :process_close, :closure_report, :closure_report_detailed]
  before_action :authorize_register_session, only: [:show, :close, :process_close, :closure_report, :closure_report_detailed]
  
  # GET /register_sessions
  def index
    authorize RegisterSession
    @register_sessions = policy_scope(RegisterSession)
                          .includes(:register, :opened_by, :closed_by)
                          .order(opened_at: :desc)
                          #.page(params[:page]).per(20) cuando tengamos paginacion decomentar y quitar la linea de abajo
                          .limit(50)
    
    # Filtros
    @register_sessions = @register_sessions.by_register(params[:register_id]) if params[:register_id].present?
    @register_sessions = @register_sessions.open_sessions if params[:status] == 'open'
    @register_sessions = @register_sessions.closed_sessions if params[:status] == 'closed'
    @register_sessions = @register_sessions.by_date(params[:date]) if params[:date].present?
    
    # Estadísticas del día
    @today_stats = calculate_today_stats
  end
  
  # GET /register_sessions/:id
  def show
    # Validar permisos ANTES de mostrar
    unless policy(@register_session).show?
      redirect_to register_sessions_path, alert: "No tiene permisos para ver los detalles de esta sesión."
      return
    end
    
    @sales = @register_session.sales.includes(:customer, :user, :sale_items)
                               .order(created_at: :desc)
    @cancelled_sales = @register_session.sales.cancelled.includes(:cancelled_by)
    @current_session = @register_session if @register_session.open?
    @recent_sessions = @register_session.register.register_sessions
                                        .where.not(id: @register_session.id)
                                        .order(opened_at: :desc)
                                        .limit(10)
    @session_stats = calculate_session_stats(@register_session)
    @stats = {
      total_sessions: @register_session.register.register_sessions.count,
      closed_sessions: @register_session.register.register_sessions.closed_sessions.count,
      total_sales: @register_session.register.register_sessions.sum(:total_sales),
      last_session_date: @register_session.register.register_sessions.maximum(:opened_at)
    }
  end
  
  # GET /register_sessions/new
  def new
    @register_session = RegisterSession.new
    authorize @register_session
    
    # Solo mostrar cajas disponibles (activas y sin sesión abierta)
    @available_registers = Register.active
                                   .select { |r| r.available_for_opening? }
    
    if @available_registers.empty?
      redirect_to register_sessions_path, alert: "No hay cajas disponibles para abrir. Todas las cajas tienen sesiones abiertas o están inactivas."
    end
  end
  
  # POST /register_sessions
  def create
    @register_session = RegisterSession.new(register_session_create_params)
    @register_session.opened_by = current_user
    @register_session.opened_at = Time.current
    @register_session.status = :open
    
    authorize @register_session
    
    if @register_session.save
      redirect_to @register_session, notice: "Turno abierto exitosamente. Puede comenzar a vender."
    else
      @available_registers = Register.active.select { |r| r.available_for_opening? }
      render :new, status: :unprocessable_entity
    end
  end
  
  # GET /register_sessions/:id/close
  def close
    authorize @register_session, :close?
    
    unless @register_session.can_be_closed?
      redirect_to @register_session, alert: "Esta sesión ya está cerrada o no puede cerrarse."
      return
    end
    
    # Calcular balance esperado y actualizar
    @register_session.update_expected_balance!
    
    # Resumen para el cierre
    @closure_summary = calculate_closure_summary
  end
  
  # PATCH /register_sessions/:id/process_close
  def process_close
    authorize @register_session, :process_close?
    
    unless @register_session.can_be_closed?
      redirect_to @register_session, alert: "Esta sesión ya está cerrada o no puede cerrarse."
      return
    end
    
    # Validar que vengan los parámetros
    unless params[:register_session].present?
      @closure_summary = calculate_closure_summary
      flash.now[:alert] = "Faltan datos para cerrar el turno"
      render :close, status: :unprocessable_entity
      return
    end
    
    # Obtener parámetros del formulario
    closing_balance = params[:register_session][:closing_balance].to_f
    closing_notes = params[:register_session][:closing_notes]
    
    # Validar que el monto sea válido
    if closing_balance < 0
      @closure_summary = calculate_closure_summary
      flash.now[:alert] = "El monto de cierre debe ser mayor o igual a cero"
      render :close, status: :unprocessable_entity
      return
    end
    
    # Cerrar la sesión
    begin
      if @register_session.close_session!(closing_balance, current_user, closing_notes)
        redirect_to closure_report_register_session_path(@register_session), notice: "✅ Turno cerrado exitosamente."
      else
        @closure_summary = calculate_closure_summary
        flash.now[:alert] = "No se pudo cerrar el turno. Verifique los datos."
        render :close, status: :unprocessable_entity
      end
    rescue => e
      @closure_summary = calculate_closure_summary
      flash.now[:alert] = "Error al cerrar el turno: #{e.message}"
      render :close, status: :unprocessable_entity
    end
  end
  
  # GET /register_sessions/:id/closure_report (Reporte Básico)
  def closure_report
    authorize @register_session, :closure_report?
    
    unless @register_session.closed?
      redirect_to @register_session, alert: "No se puede ver el reporte de una sesión abierta."
      return
    end
    
    @report_data = build_report_data
  end
  
  # GET /register_sessions/:id/closure_report_detailed (Reporte Completo)
  def closure_report_detailed
    authorize @register_session, :closure_report_detailed?
    
    unless @register_session.closed?
      redirect_to @register_session, alert: "No se puede ver el reporte de una sesión abierta."
      return
    end
    
    @sales = @register_session.sales.completed.includes(:customer, :user)
    @cancelled_sales = @register_session.sales.cancelled.includes(:cancelled_by)
    
    @report_data = build_report_data
    
    respond_to do |format|
      format.html
      format.pdf do
        render pdf: "cierre_caja_#{@register_session.id}",
               template: "register_sessions/closure_report_detailed",
               layout: "pdf"
      end
    end
  end
  
  private
  
  def set_register_session
    @register_session = RegisterSession.find(params[:id])
  end
  
  def authorize_register_session
    authorize @register_session
  end
  
  def register_session_create_params
    params.require(:register_session).permit(
      :register_id,
      :opening_balance,
      :opening_notes
    )
  end
  
  def register_session_close_params
    params.require(:register_session).permit(
      :closing_balance,
      :closing_notes
    )
  end
  
  # MÉTODO ACTUALIZADO: Construir datos del reporte
  def build_report_data
    {
      register: @register_session.register,
      opened_by: @register_session.opened_by,
      closed_by: @register_session.closed_by,
      opened_at: @register_session.opened_at,
      closed_at: @register_session.closed_at,
      duration: @register_session.duration_in_hours,
      opening_balance: @register_session.opening_balance,
      closing_balance: @register_session.closing_balance,
      expected_balance: @register_session.expected_balance,
      difference: @register_session.difference,
      total_sales: @register_session.total_sales,
      total_cash_sales: @register_session.total_cash_sales,
      total_card_sales: @register_session.total_card_sales,
      total_credit_sales: @register_session.total_credit_sales,
      sales_count: @register_session.sales_count,
      cancelled_sales_count: @register_session.cancelled_sales_count,
      cancelled_sales_total: @register_session.cancelled_sales_total,
      cancellation_rate: @register_session.cancellation_rate,
      average_ticket: @register_session.average_ticket,
      sales_per_hour: @register_session.sales_per_hour
    }
  end
  
  def calculate_closure_summary
    @register_session.update_expected_balance!
    
    {
      opening_balance: @register_session.opening_balance,
      total_sales: @register_session.total_sales,
      total_cash_sales: @register_session.total_cash_sales,
      total_card_sales: @register_session.total_card_sales,
      total_credit_sales: @register_session.total_credit_sales,
      sales_count: @register_session.sales_count,
      cancelled_sales_count: @register_session.cancelled_sales_count,
      cancelled_sales_total: @register_session.cancelled_sales_total,
      expected_balance: @register_session.expected_balance
    }
  end
  
  def calculate_today_stats
    today_sessions = RegisterSession.today
    
    {
      total_sessions: today_sessions.count,
      open_sessions: today_sessions.open_sessions.count,
      closed_sessions: today_sessions.closed_sessions.count,
      total_sales: today_sessions.sum(:total_sales),
      total_cash_sales: today_sessions.sum(:total_cash_sales)
    }
  end
  
  def calculate_session_stats(session)
    {
      duration: session.duration_in_hours,
      average_ticket: session.average_ticket,
      sales_per_hour: session.sales_per_hour,
      cancellation_rate: session.cancellation_rate,
      has_shortage: session.has_shortage?,
      has_surplus: session.has_surplus?,
      shortage_amount: session.shortage_amount,
      surplus_amount: session.surplus_amount
    }
  end
end