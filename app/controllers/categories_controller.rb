class CategoriesController < ApplicationController
  def index
    # Autorizar el acceso al índice de categorías
    authorize Category
    
    @categories = Category.all.order(name: :asc)
  end

  def new
    @category = Category.new
    authorize @category
  end

  def create
    @category = Category.new(category_params)
    authorize @category
    
    if @category.save
      redirect_to categories_url, notice: "Tu categoría se creó correctamente!"
    else
      render :new, status: :unprocessable_content
    end
  end

  def edit
    @category = Category.find(params[:id])
    authorize @category
  end

  def update
    @category = Category.find(params[:id])
    authorize @category
    
    if @category.update(category_params)
      redirect_to categories_url, notice: "Tu categoría se actualizó correctamente"
    else
      render :edit, status: :unprocessable_content
    end
  end
  
  def destroy
    @category = Category.find(params[:id])
    authorize @category
    
    @category.destroy
    redirect_to categories_url, notice: "La categoría se eliminó correctamente", status: :see_other
  end

  private

  def category_params
    params.require(:category).permit(:name, :description)
  end
end