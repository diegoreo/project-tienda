class AddAmountReceivedAndChangeToSales < ActiveRecord::Migration[8.0]
  def change
    add_column :sales, :amount_received, :decimal, precision: 10, scale: 2
    add_column :sales, :change_given, :decimal, precision: 10, scale: 2
  end
end
