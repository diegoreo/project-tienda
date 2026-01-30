class CreateCompanies < ActiveRecord::Migration[8.0]
  def change
    create_table :companies do |t|
      # Información básica
      t.string :business_name, null: false, default: '', limit: 100
      t.string :legal_name, limit: 150
      t.string :rfc, limit: 13
      t.string :phone, limit: 20
      t.string :email, limit: 100
      t.text :address
      t.string :city, limit: 100
      t.string :state, limit: 50
      t.string :postal_code, limit: 10
      
      # Facturación (futuro)
      t.string :tax_regime, limit: 50
      t.string :cfdi_use, limit: 10
      
      # Multi-tenant (futuro)
      t.string :subdomain, limit: 50
      t.boolean :active, default: true, null: false
      t.string :plan, default: 'free', null: false, limit: 20
      
      t.timestamps
    end
    
    # Índices para performance y unicidad
    add_index :companies, :subdomain, unique: true, where: "subdomain IS NOT NULL"
    add_index :companies, :rfc, unique: true, where: "rfc IS NOT NULL AND rfc != ''"
    add_index :companies, :email, where: "email IS NOT NULL"
    add_index :companies, :active
  end
end