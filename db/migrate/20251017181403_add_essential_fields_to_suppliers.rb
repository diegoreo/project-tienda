class AddEssentialFieldsToSuppliers < ActiveRecord::Migration[8.0]
  def change
    add_column :suppliers, :email, :string
    add_column :suppliers, :phone, :string
    add_column :suppliers, :mobile, :string
    add_column :suppliers, :rfc, :string
    add_column :suppliers, :company_name, :string
    add_column :suppliers, :address, :text
    add_column :suppliers, :city, :string
    add_column :suppliers, :state, :string
    add_column :suppliers, :zip_code, :string
    add_column :suppliers, :active, :boolean, default: true, null: false
    add_column :suppliers, :notes, :text

    # Índices para búsquedas
    add_index :suppliers, :email
    add_index :suppliers, :rfc
    add_index :suppliers, :active
  end
end
