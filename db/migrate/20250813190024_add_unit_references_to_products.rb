class AddUnitReferencesToProducts < ActiveRecord::Migration[8.0]
  def change
    add_reference :products, :purchase_unit, null: false, foreign_key: { to_table: :units }
    add_reference :products, :sale_unit, null: false, foreign_key: { to_table: :units }
  end
end
