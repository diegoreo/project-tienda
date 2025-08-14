class CreateUnits < ActiveRecord::Migration[8.0]
  def change
    create_table :units do |t|
      t.string :name, null: false
      t.string :abbreviation
      t.string :description

      t.timestamps
    end
  end
end
