module InventoriesHelper
  def inventory
    @inventory ||= Inventory.find_by(id: params[:inventory_id])
    unless @inventory
      redirect_to inventories_path, alert: "Inventario no encontrado."
    end
    @inventory
  end
end