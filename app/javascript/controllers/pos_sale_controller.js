import { Controller } from "@hotwired/stimulus"
import Swal from "sweetalert2"

export default class extends Controller {
  static targets = [
    "searchInput",
    "searchResults", 
    "itemsContainer",
    "emptyCart",
    "totalAmount",
    "warehouseSelect",
    "notesContainer",
    "submitButton",
    "paymentSection",      
    "receivedAmount",      
    "changeAmount",
    "pendingCount",        // Badge de contador
    "pendingList",         // Dropdown de tickets
    "customerSelect",       // Select de cliente   
    "itemsCount",          // Resumen: número de items
    "unitsCount",          // Resumen: total de unidades
    "discountTotal"        // Resumen: total de descuentos      
  ]

  connect() {
    console.log("POS Sale controller connected")
    this.searchTimeout = null
    this.selectedIndex = -1
    this.searchResultsData = []
    this.itemIndex = 0

    // 🔧 FIX: Flag para prevenir múltiples agregados simultáneos
    this.isProcessingBarcode = false  
    
    // Cargar almacén guardado
    this.loadWarehousePreference()
    // Verificar método de pago inicial y mostrar campo si es efectivo
    this.checkInitialPaymentMethod()
    
    // Enfocar buscador al cargar (con pequeño delay para que cargue el DOM)
    setTimeout(() => {
      this.focusSearch()
    }, 100)

    this.updatePendingUI()
    
    // Atajos de teclado globales
    document.addEventListener('keydown', this.handleGlobalKeydown.bind(this))
  
    // Verificar si viene de venta exitosa
    this.checkSuccessfulSale()
  }


  // Verificar si viene de una venta exitosa
  async checkSuccessfulSale() {
    const urlParams = new URLSearchParams(window.location.search)
    const isSuccess = urlParams.get('success')
    const saleId = urlParams.get('sale_id')
    
    if (isSuccess === 'true' && saleId) {
      // Obtener configuración de impresión
      const printingMode = this.getPrintingMode()
      const printingMethod = this.getPrintingMethod()
      
      console.log('🎯 Printing Mode:', printingMode)
      console.log('🖨️ Printing Method:', printingMethod)
      
      if (printingMode === 'always') {
        // Imprimir automáticamente
        await this.executePrint(saleId, printingMethod)
      } else if (printingMode === 'ask') {
        // Preguntar al usuario
        this.showPrintModal(saleId, printingMethod)
      }
      // Si es 'manual', no hace nada
    }
  }

  // Obtener modo de impresión desde el HTML
  getPrintingMode() {
    return this.element.dataset.printingMode || 'ask'
  }

  // Obtener método de impresión desde localStorage (por PC)
  getPrintingMethod() {
    const saved = localStorage.getItem('printing_method')
    return saved || 'webusb' // Default: webusb
  }

  // Mostrar modal preguntando si quiere imprimir
  showPrintModal(saleId, printingMethod) {
    Swal.fire({
      title: '¿Imprimir ticket?',
      icon: 'question',
      showCancelButton: true,
      confirmButtonText: '🖨️ Sí, imprimir',
      cancelButtonText: 'No imprimir',
      confirmButtonColor: '#10b981',
      cancelButtonColor: '#6b7280',
      customClass: {
        popup: 'rounded-lg shadow-2xl',
        confirmButton: 'px-6 py-3 rounded-lg font-semibold',
        cancelButton: 'px-6 py-3 rounded-lg font-semibold'
      }
    }).then(async (result) => {
      if (result.isConfirmed) {
        await this.executePrint(saleId, printingMethod)
      }
    })
  }

  // Ejecutar impresión según el método configurado
  async executePrint(saleId, printingMethod) {
    if (printingMethod === 'webusb') {
      await this.printTicketWebUSB(saleId)
    } else {
      this.printTicketPDF(saleId)
    }
  }

  // Imprimir con WebUSB
  async printTicketWebUSB(saleId) {
    try {
      // Verificar soporte WebUSB
      if (!navigator.usb) {
        throw new Error('Tu navegador no soporta WebUSB. Cambia a método PDF en configuración.')
      }

      // Usar el controller de thermal_printer
      const thermalPrinterController = this.application.getControllerForElementAndIdentifier(
        document.body,
        'thermal-printer'
      )

      if (!thermalPrinterController) {
        // Si no existe el controller, lo creamos dinámicamente
        const thermalPrinter = await this.createThermalPrinterController()
        await thermalPrinter.printTicket(saleId)
      } else {
        await thermalPrinterController.printTicket(saleId)
      }

    } catch (error) {
      console.error('Error imprimiendo con WebUSB:', error)
      
      Swal.fire({
        icon: 'error',
        title: 'Error al imprimir',
        html: `
          <p class="mb-3">${error.message}</p>
          <p class="text-sm text-gray-600">
            Puedes cambiar a método PDF en Config > Tickets
          </p>
        `,
        confirmButtonColor: '#ef4444'
      })
    }
  }

  // Imprimir con PDF (método actual)
  printTicketPDF(saleId) {
    const iframe = document.createElement('iframe')
    iframe.style.position = 'fixed'
    iframe.style.right = '0'
    iframe.style.bottom = '0'
    iframe.style.width = '0'
    iframe.style.height = '0'
    iframe.style.border = 'none'
    iframe.src = `/sales/${saleId}/print_ticket`
    
    document.body.appendChild(iframe)
    
    iframe.onload = () => {
      try {
        setTimeout(() => {
          iframe.contentWindow.print()
        }, 500)
      } catch(e) {
        console.error('Error al imprimir:', e)
        Swal.fire({
          icon: 'error',
          title: 'Error al imprimir',
          text: 'No se pudo enviar el ticket a la impresora',
          confirmButtonColor: '#ef4444'
        })
      }
      
      setTimeout(() => {
        document.body.removeChild(iframe)
      }, 2000)
    }
  }

  // Crear controller de thermal printer dinámicamente
  async createThermalPrinterController() {
    const { default: ThermalPrinterController } = await import('./thermal_printer_controller')
    return new ThermalPrinterController()
  }

