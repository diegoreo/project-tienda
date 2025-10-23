class CustomersController < ApplicationController
  before_action :set_customer, only: %i[show edit update destroy]
  
  def index
    @customers = Customer.order(name: :asc)
    @customers = @customers.by_type(params[:type]) if params[:type].present?
    @customers = @customers.with_debt if params[:with_debt] == 'true'
  end
  
  def show
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
  end
  
  def create
    @customer = Customer.new(customer_params)
    
    if @customer.save
      redirect_to @customer, notice: "Cliente registrado correctamente."
    else
      render :new, status: :unprocessable_entity
    end
  end
  
  def edit
  end
  
  def update
    if @customer.update(customer_params)
      redirect_to @customer, notice: "Cliente actualizado correctamente."
    else
      render :edit, status: :unprocessable_entity
    end
  end
  
  def destroy
    @customer.destroy
    redirect_to customers_path, notice: "Cliente eliminado correctamente."
  rescue ActiveRecord::DeleteRestrictionError
    redirect_to @customer, alert: "No se puede eliminar el cliente porque tiene ventas o pagos registrados."
  end
  
  private
  
  def set_customer
    @customer = Customer.find(params[:id])
  end
  
  def customer_params
    params.require(:customer).permit(
      :name, :phone, :email, :address, :rfc,
      :credit_limit, :customer_type, :notes
    )
  end
end