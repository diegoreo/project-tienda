class CustomersController < ApplicationController
  before_action :set_customer, only: %i[show edit update destroy]
  
  def index
    @customers = Customer.order(name: :asc)
    @customers = @customers.by_type(params[:type]) if params[:type].present?
    @customers = @customers.with_debt if params[:with_debt] == 'true'
  end
  
  def show
    #@sales = @customer.sales.order(sale_date: :desc).limit(10)
    #@payments = @customer.payments.order(payment_date: :desc).limit(10)
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
    redirect_to @customer, alert: "No se puede eliminar el cliente porque tiene ventas registradas."
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