  disconnect() {
    document.removeEventListener('keydown', this.handleGlobalKeydown.bind(this))
  }

  focusSearch() {
    this.searchInputTarget.focus()
  }

  // Agregar este nuevo método
  checkInitialPaymentMethod() {
    const paymentSelect = this.element.querySelector('select[name="sale[payment_method]"]')
    if (paymentSelect && paymentSelect.value === 'cash' && this.hasPaymentSectionTarget) {
      this.paymentSectionTarget.style.display = 'block'
    }
  }

  loadWarehousePreference() {
    const savedWarehouse = localStorage.getItem('pos_warehouse_id')
    if (savedWarehouse && this.hasWarehouseSelectTarget) {
      const warehouseSelect = this.warehouseSelectTarget
      // Verificar que el almacén existe en las opciones
      const optionExists = Array.from(warehouseSelect.options).some(
        option => option.value === savedWarehouse
      )
      
      if (optionExists) {
        warehouseSelect.value = savedWarehouse
      }
    }
  }

  saveWarehousePreference(event) {
    localStorage.setItem('pos_warehouse_id', event.target.value)
  }

  handleGlobalKeydown(event) {
    // F1 - Enfocar buscador
    if (event.key === 'F1') {
      event.preventDefault()
      this.focusSearch()
    }
    
    // F2 - Cambiar método de pago
    if (event.key === 'F2') {
      event.preventDefault()
      const paymentSelect = this.element.querySelector('select[name="sale[payment_method]"]')
      if (paymentSelect) {
        const currentIndex = paymentSelect.selectedIndex
        const nextIndex = (currentIndex + 1) % paymentSelect.options.length
        paymentSelect.selectedIndex = nextIndex
        paymentSelect.dispatchEvent(new Event('change', { bubbles: true }))
      }
    }
    
    // F3 - Enfocar campo de recibido (si es efectivo)
    if (event.key === 'F3') {
      event.preventDefault()
      if (this.hasReceivedAmountTarget && this.paymentSectionTarget.style.display !== 'none') {
        this.receivedAmountTarget.focus()
      }
    }
    
    // Enter - Enviar formulario (solo si no estás en un input)
    if (event.key === 'Enter' && !this.searchResultsTarget.classList.contains('active')) {
      const items = this.itemsContainerTarget.querySelectorAll('.sale-item-row')
      if (items.length > 0 && event.target.tagName !== 'INPUT') {
        event.preventDefault()
        this.submitButtonTarget.click()
      }
    }
    
    // Escape - Limpiar búsqueda o venta
    if (event.key === 'Escape') {
      event.preventDefault()      // ← FIX 1: Prevenir default
      event.stopPropagation()     // ← FIX 2: Detener propagación
      
      if (this.searchResultsTarget.classList.contains('active')) {
        // Si hay resultados de búsqueda abiertos, cerrarlos
        this.closeSearchResults()
        this.searchInputTarget.value = ''
        this.focusSearch()
      } else {
        // Si no hay búsqueda activa, preguntar si limpiar venta
        const items = this.itemsContainerTarget.querySelectorAll('.sale-item-row')
        const hasItems = Array.from(items).some(row => row.style.display !== 'none')
        
        if (!hasItems) {
          // No hay productos, no hacer nada
          return
        }
        
        // ← FIX 3: SweetAlert2 en vez de confirm()
        Swal.fire({
          title: '🗑️ ¿Limpiar toda la venta?',
          html: `
            <div class="text-center space-y-3">
              <p class="text-gray-700">Se perderán todos los productos agregados</p>
              <div class="bg-red-50 border-2 border-red-200 rounded-lg p-4">
                <p class="text-red-800 font-bold text-lg">
                  ${items.length} producto${items.length !== 1 ? 's' : ''} en el carrito
                </p>
              </div>
              <p class="text-sm text-gray-500">Presiona ESC para cancelar</p>
            </div>
          `,
          icon: 'warning',
          showCancelButton: true,
          confirmButtonText: '✓ Sí, limpiar todo',
          cancelButtonText: '✗ No, cancelar',
          confirmButtonColor: '#dc2626',
          cancelButtonColor: '#6b7280',
          focusCancel: true,
          customClass: {
            popup: 'rounded-xl shadow-2xl',
            title: 'text-2xl font-bold',
            confirmButton: 'px-6 py-3 rounded-lg font-bold shadow-lg',
            cancelButton: 'px-6 py-3 rounded-lg font-semibold'
          }
        }).then((result) => {
          if (result.isConfirmed) {
            this.clearSale()
            
            Swal.fire({
              icon: 'success',
              title: '✅ Venta limpiada',
              text: 'Todos los productos fueron eliminados',
              timer: 1500,
              showConfirmButton: false,
              customClass: {
                popup: 'rounded-xl shadow-2xl'
              }
            })
          }
        })
      }
    }
  }

