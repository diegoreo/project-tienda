class CreateBarcodes < ActiveRecord::Migration[8.0]
  def change
    create_table :barcodes do |t|
      t.string :code
      t.references :product, null: false, foreign_key: true

      t.timestamps
    end
  end
end
