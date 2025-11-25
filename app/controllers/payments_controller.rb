class PaymentsController < ApplicationController
  before_action :set_customer
  before_action :set_payment, only: [ :destroy ]

  def index
    @payments = @customer.payments.recent.includes(:sale)
  end

  def new
    @payment = @customer.payments.build(payment_date: Date.today)
    @pending_sales = @customer.pending_sales
  end

  def create
    @payment = @customer.payments.build(payment_params)

    if @payment.save
      # La actualización de deuda se hace automáticamente en el modelo Payment
      # Si prefieres hacerlo manual (sin callbacks), descomenta:
      # @customer.reduce_debt!(@payment.amount)

      redirect_to customer_path(@customer), notice: "Pago registrado correctamente. Deuda actual: $#{sprintf('%.2f', @customer.reload.current_debt)}"
    else
      @pending_sales = @customer.pending_sales
      render :new, status: :unprocessable_entity
    end
  end

  def destroy
    amount = @payment.amount

    if @payment.destroy
      # La reversión se hace automáticamente en el callback
      redirect_to customer_path(@customer), notice: "Pago eliminado. Deuda actual: $#{sprintf('%.2f', @customer.reload.current_debt)}"
    else
      redirect_to customer_path(@customer), alert: "No se pudo eliminar el pago."
    end
  end

  private

  def set_customer
    @customer = Customer.find(params[:customer_id])
  end

  def set_payment
    @payment = @customer.payments.find(params[:id])
  end

  def payment_params
    params.require(:payment).permit(
      :sale_id, :amount, :payment_date, :payment_method, :notes
    )
  end
end
