# 🛒 Sistema POS - Tienda de Abarrotes

Sistema integral de Punto de Venta desarrollado en Ruby on Rails para la gestión completa de tiendas de abarrotes.

## ✨ Características Principales

### 👥 Gestión de Usuarios y Autorización
- Sistema multi-rol con **6 niveles de permisos** (Cajero, Supervisor, Almacenista, Contador, Gerente, Admin)
- Autorización granular con **Pundit**
- Control de acceso por módulo y acción

### 💰 Punto de Venta
- Interfaz intuitiva para registro de ventas
- Búsqueda de productos con **código de barras**
- **Búsqueda full-text** con PostgreSQL (pg_search)
- Gestión de sesiones de caja
- Múltiples métodos de pago

### 💳 Gestión de Pagos y Crédito
- Sistema de **crédito a clientes**
- Lógica **FIFO** para aplicación automática de pagos
- Distribución inteligente de abonos en ventas pendientes
- Historial completo de transacciones

### 📦 Inventario y Almacén
- Control de múltiples almacenes
- Gestión de entradas y salidas
- Ajustes automáticos de inventario
- Alertas de stock bajo
- Conversión de unidades (compra/venta)

### 🏢 Gestión Empresarial
- **Proveedores:** Registro y seguimiento de compras
- **Clientes:** Perfiles con historial de compras y crédito
- **Productos:** Catálogo completo con categorías y unidades
- **Compras:** Órdenes de compra y recepción de mercancía

### 📊 Validaciones de Negocio
- Validaciones exhaustivas en todos los módulos
- Prevención de inconsistencias de datos
- Reglas de negocio aplicadas a nivel de modelo
- Integridad referencial garantizada

## 🛠️ Stack Tecnológico

- **Backend:** Ruby on Rails 8.0.2
- **Base de Datos:** PostgreSQL
- **Autorización:** Pundit
- **Frontend:** Tailwind CSS
- **Búsqueda:** pg_search (PostgreSQL Full-Text Search)
- **Testing:** Minitest (Integration Tests)

## 🧪 Testing

El proyecto cuenta con suite de tests de integración usando **Minitest**:

- Tests CRUD completos para todos los módulos
- Validación de permisos y autorización
- Tests de flujos de negocio complejos
- Cobertura de casos edge y validaciones
```ruby
# Ejemplo de tests implementados
- ProductsControllerTest
- CategoriesControllerTest
- SalesControllerTest
- InventoriesControllerTest
```

## 📁 Módulos Principales
```
├── Productos y Categorías
├── Proveedores
├── Clientes
├── Compras
├── Ventas
├── Inventarios
├── Usuarios y Roles
├── Caja (Sesiones)
├── Flujos de Efectivo
└── Pagos y Crédito
```

## 🚀 Características Técnicas

- **Arquitectura MVC** siguiendo convenciones Rails
- **Código explícito** sobre "Rails magic"
- **Autorización explícita** en cada acción
- **Validaciones robustas** en modelos
- **Relaciones ActiveRecord** bien definidas
- **Queries optimizadas** con PostgreSQL
- **Responsive design** con Tailwind CSS

## 👨‍💻 Desarrollado por

**Diego Reyes Olivares**
- GitHub: [@diegoreo](https://github.com/diegoreo)
- LinkedIn: [diego-reyes-olivares](https://www.linkedin.com/in/diego-reyes-olivares-899335199)

---

**Estado:** 🚧 En desarrollo activo - Próximamente en producción

**Licencia:** Proyecto privado para uso comercial
