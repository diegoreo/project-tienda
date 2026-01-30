class CompaniesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_company
  before_action :authorize_company_access
  
  def show
    # Mostrar datos de la empresa
  end
  
  def edit
    # Formulario de edición
  end
  
  def update
    @company.assign_attributes(company_params)
    
    # Normalización EXPLÍCITA antes de guardar
    @company.normalize_attributes!
    
    if @company.save
      redirect_to company_path, notice: "✅ Información actualizada correctamente."
    else
      flash.now[:alert] = "❌ Error al actualizar la información."
      render :edit, status: :unprocessable_entity
    end
  end
  
  private
  
  def set_company
    @company = Company.current
  end
  
  def authorize_company_access
    authorize @company
  end
  
  def company_params
    params.require(:company).permit(
      :business_name,
      :legal_name,
      :rfc,
      :phone,
      :email,
      :address,
      :city,
      :state,
      :postal_code,
      :tax_regime,
      :cfdi_use
    )
  end
end