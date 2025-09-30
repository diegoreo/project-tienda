class AddProcessedAtToPurchases < ActiveRecord::Migration[8.0]
  def change
    add_column :purchases, :processed_at, :datetime
    add_index :purchases, :processed_at
  end
end
