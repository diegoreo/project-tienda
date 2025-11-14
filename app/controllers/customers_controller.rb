class CustomersController < ApplicationController
  def index
    # Autorizar el acceso al índice de clientes
    authorize Customer
    
    customers = Customer.order(name: :asc)

    # Aplicar filtros
    customers = customers.by_type(params[:type]) if params[:type].present?
    customers = customers.with_debt if params[:with_debt] == 'true'

    # PAGINACIÓN (25 clientes por página)
    @pagy, @customers = pagy(customers, items: 25)
  end
  
  def show
    @customer = Customer.find(params[:id])
    authorize @customer
    
    # Ventas pendientes de pago (las más importantes)
    @pending_sales = @customer.pending_sales.includes(:warehouse).limit(10)
    
    # Todas las ventas recientes
    @all_sales = @customer.sales.order(sale_date: :desc).includes(:warehouse).limit(20)
    
    # Pagos recientes
    @recent_payments = @customer.payments.recent.includes(:sale).limit(10)
    
    # Estadísticas
    @total_sales = @customer.sales.count
    @total_sales_amount = @customer.total_sales_amount
    @total_credit_sales = @customer.total_credit_sales
    @total_payments = @customer.total_paid_amount
  end
  
  def new
    @customer = Customer.new
    authorize @customer
  end
  
  def create
    @customer = Customer.new(customer_params)
    authorize @customer
    
    # Verificar si está intentando establecer un límite de crédito
    if credit_limit_changing? && !policy(@customer).update_credit_limit?
      flash.now[:alert] = "No tienes permiso para establecer límite de crédito. Solo Gerentes pueden hacerlo."
      render :new, status: :unprocessable_entity
      return
    end
    
    if @customer.save
      redirect_to @customer, notice: "Cliente registrado correctamente."
    else
      render :new, status: :unprocessable_entity
    end
  end
  
  def edit
    @customer = Customer.find(params[:id])
    authorize @customer
  end
  
  def update
    @customer = Customer.find(params[:id])
    authorize @customer
    
    # Verificar si está intentando cambiar el límite de crédito
    if credit_limit_changing? && !policy(@customer).update_credit_limit?
      flash.now[:alert] = "No tienes permiso para modificar el límite de crédito. Solo Gerentes pueden hacerlo."
      render :edit, status: :unprocessable_entity
      return
    end
    
    if @customer.update(customer_params)
      redirect_to @customer, notice: "Cliente actualizado correctamente."
    else
      render :edit, status: :unprocessable_entity
    end
  end
  
  def destroy
    @customer = Customer.find(params[:id])
    authorize @customer
    
    @customer.destroy
    redirect_to customers_path, notice: "Cliente eliminado correctamente.", status: :see_other
  rescue ActiveRecord::DeleteRestrictionError
    redirect_to @customer, 
                alert: "No se puede eliminar el cliente porque tiene ventas o pagos registrados.",
                status: :see_other
  end
  
  private
  
  def customer_params
    params.require(:customer).permit(
      :name, :phone, :email, :address, :rfc,
      :credit_limit, :customer_type, :notes
    )
  end
  
  # Verifica si se está intentando cambiar el límite de crédito
  def credit_limit_changing?
    return false unless params[:customer][:credit_limit].present?
    
    # En create, cualquier valor > 0 significa que está estableciendo crédito
    return true if action_name == 'create' && params[:customer][:credit_limit].to_f > 0
    
    # En update, verificar si el valor cambió
    params[:customer][:credit_limit].to_f != @customer.credit_limit.to_f
  end
end