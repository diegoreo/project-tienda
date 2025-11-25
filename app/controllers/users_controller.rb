class UsersController < ApplicationController
  def index
    # Verificar autenticación
    redirect_to new_user_session_path, alert: "Debes iniciar sesión" and return unless user_signed_in?

    # Autorizar
    authorize User

    # Cargar usuarios con scope de Pundit
    @users = policy_scope(User).order(created_at: :desc)

    # Filtros opcionales
    @users = @users.where(role: params[:role]) if params[:role].present?
    @users = @users.where(active: params[:active]) if params[:active].present?
  end

  def show
    # Verificar autenticación
    redirect_to new_user_session_path, alert: "Debes iniciar sesión" and return unless user_signed_in?

    # Cargar usuario
    @user = User.find(params[:id])

    # Autorizar
    authorize @user
  end

  def new
    # Verificar autenticación
    redirect_to new_user_session_path, alert: "Debes iniciar sesión" and return unless user_signed_in?

    # Crear nuevo usuario
    @user = User.new

    # Autorizar
    authorize @user
  end

  def create
    # Verificar autenticación
    redirect_to new_user_session_path, alert: "Debes iniciar sesión" and return unless user_signed_in?

    # Crear usuario con parámetros
    @user = User.new(user_params)

    # Autorizar
    authorize @user

    # Asignar password temporal si no se proporciona
    if @user.password.blank?
      generated_password = SecureRandom.hex(8)
      @user.password = generated_password
      @user.password_confirmation = generated_password
    end

    # Guardar
    if @user.save
      redirect_to users_path, notice: "Usuario creado correctamente. Password: #{@user.password}"
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    # Verificar autenticación
    redirect_to new_user_session_path, alert: "Debes iniciar sesión" and return unless user_signed_in?

    # Cargar usuario
    @user = User.find(params[:id])

    # Autorizar
    authorize @user
  end

  def update
    # Verificar autenticación
    redirect_to new_user_session_path, alert: "Debes iniciar sesión" and return unless user_signed_in?

    # Cargar usuario
    @user = User.find(params[:id])

    # Autorizar
    authorize @user

    # Si no se proporciona password, no lo actualizamos
    user_params_filtered = user_params
    if params[:user][:password].blank?
      user_params_filtered = user_params.except(:password, :password_confirmation)
    end

    # Actualizar
    if @user.update(user_params_filtered)
      redirect_to users_path, notice: "Usuario actualizado correctamente."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    # Verificar autenticación
    redirect_to new_user_session_path, alert: "Debes iniciar sesión" and return unless user_signed_in?

    # Cargar usuario
    @user = User.find(params[:id])

    # Autorizar
    authorize @user

    # No permitir que el admin se elimine a sí mismo
    if @user == current_user
      redirect_to users_path, alert: "No puedes eliminar tu propia cuenta."
      return
    end

    # Desactivar en lugar de eliminar
    if @user.deactivate!
      redirect_to users_path, notice: "Usuario desactivado correctamente."
    else
      redirect_to users_path, alert: "No se pudo desactivar el usuario."
    end
  end

  def toggle_active
    # Verificar autenticación
    redirect_to new_user_session_path, alert: "Debes iniciar sesión" and return unless user_signed_in?

    # Cargar usuario
    @user = User.find(params[:id])

    # Autorizar con método específico
    authorize @user, :toggle_active?

    # No permitir auto-desactivación
    if @user == current_user
      redirect_to users_path, alert: "No puedes desactivar tu propia cuenta."
      return
    end

    # Activar o desactivar según el estado actual
    if @user.active?
      @user.deactivate!
      redirect_to users_path, notice: "Usuario desactivado correctamente."
    else
      @user.activate!
      redirect_to users_path, notice: "Usuario activado correctamente."
    end
  end

  private

  def user_params
    params.require(:user).permit(:name, :email, :role, :password, :password_confirmation, :active)
  end
end
