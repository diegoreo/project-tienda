# db/seeds.rb
puts "🌱 Iniciando seed de datos..."

# ===========================================
# 1. USUARIOS
# ===========================================
puts "\n👥 Creando usuarios..."

usuarios = [
  { email: 'supervisor@tienda.com', name: 'Sofia Supervisor', role: 'supervisor' },
  { email: 'almacenista@tienda.com', name: 'Luis Almacenista', role: 'almacenista' },
  { email: 'contador@tienda.com', name: 'Ana Contador', role: 'contador' },
  { email: 'gerente@tienda.com', name: 'Miguel Gerente', role: 'gerente' },
  { email: 'cajero@tienda.com', name: 'Carlos Cajero', role: 'cajero' },
  { email: 'admin@tienda.com', name: 'Diego Admin', role: 'admin' }
]

usuarios.each do |user_data|
  unless User.exists?(email: user_data[:email])
    User.create!(
      email: user_data[:email],
      name: user_data[:name],
      role: user_data[:role],
      password: 'Password123!',
      password_confirmation: 'Password123!'
    )
    puts "  ✅ Usuario creado: #{user_data[:email]} (#{user_data[:role]})"
  else
    puts "  ⏭️  Usuario ya existe: #{user_data[:email]}"
  end
end

# ===========================================
# 2. CATEGORÍAS
# ===========================================
puts "\n📦 Creando categorías..."

categorias = [
  'Bebidas',
  'Lácteos',
  'Abarrotes secos',
  'Panadería y repostería',
  'Carnes y embutidos',
  'Frutas y verduras',
  'Enlatados y conservas',
  'Aceites y condimentos',
  'Dulces y botanas',
  'Cereales y desayuno',
  'Higiene personal',
  'Cuidado del bebé',
  'Artículos de limpieza',
  'Congelados',
  'Mascotas',
  'Papelería y desechables',
  'Ferretería y hogar',
  'Otros'
]

categorias.each do |nombre|
  unless Category.exists?(name: nombre)
    Category.create!(name: nombre)
    puts "  ✅ Categoría creada: #{nombre}"
  else
    puts "  ⏭️  Categoría ya existe: #{nombre}"
  end
end

# ===========================================
# 3. CLIENTE POR DEFECTO
# ===========================================
puts "\n👤 Creando cliente por defecto..."

unless Customer.exists?(name: 'Público General')
  Customer.create!(
    name: 'Público General',
    email: '',
    phone: ''
  )
  puts "  ✅ Cliente 'Público General' creado"
else
  puts "  ⏭️  Cliente 'Público General' ya existe"
end

# ===========================================
# 4. ALMACÉN POR DEFECTO
# ===========================================
puts "\n🏪 Creando almacén por defecto..."

unless Warehouse.exists?(name: 'Almacén Principal')
  Warehouse.create!(
    name: 'Almacén Principal',
    location: 'Ubicación principal'
  )
  puts "  ✅ Almacén 'Almacén Principal' creado"
else
  puts "  ⏭️  Almacén 'Almacén Principal' ya existe"
end

# ===========================================
# 5. PROVEEDORES
# ===========================================
puts "\n🏭 Creando proveedores..."

proveedores = [
  'Coca-Cola FEMSA',
  'Grupo Bimbo',
  'Grupo Lala',
  'Sabritas/PepsiCo',
  'Nestlé México',
  'Grupo Modelo',
  'Herdez',
  'Jumex',
  'Sigma Alimentos',
  'Barcel',
  'Grupo Maseca',
  'Alpura',
  'Distribuidora Comercial Mexicana',
  'Abarrotes y Distribuidora del Centro',
  'Proveedores Locales Zacualtipan'
]

proveedores.each do |nombre|
  unless Supplier.exists?(name: nombre)
    Supplier.create!(name: nombre)
    puts "  ✅ Proveedor creado: #{nombre}"
  else
    puts "  ⏭️  Proveedor ya existe: #{nombre}"
  end
end

puts "\n🎉 Seed completado exitosamente!"
puts "\n📋 Resumen:"
puts "  👥 Usuarios: #{User.count}"
puts "  📦 Categorías: #{Category.count}"
puts "  👤 Clientes: #{Customer.count}"
puts "  🏪 Almacenes: #{Warehouse.count}"
puts "  🏭 Proveedores: #{Supplier.count}"
puts "\n🔐 Contraseña para todos los usuarios: Password123!"
puts "\n⚠️  IMPORTANTE: Cambia las contraseñas después del primer login"
