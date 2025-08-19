class CategoriesController < ApplicationController
  def index
    @categories = Category.all
  end

  def new
    @category = Category.new
  end

  def create
    @category = Category.new(category_params) 
    if @category.save
      redirect_to categories_url, notice: "Tu categoria se creo correctamente!"
    else
      render :new, status: :unprocessable_content
    end
  end

  def edit
    category
  end

  def update
    if category.update(category_params)
      redirect_to categories_url, notice: "tu categoria se actualizo correctamente"
    else
      render :edit, status: :unprocessable_content
    end
  end
  def destroy
    category.destroy
    redirect_to categories_url, notice: "La categoria se elimino correctamente", status: :see_other
  end

  private

  def category
    @category = Category.find(params[:id])
  end

  def category_params
    params.require(:category).permit(
      :name, :description
    )
  end
end
