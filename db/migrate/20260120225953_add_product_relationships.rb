class AddProductRelationships < ActiveRecord::Migration[8.0]
  def change
    # Tipo de producto: base (0), master (1), presentation (2)
    add_column :products, :product_type, :integer, default: 0, null: false
    
    # Relación con producto maestro (solo para presentaciones)
    add_column :products, :master_product_id, :bigint, null: true
    
    # Factor de conversión (cuántas unidades base tiene esta presentación)
    # Ejemplo: 1 paquete = 4 rollos → conversion_factor = 4.0
    add_column :products, :conversion_factor, :decimal, 
               precision: 10, scale: 3, default: 1.0, null: false
    
    # Índices para mejorar rendimiento de búsquedas
    add_index :products, :product_type
    add_index :products, :master_product_id
    
    # Foreign key con restricción para evitar eliminar maestros con presentaciones
    add_foreign_key :products, :products, 
                    column: :master_product_id,
                    on_delete: :restrict
  end
end