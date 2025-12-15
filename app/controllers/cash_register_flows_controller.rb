class CashRegisterFlowsController < ApplicationController
  before_action :set_register_session
  before_action :set_flow, only: [:show, :edit, :update, :cancel]
  before_action :authorize_flows

  # GET /register_sessions/:register_session_id/flows
  def index
    @flows = policy_scope(CashRegisterFlow)
              .where(register_session_id: @register_session.id)
              .includes(:created_by, :authorized_by)
              .ordered

    @stats = calculate_flows_stats
  end

  def quick_create
    # 1. Validar que existan los parámetros necesarios
    unless params[:authorized_by_id].present? && params[:password].present?
      return render json: { 
        error: "Faltan datos de autorización" 
      }, status: :bad_request
    end
  
    # 2. Buscar al autorizador
    authorizer = User.find_by(id: params[:authorized_by_id])
    
    unless authorizer
      return render json: { 
        error: "Usuario autorizador no encontrado" 
      }, status: :not_found
    end
  
    # 3. Validar contraseña
    unless authorizer.valid_password?(params[:password])
      return render json: { 
        error: "❌ Contraseña incorrecta" 
      }, status: :unauthorized
    end
  
    # 4. Verificar que el autorizador tenga permisos
    unless authorizer.admin? || authorizer.gerente? || authorizer.supervisor?
      return render json: { 
        error: "Este usuario no tiene permisos para autorizar movimientos" 
      }, status: :forbidden
    end
  
    # 5. Verificar que la sesión esté abierta
    unless @register_session.open?
      return render json: { 
        error: "No se pueden registrar movimientos en una sesión cerrada" 
      }, status: :unprocessable_entity
    end
  
    # 6. Crear el flujo usando quick_flow_params
    @flow = @register_session.cash_register_flows.build(quick_flow_params)
    @flow.created_by = current_user
    @flow.authorized_by = authorizer
  
    if @flow.save
      # Actualizar contadores de la sesión
      @flow.update_session_counters!
      
      # Respuesta exitosa
      render json: { 
        success: true,
        message: "✅ #{@flow.type_name} de $#{'%.2f' % @flow.amount} registrado exitosamente"
      }, status: :created
    else
      # Errores de validación del modelo
      render json: { 
        error: @flow.errors.full_messages.join(", ") 
      }, status: :unprocessable_entity
    end
  end

  # GET /register_sessions/:register_session_id/flows/:id
  def show
    # Vista de detalle de un flujo específico
  end

  # GET /register_sessions/:register_session_id/flows/new
  def new
    @flow = @register_session.cash_register_flows.new
  end

  # POST /register_sessions/:register_session_id/flows
  def create
    @flow = @register_session.cash_register_flows.new(flow_params)
    @flow.created_by = current_user
    @flow.authorized_by = current_user # El que crea también autoriza

    if @flow.save
      # Actualizar contadores EXPLÍCITAMENTE
      @flow.update_session_counters!
      
      redirect_to register_session_cash_register_flows_path(@register_session),
                  notice: "✅ #{@flow.type_name} registrado exitosamente por $#{@flow.amount}"
    else
      flash.now[:alert] = "No se pudo registrar el movimiento: #{@flow.errors.full_messages.join(', ')}"
      render :new, status: :unprocessable_entity
    end
  end


  # GET /register_sessions/:register_session_id/flows/:id/edit
  def edit
    unless @flow.can_be_edited?
      redirect_to register_session_cash_register_flows_path(@register_session),
                  alert: "❌ Este movimiento no puede editarse (está cancelado o la sesión está cerrada)"
      return
    end
  end

  # PATCH/PUT /register_sessions/:register_session_id/flows/:id
  def update
    unless @flow.can_be_edited?
      redirect_to register_session_cash_register_flows_path(@register_session),
                  alert: "❌ Este movimiento no puede editarse (está cancelado o la sesión está cerrada)"
      return
    end

    # Guardar valores anteriores ANTES de actualizar
    old_amount = @flow.amount
    old_type = @flow.movement_type

    if @flow.update(flow_params)
      # Recalcular contadores EXPLÍCITAMENTE solo si cambió monto o tipo
      if @flow.saved_change_to_amount? || @flow.saved_change_to_movement_type?
        @flow.recalculate_session_counters!(old_amount, old_type)
      end
      
      redirect_to register_session_cash_register_flows_path(@register_session),
                  notice: "✅ #{@flow.type_name} actualizado exitosamente"
    else
      flash.now[:alert] = "No se pudo actualizar el movimiento: #{@flow.errors.full_messages.join(', ')}"
      render :edit, status: :unprocessable_entity
    end
  end

  # POST /register_sessions/:register_session_id/flows/:id/cancel
  def cancel
    unless @flow.can_be_cancelled?
      redirect_to register_session_cash_register_flows_path(@register_session),
                  alert: "❌ Este movimiento no puede cancelarse (ya está cancelado o la sesión está cerrada)"
      return
    end

    cancellation_reason = params[:cancellation_reason]

    if cancellation_reason.blank?
      redirect_to register_session_cash_register_flows_path(@register_session),
                  alert: "❌ Debe proporcionar una razón para cancelar el movimiento"
      return
    end

    # Actualizar registro con datos de cancelación
    if @flow.update(
      cancelled: true,
      cancelled_by: current_user,
      cancelled_at: Time.current,
      cancellation_reason: cancellation_reason
    )
      # Revertir contadores EXPLÍCITAMENTE
      @flow.revert_session_counters!
      
      redirect_to register_session_cash_register_flows_path(@register_session),
                  notice: "✅ Movimiento cancelado exitosamente"
    else
      redirect_to register_session_cash_register_flows_path(@register_session),
                  alert: "❌ No se pudo cancelar el movimiento: #{@flow.errors.full_messages.join(', ')}"
    end
  end

  private


  def set_register_session
    @register_session = RegisterSession.find(params[:register_session_id])
  end

  def set_flow
    @flow = @register_session.cash_register_flows.find(params[:id])
    authorize @flow
  end

  def authorize_flows
    authorize @register_session, :manage_flows?
  end

  def flow_params
    params.require(:cash_register_flow).permit(
      :movement_type,
      :amount,
      :description
    )
  end

  def quick_flow_params
    params.permit(:movement_type, :amount, :description)
  end

  def calculate_flows_stats
    total_inflows = @register_session.cash_register_flows.inflows.active.sum(:amount)
    total_outflows = @register_session.cash_register_flows.outflows.active.sum(:amount)
    
    {
      total_inflows: total_inflows,
      total_outflows: total_outflows,
      net_flow: total_inflows - total_outflows,
      flows_count: @register_session.cash_register_flows.count,
      inflows_count: @register_session.cash_register_flows.inflows.active.count,
      outflows_count: @register_session.cash_register_flows.outflows.active.count
    }
  end
end