require 'pagy/extras/overflow'
require 'pagy/extras/items'

# Configuración por defecto
Pagy::DEFAULT[:items] = 20  # Items por página por defecto
Pagy::DEFAULT[:overflow] = :last_page  # Si se pasa de página, ir a la última

# Breakpoints para mostrar números de página
# [1, 2, 2, 1] significa: 1 al inicio, 2 cerca del actual, 2 después del actual, 1 al final
# Ejemplo: [1] ... [4] [5] [6] [7] ... [20]
Pagy::DEFAULT[:size] = [1, 2, 2, 1]

# Opcional: Permitir cambiar items por página desde la URL
# Ejemplo: ?items=50
Pagy::DEFAULT[:items_param] = :items
Pagy::DEFAULT[:max_items] = 100  # Máximo permitido