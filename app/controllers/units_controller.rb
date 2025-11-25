# app/controllers/units_controller.rb
class UnitsController < ApplicationController
  def index
    # Autorizar el acceso al índice de unidades
    authorize Unit

    @units = Unit.all.order(name: :asc)
  end

  def new
    @unit = Unit.new
    authorize @unit
  end

  def create
    @unit = Unit.new(unit_params)
    authorize @unit

    if @unit.save
      redirect_to units_url, notice: "Tu unidad de medida se creó correctamente!"
    else
      render :new, status: :unprocessable_content
    end
  end

  def edit
    @unit = Unit.find(params[:id])
    authorize @unit
  end

  def update
    @unit = Unit.find(params[:id])
    authorize @unit

    if @unit.update(unit_params)
      redirect_to units_url, notice: "Tu unidad de medida se actualizó correctamente"
    else
      render :edit, status: :unprocessable_content
    end
  end

  def destroy
    @unit = Unit.find(params[:id])
    authorize @unit

    @unit.destroy
    redirect_to units_url, notice: "La unidad de medida se eliminó correctamente", status: :see_other
  end

  private

  def unit_params
    params.require(:unit).permit(:name, :abbreviation, :description)
  end
end
