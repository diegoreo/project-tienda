class TicketSettingsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_company
  before_action :authorize_settings
  
  def edit
    # Mostrar form de configuración
  end
  
  def update
    @company.assign_attributes(ticket_params)
    @company.normalize_attributes!
    
    if @company.save
      redirect_to edit_ticket_settings_path, notice: "✅ Configuración de tickets actualizada correctamente."
    else
      flash.now[:alert] = "❌ Error al actualizar la configuración."
      render :edit, status: :unprocessable_entity
    end
  end
  
  private
  
  def set_company
    @company = Company.current
  end
  
  def authorize_settings
    authorize @company, :edit?
  end
  
  def ticket_params
    params.require(:company).permit(:ticket_printing_mode, :printing_method)
  end
end