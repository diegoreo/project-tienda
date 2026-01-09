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
  { name: 'Bebidas', description: 'Refrescos, jugos, aguas y bebidas alcohólicas' },
  { name: 'Lácteos', description: 'Leche, queso, yogurt, crema y mantequilla' },
  { name: 'Abarrotes secos', description: 'Pastas, arroz, frijol, harinas y granos' },
  { name: 'Panadería y repostería', description: 'Pan, pasteles, galletas y pan dulce' },
  { name: 'Carnes y embutidos', description: 'Carnes frescas, jamón, salchichas y chorizo' },
  { name: 'Frutas y verduras', description: 'Frutas y verduras frescas de temporada' },
  { name: 'Enlatados y conservas', description: 'Atún, chiles, vegetales y frutas en conserva' },
  { name: 'Aceites y condimentos', description: 'Aceites, vinagres, salsas, especias y sazonadores' },
  { name: 'Dulces y botanas', description: 'Chocolates, dulces, papas, chicharrones y frituras' },
  { name: 'Cereales y desayuno', description: 'Cereales, avena, granola y barras energéticas' },
  { name: 'Higiene personal', description: 'Jabones, shampoo, pasta dental y desodorantes' },
  { name: 'Cuidado del bebé', description: 'Pañales, toallitas, fórmulas y papillas' },
  { name: 'Artículos de limpieza', description: 'Detergentes, cloro, desinfectantes y limpiadores' },
  { name: 'Congelados', description: 'Helados, verduras congeladas, pizzas y comidas preparadas' },
  { name: 'Mascotas', description: 'Alimento y accesorios para perros y gatos' },
  { name: 'Papelería y desechables', description: 'Cuadernos, plumas, servilletas, platos y vasos desechables' },
  { name: 'Ferretería y hogar', description: 'Pilas, focos, herramientas básicas y artículos para el hogar' },
  { name: 'Otros', description: 'Productos sin categoría específica o misceláneos' }
]

categorias.each do |cat_data|
  unless Category.exists?(name: cat_data[:name])
    Category.create!(cat_data)
    puts "  ✅ Categoría creada: #{cat_data[:name]}"
  else
    puts "  ⏭️  Categoría ya existe: #{cat_data[:name]}"
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
# 5. UNIDADES DE MEDIDA
# ===========================================
puts "\n📏 Creando unidades de medida..."

unidades = [
  { name: 'Pieza', abbreviation: 'pz', description: 'Unidad individual de producto' },
  { name: 'Kilogramo', abbreviation: 'kg', description: 'Unidad de peso - 1000 gramos' },
  { name: 'Gramo', abbreviation: 'g', description: 'Unidad de peso pequeña' },
  { name: 'Litro', abbreviation: 'L', description: 'Medida de volumen para líquidos' },
  { name: 'Mililitro', abbreviation: 'ml', description: 'Medida de volumen pequeña - 1/1000 de litro' },
  { name: 'Caja', abbreviation: 'caj', description: 'Contenedor con múltiples piezas' },
  { name: 'Paquete', abbreviation: 'paq', description: 'Conjunto de varias piezas empaquetadas' },
  { name: 'Bolsa', abbreviation: 'bol', description: 'Envoltorio flexible con producto' },
  { name: 'Saco', abbreviation: 'sac', description: 'Contenedor grande para productos a granel' },
  { name: 'Costal', abbreviation: 'cos', description: 'Saco grande, generalmente de 50kg' },
  { name: 'Rollo', abbreviation: 'ro', description: 'Producto enrollado (papel, tela, etc.)' },
  { name: 'Bote', abbreviation: 'bt', description: 'Envase rígido para productos' },
  { name: 'Lata', abbreviation: 'lta', description: 'Envase metálico sellado' },
  { name: 'Frasco', abbreviation: 'fco', description: 'Envase de vidrio o plástico con tapa' },
  { name: 'Sobre', abbreviation: 'sob', description: 'Empaque individual pequeño' },
  { name: 'Docena', abbreviation: 'dz', description: 'Conjunto de 12 unidades' },
  { name: 'Exhibidor', abbreviation: 'exh', description: 'Exhibidor con múltiples piezas para punto de venta' },
  { name: 'A granel', abbreviation: 'grn', description: 'Producto sin empaque, pesado al momento' }
]

unidades.each do |unidad_data|
  unless Unit.exists?(name: unidad_data[:name])
    Unit.create!(unidad_data)
    puts "  ✅ Unidad creada: #{unidad_data[:name]} (#{unidad_data[:abbreviation]})"
  else
    puts "  ⏭️  Unidad ya existe: #{unidad_data[:name]}"
  end
end

# ===========================================
# 6. PROVEEDORES
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
puts "  📏 Unidades: #{Unit.count}"
puts "  🏭 Proveedores: #{Supplier.count}"
puts "\n🔐 Contraseña para todos los usuarios: Password123!"
puts "\n⚠️  IMPORTANTE: Cambia las contraseñas después del primer login"