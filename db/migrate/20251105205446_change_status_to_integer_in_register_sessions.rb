class ChangeStatusToIntegerInRegisterSessions < ActiveRecord::Migration[8.0]
  def up
    # Paso 1: Quitar el default temporalmente
    change_column_default :register_sessions, :status, from: 'open', to: nil
    
    # Paso 2: Cambiar el tipo a integer
    change_column :register_sessions, :status, :integer, using: 'status::integer'
    
    # Paso 3: Establecer el nuevo default como integer
    change_column_default :register_sessions, :status, from: nil, to: 0
    
    # Paso 4: Agregar restricción not null
    change_column_null :register_sessions, :status, false
  end
  
  def down
    # Revertir: quitar not null
    change_column_null :register_sessions, :status, true
    
    # Cambiar default a nil
    change_column_default :register_sessions, :status, from: 0, to: nil
    
    # Cambiar a string
    change_column :register_sessions, :status, :string
    
    # Establecer default como string
    change_column_default :register_sessions, :status, from: nil, to: 'open'
    
    # Agregar not null
    change_column_null :register_sessions, :status, false
  end
end