  // Validar antes de enviar el formulario
  validateSubmit(event) {
    const paymentSelect = this.element.querySelector('select[name="sale[payment_method]"]')
    const paymentMethod = paymentSelect ? paymentSelect.value : null
    
    // Solo validar si es pago en efectivo
    if (paymentMethod === 'cash') {
      const total = this.getCurrentTotal()
      
      // Si no hay campo de recibido visible, es porque no se configuró bien
      if (!this.hasReceivedAmountTarget || this.paymentSectionTarget.style.display === 'none') {
        event.preventDefault()
        alert('⚠️ Debes ingresar el monto recibido en efectivo')
        return false
      }
      
      const received = parseFloat(this.receivedAmountTarget.value) || 0
      
      // Validar que el monto recibido sea mayor o igual al total
      if (received < total) {
        event.preventDefault()
        const missing = total - received
        
        Swal.fire({
          icon: 'warning',
          title: '⚠️ Efectivo insuficiente',
          html: `
            <div class="text-left space-y-3">
              <p class="text-base"><strong>Total de la venta:</strong> <span class="text-green-600 font-bold text-lg">$${total.toFixed(2)}</span></p>
              <p class="text-base"><strong>Efectivo recibido:</strong> <span class="text-blue-600 font-bold text-lg">$${received.toFixed(2)}</span></p>
              
              <div class="text-center py-4 bg-red-50 rounded-lg border-2 border-red-200 my-4">
                <p class="text-red-800 font-bold text-xl mb-1">Falta:</p>
                <p class="text-red-600 font-bold text-3xl">$${missing.toFixed(2)}</p>
              </div>
              
              <hr class="my-3 border-gray-300">
              <p class="text-gray-700 text-sm">Por favor, solicita el monto completo al cliente.</p>
            </div>
          `,
          confirmButtonText: 'Entendido',
          confirmButtonColor: '#16a34a',
          customClass: {
            popup: 'rounded-lg shadow-2xl',
            confirmButton: 'px-6 py-3 rounded-lg font-semibold'
          }
        }).then(() => {
          // Enfocar el campo de recibido después de cerrar el modal
          this.receivedAmountTarget.focus()
          this.receivedAmountTarget.select()
        })
        
        return false
      }
      
      // ✅ NUEVO: Agregar campos hidden para enviar al servidor
      this.addHiddenFields(received, total)
    } else {
      // Si NO es efectivo, asegurarse de NO enviar amount_received
      this.removeHiddenFields()
    }
    
    // Si pasa todas las validaciones, permitir el submit
    return true
  }

  searchProducts(event) {
    clearTimeout(this.searchTimeout)
    const query = event.target.value.replace(/\s+/g, '')
    
    if (query.length === 0) {
      this.closeSearchResults()
      return
    }
    
    // 🔧 Detectar si es código de barras (2+ dígitos consecutivos)
    const isBarcodePattern = /^\d{2,}$/.test(query)
    
    if (isBarcodePattern) {
      // 🚀 ES CÓDIGO DE BARRAS - NO BUSCAR hasta Enter
      // El lector escribe tan rápido que dispararía múltiples búsquedas
      console.log(`📦 Código detectado: ${query} - Esperando Enter...`)
      this.closeSearchResults()  // Cerrar resultados para evitar confusión
      return  // NO buscar hasta que presione Enter
    } else {
      // 📝 ES TEXTO - Esperar 400ms (escritura manual)
      this.searchTimeout = setTimeout(() => {
        this.performSearch(query)
      }, 400)
    }
  }



  async performSearch(query) {
    const warehouseId = this.warehouseSelectTarget.value
    
    if (!warehouseId) {
      alert('Selecciona un almacén primero')
      return
    }
    
    try {
      const response = await fetch(`/products/search?q=${encodeURIComponent(query)}&warehouse_id=${warehouseId}`)
      const products = await response.json()
      
      if (products.length > 0) {
        // SIEMPRE mostrar resultados, nunca agregar automáticamente
        this.showSearchResults(products)
      } else {
        this.showNoResults()
      }
    } catch (error) {
      console.error('Error en búsqueda:', error)
    }
  }

  showSearchResults(products) {
    this.searchResultsData = products
    this.selectedIndex = -1
    
    const html = products.map((product, index) => {
      let stockClass = 'out-of-stock'
      let stockText = 'Sin stock'
      
      if (product.stock > 10) {
        stockClass = 'in-stock'
        stockText = `Stock: ${product.stock}`
      } else if (product.stock > 0) {
        stockClass = 'low-stock'
        stockText = `Stock bajo: ${product.stock}`
      }
      
      return `
        <div class="search-result-item" data-index="${index}" data-action="click->pos-sale#selectProduct">
          <div class="product-name">${product.name}</div>
          <div class="product-details">
            <span class="product-price">$${product.price.toFixed(2)}</span>
            <span class="product-stock ${stockClass}">
              ${stockText} ${product.unit || ''}
            </span>
          </div>
        </div>
      `
    }).join('')
    
    this.searchResultsTarget.innerHTML = html
    this.searchResultsTarget.classList.add('active')
  }
  

  showNoResults() {
    this.searchResultsTarget.innerHTML = '<div class="search-result-item">No se encontraron productos</div>'
    this.searchResultsTarget.classList.add('active')
  }

  closeSearchResults() {
    this.searchResultsTarget.classList.remove('active')
    this.searchResultsTarget.innerHTML = ''
    this.selectedIndex = -1
  }

