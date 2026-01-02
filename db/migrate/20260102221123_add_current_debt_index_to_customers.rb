class AddCurrentDebtIndexToCustomers < ActiveRecord::Migration[8.0]
  def change
    # Índice parcial: solo indexa clientes con deuda > 0
    # Esto hace el índice más pequeño y rápido
    add_index :customers, :current_debt, 
      where: "current_debt > 0",
      name: "index_customers_on_current_debt_positive"
  end
end
