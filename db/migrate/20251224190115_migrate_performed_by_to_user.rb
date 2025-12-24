class MigratePerformedByToUser < ActiveRecord::Migration[8.0]
  def up
    # 1. Agregar nueva columna performed_by_id
    add_reference :inventory_adjustments, :performed_by, foreign_key: { to_table: :users }, index: true
    
    # 2. Migrar datos existentes (buscar user por nombre o asignar admin)
    InventoryAdjustment.reset_column_information
    
    admin_user = User.find_by(role: :admin) || User.first
    
    InventoryAdjustment.find_each do |adjustment|
      if adjustment.performed_by.present?
        # Intentar encontrar usuario por nombre
        user = User.find_by("LOWER(name) = ?", adjustment.performed_by.downcase)
        adjustment.update_column(:performed_by_id, user&.id || admin_user&.id)
      else
        adjustment.update_column(:performed_by_id, admin_user&.id)
      end
    end
    
    # 3. Hacer performed_by_id obligatorio
    change_column_null :inventory_adjustments, :performed_by_id, false
    
    # 4. Eliminar columna antigua
    remove_column :inventory_adjustments, :performed_by, :string
  end
  
  def down
    # Rollback: restaurar columna string
    add_column :inventory_adjustments, :performed_by, :string, null: false, default: "Sistema"
    
    InventoryAdjustment.reset_column_information
    
    InventoryAdjustment.find_each do |adjustment|
      if adjustment.performed_by_id.present?
        user = User.find_by(id: adjustment.performed_by_id)
        adjustment.update_column(:performed_by, user&.name || "Sistema")
      end
    end
    
    remove_reference :inventory_adjustments, :performed_by, foreign_key: { to_table: :users }
  end
end