  async handleSearchKeydown(event) {
    // Si presiona Enter en el campo de búsqueda
    if (event.key === 'Enter') {
      event.preventDefault()
      
      // 🔧 PREVENIR múltiples Enters rápidos
      if (this.isProcessingBarcode) {
        console.log('⏸️ Ya procesando código, ignorando Enter...')
        return
      }
      
      const query = this.searchInputTarget.value.replace(/\s+/g, '')
      
      if (query.length === 0) {
        return
      }
      
      // 🔧 NUEVO: Detectar si es código de barras
      const isBarcodePattern = /^\d{2,}$/.test(query)
      
      if (isBarcodePattern) {
        console.log(`📦 Procesando código de barras: ${query}`)
        this.isProcessingBarcode = true
        
        // 🔧 Buscar AHORA con el código completo (una sola vez)
        await this.performSearch(query)
        
        // Esperar 150ms para asegurar que la respuesta llegó
        await new Promise(resolve => setTimeout(resolve, 150))
        
        // Buscar coincidencia EXACTA de código de barras
        const exactMatch = this.searchResultsData.find(product => {
          // Buscar en el array de códigos de barras
          if (product.barcodes && Array.isArray(product.barcodes)) {
            return product.barcodes.some(barcode => barcode === query)
          }
          return false
        })
        
        if (exactMatch) {
          console.log(`✅ Código ${query} coincide con: ${exactMatch.name}`)
          this.addProductToSale(exactMatch)
          this.searchInputTarget.value = ''
          this.closeSearchResults()
        } else {
          console.log(`❌ Código ${query} no encontrado en productos`)
          console.log(`📊 Datos recibidos del servidor:`, this.searchResultsData)
          
          // Si solo hay un resultado, agregarlo de todas formas
          if (this.searchResultsData.length === 1) {
            console.log(`⚠️ Solo hay 1 resultado, agregándolo...`)
            this.addProductToSale(this.searchResultsData[0])
            this.searchInputTarget.value = ''
            this.closeSearchResults()
          }
        }
        
        // Liberar el flag después de 100ms
        setTimeout(() => {
          this.isProcessingBarcode = false
        }, 100)
        
        this.focusSearch()
        return
      }
      
      // 📝 ENTRADA MANUAL (no es código de barras)
      if (query.length > 0) {
        // Si hay resultados visibles y uno seleccionado
        if (this.searchResultsTarget.classList.contains('active') && this.selectedIndex >= 0) {
          this.addProductToSale(this.searchResultsData[this.selectedIndex])
        } 
        // Si solo hay un resultado, agregarlo
        else if (this.searchResultsData.length === 1) {
          this.addProductToSale(this.searchResultsData[0])
        }
        // Si hay múltiples resultados pero ninguno seleccionado, seleccionar el primero
        else if (this.searchResultsData.length > 1) {
          this.selectedIndex = 0
          const items = this.searchResultsTarget.querySelectorAll('.search-result-item')
          this.highlightSelected(items)
          return // No agregar todavía
        }
        
        this.searchInputTarget.value = ''
        this.closeSearchResults()
        this.focusSearch()
      }
      return
    }
    
    // Navegación con flechas (código existente)
    if (!this.searchResultsTarget.classList.contains('active')) return
  
    const items = this.searchResultsTarget.querySelectorAll('.search-result-item')
  
    if (event.key === 'ArrowDown') {
      event.preventDefault()
      this.selectedIndex = Math.min(this.selectedIndex + 1, items.length - 1)
      this.highlightSelected(items)
    } else if (event.key === 'ArrowUp') {
      event.preventDefault()
      this.selectedIndex = Math.max(this.selectedIndex - 1, 0)
      this.highlightSelected(items)
    }
  }

  highlightSelected(items) {
    items.forEach((item, index) => {
      item.classList.toggle('selected', index === this.selectedIndex)
    })
  }

  selectProduct(event) {
    const index = parseInt(event.currentTarget.dataset.index)
    const product = this.searchResultsData[index]
    this.addProductToSale(product)
    this.searchInputTarget.value = '' // Esta línea ya está pero asegúrate que exista
    this.closeSearchResults()
    this.focusSearch() // Agregar esta línea para reenfocar
  }

  addProductToSale(product) {
    // Verificar si el producto ya está en la venta
    const existingRow = this.findProductRow(product.id)
    
    if (existingRow) {
      // Incrementar cantidad
      const qtyInput = existingRow.querySelector('input[name*="[quantity]"]')
      qtyInput.value = parseFloat(qtyInput.value) + 1
      qtyInput.dispatchEvent(new Event('input', { bubbles: true }))
    } else {
      // Agregar nuevo item
      this.createNewItemRow(product)
    }
    
    this.updateEmptyCartVisibility()
    // Feedback visual/sonoro
    this.playSuccessSound()
  }

  findProductRow(productId) {
    const rows = this.itemsContainerTarget.querySelectorAll('.sale-item-row')
    for (const row of rows) {
      const productIdInput = row.querySelector('input[name*="[product_id]"]')
      if (productIdInput && productIdInput.value == productId) {
        const destroyInput = row.querySelector('input[name*="[_destroy]"]')
        if (!destroyInput || destroyInput.value !== '1') {
          return row
        }
      }
    }
    return null
  }

  createNewItemRow(product) {
    let stockClass = 'out-of-stock'
    if (product.stock > 10) {
      stockClass = 'in-stock'
    } else if (product.stock > 0) {
      stockClass = 'low-stock'
    }
    
    const template = `
      <tr class="sale-item-row hover:bg-gray-50 transition" data-product-id="${product.id}">
        <input type="hidden" name="sale[sale_items_attributes][${this.itemIndex}][product_id]" value="${product.id}">
        <input type="hidden" name="sale[sale_items_attributes][${this.itemIndex}][unit_price]" value="${product.price}">
        <input type="hidden" name="sale[sale_items_attributes][${this.itemIndex}][subtotal]" value="${product.price}">
        <input type="hidden" name="sale[sale_items_attributes][${this.itemIndex}][_destroy]" value="0">
        
        <td class="px-3 py-2 text-sm text-gray-800 font-medium product-name-cell">${product.name}</td>
        <td class="px-3 py-2 text-xs font-bold stock-cell ${stockClass}">${product.stock} ${product.unit || ''}</td>
        <td class="px-3 py-2">
          <input type="number" 
            name="sale[sale_items_attributes][${this.itemIndex}][quantity]" 
            min="0.001" 
            step="0.001" 
            value="1"
            class="quantity-input w-full px-3 py-2 text-base font-bold text-right border-2 border-green-400 bg-green-50 rounded-lg focus:ring-2 focus:ring-green-500 focus:border-green-500 hover:bg-green-100 transition shadow-sm"
            data-action="input->pos-sale#updateItemSubtotal">
        </td>
        <td class="px-3 py-2 text-sm font-semibold text-gray-700 price-cell">$${product.price.toFixed(2)}</td>
        <td class="px-3 py-2">
          <input type="number" 
            name="sale[sale_items_attributes][${this.itemIndex}][discount]" 
            min="0" 
            step="0.01" 
            value="0" 
            class="discount-input w-full px-3 py-2 text-base font-bold text-right border-2 border-orange-400 bg-orange-50 rounded-lg focus:ring-2 focus:ring-orange-500 focus:border-orange-500 hover:bg-orange-100 transition shadow-sm"
            data-action="input->pos-sale#updateItemSubtotal">
        </td>
        <td class="subtotal-cell px-3 py-2 text-sm font-bold text-green-700">$${product.price.toFixed(2)}</td>
        <td class="px-3 py-2">
          <button type="button" 
            class="btn-remove-item p-1.5 bg-red-100 text-red-600 rounded hover:bg-red-200 transition" 
            data-action="click->pos-sale#removeItem"
            title="Eliminar">
            <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16"/>
            </svg>
          </button>
        </td>
      </tr>
    `
    
    this.itemsContainerTarget.insertAdjacentHTML('beforeend', template)
    this.itemIndex++
    this.updateTotal()
  }

