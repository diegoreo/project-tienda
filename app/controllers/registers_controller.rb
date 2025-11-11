class RegistersController < ApplicationController
  before_action :set_register, only: [:show, :edit, :update, :destroy, :toggle_active]
  before_action :authorize_register, only: [:show, :edit, :update, :destroy, :toggle_active]
  
  # GET /registers
  def index
    authorize Register
    @registers = policy_scope(Register).includes(:warehouse, :register_sessions)
                                       .order(:code)
    
    # Filtros opcionales
    @registers = @registers.by_warehouse(params[:warehouse_id]) if params[:warehouse_id].present?
    @registers = @registers.active if params[:status] == 'active'
    @registers = @registers.inactive if params[:status] == 'inactive'
  end
  
  # GET /registers/:id
  def show
    @current_session = @register.current_session
    @recent_sessions = @register.register_sessions.order(opened_at: :desc).limit(10)
    @stats = calculate_register_stats(@register)
  end
  
  # GET /registers/new
  def new
    @register = Register.new
    authorize @register
    @warehouses = Warehouse.order(:name)
  end
  
  # POST /registers
  def create
    @register = Register.new(register_params)
    authorize @register
    
    if @register.save
      redirect_to @register, notice: "Caja creada exitosamente."
    else
      @warehouses = Warehouse.order(:name)
      render :new, status: :unprocessable_entity
    end
  end
  
  # GET /registers/:id/edit
  def edit
    @warehouses = Warehouse.order(:name)
  end
  
  # PATCH/PUT /registers/:id
  def update
    if @register.update(register_params)
      redirect_to @register, notice: "Caja actualizada exitosamente."
    else
      @warehouses = Warehouse.order(:name)
      render :edit, status: :unprocessable_entity
    end
  end
  
  # DELETE /registers/:id
  def destroy
    if @register.can_be_destroyed?
      @register.destroy
      redirect_to registers_path, notice: "Caja eliminada exitosamente."
    else
      redirect_to @register, alert: "No se puede eliminar la caja porque tiene sesiones registradas."
    end
  end
  
  # PATCH /registers/:id/toggle_active
  def toggle_active
    authorize @register, :toggle_active?
    
    if @register.active?
      if @register.deactivate!
        redirect_to @register, notice: "Caja desactivada exitosamente."
      else
        redirect_to @register, alert: @register.errors.full_messages.join(", ")
      end
    else
      @register.activate!
      redirect_to @register, notice: "Caja activada exitosamente."
    end
  end
  
  private
  
  def set_register
    @register = Register.find(params[:id])
  end
  
  def authorize_register
    authorize @register
  end
  
  def register_params
    params.require(:register).permit(
      :code,
      :name,
      :description,
      :initial_balance,
      :location,
      :warehouse_id,
      :active
    )
  end
  
  def calculate_register_stats(register)
    {
      total_sessions: register.total_sessions,
      closed_sessions: register.closed_sessions_count,
      total_sales: register.total_sales_amount,
      last_session_date: register.last_session&.opened_at
    }
  end
end