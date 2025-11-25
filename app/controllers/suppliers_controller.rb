class SuppliersController < ApplicationController
  def index
    # Autorizar el acceso al índice de proveedores
    authorize Supplier

    @suppliers = Supplier.all

    # Filtro por estado
    @suppliers = case params[:status]
    when "inactive"
                   @suppliers.inactive
    when "all"
                   @suppliers
    else
                   @suppliers.active # Por defecto mostrar solo activos
    end

    # Búsqueda
    if params[:query].present?
      query = "%#{params[:query]}%"
      @suppliers = @suppliers.where(
        "name ILIKE ? OR company_name ILIKE ? OR rfc ILIKE ? OR email ILIKE ? OR city ILIKE ?",
        query, query, query, query, query
      )
    end

    @suppliers = @suppliers.order(name: :asc)
  end

  def show
    @supplier = Supplier.find(params[:id])
    authorize @supplier
  end

  def new
    @supplier = Supplier.new
    authorize @supplier
  end

  def create
    @supplier = Supplier.new(supplier_params)
    authorize @supplier

    normalize_supplier_data(@supplier)

    if @supplier.save
      redirect_to supplier_path(@supplier), notice: "Proveedor creado correctamente"
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @supplier = Supplier.find(params[:id])
    authorize @supplier
  end

  def update
    @supplier = Supplier.find(params[:id])
    authorize @supplier

    @supplier.assign_attributes(supplier_params)
    normalize_supplier_data(@supplier)

    if @supplier.save
      redirect_to supplier_path(@supplier), notice: "Proveedor actualizado correctamente"
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @supplier = Supplier.find(params[:id])
    authorize @supplier

    if @supplier.destroy
      redirect_to suppliers_url, notice: "Proveedor eliminado correctamente", status: :see_other
    else
      redirect_to suppliers_url,
                  alert: "No se pudo eliminar el proveedor: #{@supplier.errors.full_messages.join(', ')}",
                  status: :see_other
    end
  end

  private

  def supplier_params
    params.require(:supplier).permit(
      :name,
      :contact_info,
      :email,
      :phone,
      :mobile,
      :rfc,
      :company_name,
      :address,
      :city,
      :state,
      :zip_code,
      :active,
      :notes
    )
  end

  def normalize_supplier_data(supplier)
    supplier.email = supplier.email.strip.downcase if supplier.email.present?
    supplier.rfc = supplier.rfc.strip.upcase if supplier.rfc.present?
    supplier.name = supplier.name.strip if supplier.name.present?
    supplier.company_name = supplier.company_name.strip if supplier.company_name.present?
  end
end