  updateItemSubtotal(event) {
    const row = event.target.closest('.sale-item-row')
    const qtyInput = row.querySelector('input[name*="[quantity]"]')
    const priceInput = row.querySelector('input[name*="[unit_price]"]')
    const discountInput = row.querySelector('input[name*="[discount]"]')
    const subtotalInput = row.querySelector('input[name*="[subtotal]"]')
    const subtotalCell = row.querySelector('.subtotal-cell')
    
    const qty = parseFloat(qtyInput.value) || 0
    const price = parseFloat(priceInput.value) || 0
    const discount = parseFloat(discountInput.value) || 0
    
    const subtotal = (qty * price) - discount
    
    subtotalInput.value = subtotal.toFixed(2)
    subtotalCell.textContent = `$${subtotal.toFixed(2)}`
    
    this.updateTotal()
  }

  removeItem(event) {
    const row = event.target.closest('.sale-item-row')
    row.remove()
    this.updateTotal()
    this.updateEmptyCartVisibility()
  }

  // Detectar cambio en método de pago
  // Agrega data-action en el select de payment_method del formulario:
  // data: { action: "change->pos-sale#handlePaymentMethodChange" }
  handlePaymentMethodChange(event) {
    const method = event.target.value
    
    if (method === 'cash' && this.hasPaymentSectionTarget) {
      this.paymentSectionTarget.style.display = 'block'
    } else if (this.hasPaymentSectionTarget) {
      this.paymentSectionTarget.style.display = 'none'
    }
  }
  
  calculateChange() {
    if (!this.hasReceivedAmountTarget || !this.hasChangeAmountTarget) return
    
    const total = this.getCurrentTotal()
    const received = parseFloat(this.receivedAmountTarget.value) || 0
    const change = received - total
    
    this.changeAmountTarget.textContent = `$${change.toFixed(2)}`
    
    if (change < 0) {
      this.changeAmountTarget.classList.add('negative')
    } else {
      this.changeAmountTarget.classList.remove('negative')
    }
  }
  
  getCurrentTotal() {
    let total = 0
    const rows = this.itemsContainerTarget.querySelectorAll('.sale-item-row')
    
    rows.forEach(row => {
      if (row.style.display !== 'none') {
        const subtotalInput = row.querySelector('input[name*="[subtotal]"]')
        if (subtotalInput) {
          total += parseFloat(subtotalInput.value) || 0
        }
      }
    })
    
    return total
  }

  updateTotal() {
    const total = this.getCurrentTotal()
    this.totalAmountTarget.textContent = `$${total.toFixed(2)}`
    
    if (this.hasPaymentSectionTarget && this.paymentSectionTarget.style.display !== 'none') {
      this.calculateChange()
    }
    
    // Actualizar resumen
    this.updateSummary()
  }

  updateSummary() {
    // Contar items (filas visibles)
    const rows = this.itemsContainerTarget.querySelectorAll('.sale-item-row:not([style*="display: none"])')
    
    // Calcular unidades totales y descuentos
    let totalUnits = 0
    let totalDiscount = 0
    
    rows.forEach(row => {
      const quantityInput = row.querySelector('input[name*="[quantity]"]')
      const discountInput = row.querySelector('input[name*="[discount]"]')
      
      if (quantityInput) {
        totalUnits += parseFloat(quantityInput.value) || 0
      }
      
      if (discountInput) {
        totalDiscount += parseFloat(discountInput.value) || 0
      }
    })
    
    // Actualizar targets si existen
    if (this.hasItemsCountTarget) {
      this.itemsCountTarget.textContent = rows.length
    }
    
    if (this.hasUnitsCountTarget) {
      this.unitsCountTarget.textContent = totalUnits.toFixed(3).replace(/\.?0+$/, '')
    }
    
    if (this.hasDiscountTotalTarget) {
      this.discountTotalTarget.textContent = `$${totalDiscount.toFixed(2)}`
    }
  }

  updateEmptyCartVisibility() {
    const rows = this.itemsContainerTarget.querySelectorAll('.sale-item-row:not([style*="display: none"])')
    this.emptyCartTarget.style.display = rows.length === 0 ? 'block' : 'none'
  }

  toggleNotes() {
    const isVisible = this.notesContainerTarget.style.display !== 'none'
    this.notesContainerTarget.style.display = isVisible ? 'none' : 'block'
  }

  clearSale() {
    this.itemsContainerTarget.innerHTML = ''
    this.searchInputTarget.value = ''
    if (this.hasReceivedAmountTarget) {
      this.receivedAmountTarget.value = ''
    }
    
    // IMPORTANTE: Resetear itemIndex
    this.itemIndex = 0
    
    this.updateTotal()
    this.updateSummary()
    this.updateEmptyCartVisibility()
    this.focusSearch()
  }

  playSuccessSound() {
    // Opcional: agregar sonido de "beep" cuando se escanea
    const audio = new Audio('data:audio/wav;base64,UklGRnoGAABXQVZFZm10IBAAAAABAAEAQB8AAEAfAAABAAgAZGF0YQoGAACBhYqFbF1fdJivrJBhNjVgodDbq2EcBj+a2/LDciUFLIHO8tiJNwgZaLvt559NEAxQp+PwtmMcBjiR1/LMeSwFJHfH8N2QQAoUXrTp66hVFApGn+DyvmwhBSuBzvLZiTYIEGi78OahUBELTKXh8bJpHgU2jdXuzngtBSh+yO7djkILEnC967hdIAQua9DxwHMmBTGFzvLYiTUIEWW58OOmURILSKPh8bllIAU0jtXuznctBSh+yO7djUALEHG967ldIAU') 
    audio.volume = 0.3
    audio.play().catch(() => {})
  }

