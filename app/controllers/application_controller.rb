class ApplicationController < ActionController::Base
  include Pundit::Authorization
  
  before_action :authenticate_user!
  
  rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern
  private
  
  def user_not_authorized
    flash[:alert] = "No tienes permiso para realizar esta acción."
    redirect_to(request.referer || root_path)
  end
  # Helper para verificar permisos en las vistas
  def pundit_user
    current_user
  end
  
end
