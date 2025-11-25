class BackfillInventoriesFromProductsStock < ActiveRecord::Migration[8.0]
  def up
    # Usamos el primer warehouse o creamos uno por defecto
    wh_id = execute("SELECT id FROM warehouses LIMIT 1").values.dig(0, 0)
    unless wh_id
      execute("INSERT INTO warehouses (name, location, created_at, updated_at) VALUES ('General', NULL, NOW(), NOW())")
      wh_id = execute("SELECT id FROM warehouses WHERE name = 'General' LIMIT 1").values.dig(0, 0)
    end

    # Crea un inventory por producto con stock en unidad de venta
    # Comentarios explicativos afuera del SQL
    # stock = stock_quantity * unit_conversion
    # minimum_quantity = 10% del stock o 1
    execute <<-SQL.squish
      INSERT INTO inventories (product_id, warehouse_id, quantity, minimum_quantity, created_at, updated_at)
      SELECT#{' '}
        id,
        #{wh_id},
        COALESCE(stock_quantity * COALESCE(unit_conversion,1), 0),
        GREATEST(1, COALESCE(stock_quantity * COALESCE(unit_conversion,1) * 0.1, 0)),
        NOW(),
        NOW()
      FROM products
      ON CONFLICT (product_id, warehouse_id) DO NOTHING
    SQL
  end

  def down
    # Opcional: borrar inventories del warehouse 'General'
    # execute("DELETE FROM inventories WHERE warehouse_id = (SELECT id FROM warehouses WHERE name = 'General')")
  end
end