  // ========== PAUSAR VENTA ==========
  
  pauseSale(event) {
    event.preventDefault()
    
    const items = this.collectCurrentSaleItems()
    
    if (items.length === 0) {
      alert("⚠️ No hay productos para pausar")
      return
    }
    
    const saleData = {
      ticketNumber: this.generateTicketNumber(),
      items: items,
      customerId: this.hasCustomerSelectTarget ? this.customerSelectTarget.value : null,
      customerName: this.getCustomerName(),
      warehouseId: this.warehouseSelectTarget.value,
      subtotal: this.getCurrentTotal(),
      timestamp: new Date().toISOString(),
      notes: this.hasNotesContainerTarget ? this.element.querySelector('[name="sale[notes]"]')?.value : ''
    }
    
    this.savePendingSale(saleData)
    this.clearSale()
    this.updatePendingUI()
    
    Swal.fire({
      icon: 'success',
      title: '✅ Venta pausada',
      html: `<p class="text-lg">Ticket #${saleData.ticketNumber}</p>
             <p class="text-gray-600">${items.length} productos guardados</p>
             <p class="text-green-600 font-bold text-2xl mt-2">$${saleData.subtotal.toFixed(2)}</p>`,
      timer: 2000,
      showConfirmButton: false
    })
  }
  
  resumeSale(event) {
    const ticketNumber = parseInt(event.currentTarget.dataset.ticket)
    const saleData = this.loadPendingSale(ticketNumber)
    
    if (!saleData) {
      Swal.fire({
        icon: 'error',
        title: '❌ Error',
        text: 'No se encontró el ticket',
        confirmButtonColor: '#dc2626'
      })
      return
    }
    
    // Generar HTML de productos
    const itemsHTML = saleData.items.map(item => `
      <div class="flex justify-between items-center py-2 border-b border-gray-200">
        <div class="text-left flex-1">
          <p class="font-semibold text-gray-800 text-sm">${item.productName}</p>
          <p class="text-xs text-gray-500">
            ${item.quantity} × $${item.unitPrice.toFixed(2)}
            ${item.discount > 0 ? `<span class="text-orange-600">(-$${item.discount.toFixed(2)})</span>` : ''}
          </p>
        </div>
        <div class="text-right">
          <p class="font-bold text-green-600">$${item.subtotal.toFixed(2)}</p>
        </div>
      </div>
    `).join('')
    
    // Calcular tiempo transcurrido
    const timestamp = new Date(saleData.timestamp)
    const now = new Date()
    const diffMinutes = Math.floor((now - timestamp) / 1000 / 60)
    let timeText = ''
    
    if (diffMinutes < 1) {
      timeText = 'Hace menos de 1 minuto'
    } else if (diffMinutes < 60) {
      timeText = `Hace ${diffMinutes} minuto${diffMinutes !== 1 ? 's' : ''}`
    } else {
      const diffHours = Math.floor(diffMinutes / 60)
      timeText = `Hace ${diffHours} hora${diffHours !== 1 ? 's' : ''}`
    }
    
    // SWEETALERT2 EN VEZ DE CONFIRM FEO
    Swal.fire({
      title: `🎫 Ticket #${ticketNumber}`,
      html: `
        <div class="text-left space-y-4">
          <!-- Info del ticket -->
          <div class="bg-blue-50 rounded-lg p-4 border-2 border-blue-200">
            <div class="grid grid-cols-2 gap-3 text-sm">
              <div>
                <p class="text-gray-600 font-medium">Cliente:</p>
                <p class="font-bold text-gray-800">${saleData.customerName || 'Mostrador'}</p>
              </div>
              <div>
                <p class="text-gray-600 font-medium">Pausado:</p>
                <p class="font-bold text-gray-800">${timeText}</p>
              </div>
            </div>
          </div>
          
          <!-- Lista de productos -->
          <div>
            <h4 class="font-bold text-gray-800 mb-2 flex items-center gap-2">
              <svg class="w-5 h-5 text-green-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 5H7a2 2 0 00-2 2v12a2 2 0 002 2h10a2 2 0 002-2V7a2 2 0 00-2-2h-2M9 5a2 2 0 002 2h2a2 2 0 002-2M9 5a2 2 0 012-2h2a2 2 0 012 2"/>
              </svg>
              Productos (${saleData.items.length})
            </h4>
            <div class="max-h-64 overflow-y-auto bg-gray-50 rounded-lg p-3 border border-gray-200">
              ${itemsHTML}
            </div>
          </div>
          
          <!-- Total -->
          <div class="bg-gradient-to-r from-green-600 to-green-700 rounded-lg p-4 text-white">
            <div class="flex justify-between items-center">
              <span class="text-lg font-semibold">Total:</span>
              <span class="text-3xl font-bold">$${saleData.subtotal.toFixed(2)}</span>
            </div>
          </div>
          
          ${saleData.notes ? `
            <div class="bg-yellow-50 border-l-4 border-yellow-400 p-3 rounded">
              <p class="text-xs font-semibold text-yellow-800 mb-1">📝 Notas:</p>
              <p class="text-sm text-yellow-900">${saleData.notes}</p>
            </div>
          ` : ''}
          
          <!-- Advertencia -->
          <div class="bg-amber-50 border-l-4 border-amber-400 p-3 rounded">
            <p class="text-sm text-amber-800">
              <strong>⚠️ Atención:</strong> Se descartará la venta actual si existe.
            </p>
          </div>
        </div>
      `,
      icon: null,
      showCancelButton: true,
      confirmButtonText: '✅ Continuar venta',
      cancelButtonText: '❌ Cancelar',
      confirmButtonColor: '#16a34a',
      cancelButtonColor: '#6b7280',
      width: '600px',
      customClass: {
        popup: 'rounded-xl shadow-2xl',
        title: 'text-2xl font-bold',
        htmlContainer: 'text-base',
        confirmButton: 'px-6 py-3 rounded-lg font-bold text-base shadow-lg',
        cancelButton: 'px-6 py-3 rounded-lg font-semibold text-base'
      },
      focusConfirm: true
    }).then((result) => {
      if (result.isConfirmed) {
        this.restoreSaleData(saleData)
        this.removePendingSale(ticketNumber)
        this.updatePendingUI()
        
        Swal.fire({
          icon: 'success',
          title: '✅ Ticket restaurado',
          html: `
            <div class="text-center space-y-2">
              <p class="text-lg">${saleData.items.length} producto${saleData.items.length !== 1 ? 's' : ''} cargado${saleData.items.length !== 1 ? 's' : ''}</p>
              <p class="text-green-600 font-bold text-2xl">$${saleData.subtotal.toFixed(2)}</p>
            </div>
          `,
          timer: 2000,
          showConfirmButton: false,
          customClass: {
            popup: 'rounded-xl shadow-2xl'
          }
        })
      }
    })
  }
  
