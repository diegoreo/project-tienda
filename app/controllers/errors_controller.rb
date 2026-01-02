class ErrorsController < ApplicationController
  skip_before_action :authenticate_user!, if: -> { defined?(Devise) }
  layout 'application'

  # 404 - Página no encontrada
  def not_found
    respond_to do |format|
      format.html { render status: :not_found }
      format.json { render json: { error: 'No encontrado' }, status: :not_found }
    end
  end

  # 422 - Entidad no procesable (validaciones fallidas)
  def unprocessable_entity
    respond_to do |format|
      format.html { render status: :unprocessable_entity }
      format.json { render json: { error: 'No se pudo procesar' }, status: :unprocessable_entity }
    end
  end

  # 500 - Error interno del servidor
  def internal_server_error
    respond_to do |format|
      format.html { render status: :internal_server_error }
      format.json { render json: { error: 'Error del servidor' }, status: :internal_server_error }
    end
  end
end