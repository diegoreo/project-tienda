class UnitsController < ApplicationController
  def index
    @units = Unit.all.order(name: :asc)
  end

  def new
    @unit = Unit.new
  end

  def create
    @unit = Unit.new(unit_params) 
    if @unit.save
      redirect_to units_url, notice: "Tu unidad de medida se creo correctamente!"
    else
      render :new, status: :unprocessable_content
    end
  end

  def edit
    unit
  end

  def update
    if unit.update(unit_params)
      redirect_to units_url, notice: "tu unidad de medida se actualizo correctamente"
    else
      render :edit, status: :unprocessable_content
    end
  end

  def destroy
    unit.destroy
    redirect_to units_url, notice: "La unidad de medida se elimino correctamente", status: :see_other
  end

  private

  def unit
    @unit = Unit.find(params[:id])
  end

  def unit_params
    params.require(:unit).permit(
      :name, :abbreviation, :description
    )
  end
end