  cancelTicket(event) {
    event.stopPropagation()
    const ticketNumber = parseInt(event.currentTarget.dataset.ticket)
    const saleData = this.loadPendingSale(ticketNumber)
    
    Swal.fire({
      title: '⚠️ ¿Cancelar ticket?',
      html: `
        <div class="text-left space-y-3">
          <div class="bg-red-50 border-2 border-red-200 rounded-lg p-4">
            <p class="text-center mb-3">
              <span class="text-5xl">🗑️</span>
            </p>
            <p class="text-lg font-bold text-gray-800 text-center mb-2">
              Ticket #${ticketNumber}
            </p>
            <div class="text-sm text-gray-700 space-y-1">
              <p><strong>Cliente:</strong> ${saleData.customerName || 'Mostrador'}</p>
              <p><strong>Productos:</strong> ${saleData.items.length} artículo${saleData.items.length !== 1 ? 's' : ''}</p>
              <p><strong>Total:</strong> <span class="text-red-600 font-bold text-xl">$${saleData.subtotal.toFixed(2)}</span></p>
            </div>
          </div>
          
          <div class="bg-amber-50 border-l-4 border-amber-400 p-3 rounded">
            <p class="text-sm text-amber-800">
              <strong>⚠️ Esta acción no se puede deshacer.</strong><br>
              Todos los productos de este ticket se perderán.
            </p>
          </div>
        </div>
      `,
      icon: null,
      showCancelButton: true,
      confirmButtonText: '🗑️ Sí, cancelar ticket',
      cancelButtonText: '← Volver',
      confirmButtonColor: '#dc2626',
      cancelButtonColor: '#6b7280',
      customClass: {
        popup: 'rounded-xl shadow-2xl',
        title: 'text-2xl font-bold',
        confirmButton: 'px-6 py-3 rounded-lg font-bold text-base shadow-lg',
        cancelButton: 'px-6 py-3 rounded-lg font-semibold text-base'
      },
      focusCancel: true
    }).then((result) => {
      if (result.isConfirmed) {
        this.removePendingSale(ticketNumber)
        this.updatePendingUI()
        
        Swal.fire({
          icon: 'info',
          title: 'Ticket cancelado',
          text: `Ticket #${ticketNumber} eliminado`,
          timer: 1500,
          showConfirmButton: false,
          customClass: {
            popup: 'rounded-xl shadow-2xl'
          }
        })
      }
    })
  }
  
  collectCurrentSaleItems() {
    const items = []
    const rows = this.itemsContainerTarget.querySelectorAll('.sale-item-row')
    
    rows.forEach(row => {
      if (row.style.display !== 'none') {
        const productId = row.dataset.productId
        const productName = row.querySelector('.product-name-cell')?.textContent || 'Producto'
        const quantity = parseFloat(row.querySelector('input[name*="[quantity]"]')?.value || 0)
        const unitPrice = parseFloat(row.querySelector('input[name*="[unit_price]"]')?.value || 0)
        const discount = parseFloat(row.querySelector('input[name*="[discount]"]')?.value || 0)
        const subtotal = parseFloat(row.querySelector('input[name*="[subtotal]"]')?.value || 0)
        const stock = row.querySelector('.stock-cell')?.textContent || ''
        const unit = row.querySelector('.stock-cell')?.textContent?.match(/[a-zA-Z]+/) || ['']
        
        if (productId && quantity > 0) {
          items.push({
            productId,
            productName,
            quantity,
            unitPrice,
            discount,
            subtotal,
            stock,
            unit: unit[0]
          })
        }
      }
    })
    
    return items
  }
  
  restoreSaleData(saleData) {
    this.clearSale()
    
    if (this.hasCustomerSelectTarget && saleData.customerId) {
      this.customerSelectTarget.value = saleData.customerId
    }
    
    if (saleData.warehouseId) {
      this.warehouseSelectTarget.value = saleData.warehouseId
    }
    
    if (saleData.notes && this.hasNotesContainerTarget) {
      const notesField = this.element.querySelector('[name="sale[notes]"]')
      if (notesField) {
        notesField.value = saleData.notes
        this.notesContainerTarget.style.display = 'block'
      }
    }
    
    // IMPORTANTE: Resetear itemIndex para que Rails lo reciba correctamente
    this.itemIndex = 0
    
    saleData.items.forEach(item => {
      const product = {
        id: item.productId,
        name: item.productName,
        price: item.unitPrice,
        stock: parseFloat(item.stock) || 0,
        unit: item.unit
      }
      
      this.createNewItemRow(product)
      
      const lastRow = this.itemsContainerTarget.querySelector('.sale-item-row:last-child')
      if (lastRow) {
        const qtyInput = lastRow.querySelector('input[name*="[quantity]"]')
        const discountInput = lastRow.querySelector('input[name*="[discount]"]')
        
        if (qtyInput && item.quantity !== 1) {
          qtyInput.value = item.quantity
          qtyInput.dispatchEvent(new Event('input', { bubbles: true }))
        }
        
        if (discountInput && item.discount > 0) {
          discountInput.value = item.discount
          discountInput.dispatchEvent(new Event('input', { bubbles: true }))
        }
      }
    })
    
    this.updateEmptyCartVisibility()
    this.updateTotal()
    window.scrollTo({ top: 0, behavior: 'smooth' })
  }
  
