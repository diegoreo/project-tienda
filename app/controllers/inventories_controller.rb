class InventoriesController < ApplicationController

  def index
    @inventories = Inventory.includes(:product, :warehouse).all
  end

  def show
    @inventory = Inventory.find(params[:id])
  end

end
