class RemoveBarcodeFromProducts < ActiveRecord::Migration[8.0]
  def change
    remove_column :products, :barcode, :string
  end
end