  getPendingSales() {
    const sessionId = this.getCurrentSessionId()
    const key = `pending_sales_${sessionId}`
    const data = localStorage.getItem(key)
    return data ? JSON.parse(data) : []
  }
  
  savePendingSale(saleData) {
    const pending = this.getPendingSales()
    pending.push(saleData)
    
    const sessionId = this.getCurrentSessionId()
    localStorage.setItem(`pending_sales_${sessionId}`, JSON.stringify(pending))
  }
  
  loadPendingSale(ticketNumber) {
    const pending = this.getPendingSales()
    return pending.find(sale => sale.ticketNumber === ticketNumber)
  }
  
  removePendingSale(ticketNumber) {
    const pending = this.getPendingSales()
    const filtered = pending.filter(sale => sale.ticketNumber !== ticketNumber)
    
    const sessionId = this.getCurrentSessionId()
    localStorage.setItem(`pending_sales_${sessionId}`, JSON.stringify(filtered))
  }
  
  generateTicketNumber() {
    const pending = this.getPendingSales()
    const maxTicket = pending.reduce((max, sale) => 
      Math.max(max, sale.ticketNumber), 0)
    return maxTicket + 1
  }
  
  updatePendingUI() {
    this.updatePendingCount()
    this.loadPendingList()
  }
  
  updatePendingCount() {
    if (!this.hasPendingCountTarget) return
    
    const count = this.getPendingSales().length
    this.pendingCountTarget.textContent = count
    
    if (count > 0) {
      this.pendingCountTarget.classList.remove('hidden')
    } else {
      this.pendingCountTarget.classList.add('hidden')
    }
  }
  
  loadPendingList() {
    if (!this.hasPendingListTarget) return
    
    const pending = this.getPendingSales()
    
    if (pending.length === 0) {
      this.pendingListTarget.innerHTML = `
        <div class="p-4 text-center text-gray-500 text-sm">
          No hay tickets en espera
        </div>
      `
      return
    }
    
    this.pendingListTarget.innerHTML = pending.map(sale => `
      <div class="border-b border-gray-200 p-3 hover:bg-gray-50 cursor-pointer transition"
           data-action="click->pos-sale#resumeSale"
           data-ticket="${sale.ticketNumber}">
        <div class="flex justify-between items-start mb-2">
          <div>
            <span class="font-bold text-lg text-gray-800">Ticket #${sale.ticketNumber}</span>
            <p class="text-sm text-gray-600">${sale.customerName || 'Mostrador'}</p>
            <p class="text-xs text-gray-500">${sale.items.length} producto${sale.items.length !== 1 ? 's' : ''}</p>
          </div>
          <div class="text-right">
            <p class="text-lg font-bold text-green-600">$${sale.subtotal.toFixed(2)}</p>
            <p class="text-xs text-gray-500">${this.formatTime(sale.timestamp)}</p>
          </div>
        </div>
        
        <div class="flex gap-2 mt-2">
          <button type="button" class="flex-1 px-3 py-1.5 bg-blue-600 text-white text-xs font-semibold rounded hover:bg-blue-700 transition">
            Continuar
          </button>
          <button type="button" data-action="click->pos-sale#cancelTicket"
                  data-ticket="${sale.ticketNumber}"
                  class="px-3 py-1.5 bg-red-100 text-red-700 text-xs font-semibold rounded hover:bg-red-200 transition">
            Cancelar
          </button>
        </div>
      </div>
    `).join('')
  }
  
  getCurrentSessionId() {
    const metaTag = document.querySelector('meta[name="register-session-id"]')
    return metaTag?.content || this.element.dataset.sessionId || 'default'
  }
  
  getCustomerName() {
    if (!this.hasCustomerSelectTarget) return 'Mostrador'
    const selected = this.customerSelectTarget.selectedOptions[0]
    return selected ? selected.textContent : 'Mostrador'
  }
  
  formatTime(timestamp) {
    const date = new Date(timestamp)
    return date.toLocaleTimeString('es-MX', { 
      hour: '2-digit', 
      minute: '2-digit' 
    })
  }

  //Esperar a que termine la búsqueda
  waitForSearchResults(query, timeout = 1000) {
    return new Promise((resolve) => {
      const startTime = Date.now()
      
      const checkResults = () => {
        // Si ya tenemos resultados, resolver
        if (this.searchResultsData && this.searchResultsData.length > 0) {
          resolve(this.searchResultsData)
          return
        }
        
        // Si se acabó el tiempo, resolver con vacío
        if (Date.now() - startTime > timeout) {
          resolve([])
          return
        }
        
        // Intentar de nuevo en 50ms
        setTimeout(checkResults, 50)
      }
      
      checkResults()
    })
  }

  // Agregar campos hidden para enviar amount_received y change_given
  addHiddenFields(received, total) {
    const form = this.element.querySelector('form')
    
    // Remover campos previos si existen
    this.removeHiddenFields()
    
    // Calcular cambio
    const change = received - total
    
    // Crear campo amount_received
    const receivedField = document.createElement('input')
    receivedField.type = 'hidden'
    receivedField.name = 'sale[amount_received]'
    receivedField.value = received.toFixed(2)
    receivedField.id = 'hidden_amount_received'
    form.appendChild(receivedField)
    
    // Crear campo change_given
    const changeField = document.createElement('input')
    changeField.type = 'hidden'
    changeField.name = 'sale[change_given]'
    changeField.value = change.toFixed(2)
    changeField.id = 'hidden_change_given'
    form.appendChild(changeField)
    
    console.log('💰 Campos agregados - Recibido:', received, 'Cambio:', change)
  }
  
  // Remover campos hidden si existen
  removeHiddenFields() {
    const existingReceived = document.getElementById('hidden_amount_received')
    const existingChange = document.getElementById('hidden_change_given')
    
    if (existingReceived) existingReceived.remove()
    if (existingChange) existingChange.remove()
  }

}


