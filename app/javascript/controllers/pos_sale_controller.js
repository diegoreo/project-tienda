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
    "changeAmount"         
  ]

  connect() {
    console.log("POS Sale controller connected")
    this.searchTimeout = null
    this.selectedIndex = -1
    this.searchResultsData = []
    this.itemIndex = 0
    
    // Cargar almacén guardado
    this.loadWarehousePreference()
    // Verificar método de pago inicial y mostrar campo si es efectivo
    this.checkInitialPaymentMethod()
    
    // Enfocar buscador al cargar (con pequeño delay para que cargue el DOM)
    setTimeout(() => {
      this.focusSearch()
    }, 100)
    
    // Atajos de teclado globales
    document.addEventListener('keydown', this.handleGlobalKeydown.bind(this))
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
      if (this.searchResultsTarget.classList.contains('active')) {
        this.closeSearchResults()
        this.searchInputTarget.value = ''
        this.focusSearch()
      } else if (confirm('¿Limpiar toda la venta?')) {
        this.clearSale()
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
    }
    
    // Si pasa todas las validaciones, permitir el submit
    return true
  }

  searchProducts(event) {
    clearTimeout(this.searchTimeout)
    const query = event.target.value.trim()
    
    if (query.length === 0) {
      this.closeSearchResults()
      return
    }
    
    // Solo buscar, NO agregar automáticamente
    // Esperar 400ms para búsqueda
    this.searchTimeout = setTimeout(() => {
      this.performSearch(query)
    }, 400)
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

  handleSearchKeydown(event) {
    // Si presiona Enter en el campo de búsqueda
    if (event.key === 'Enter') {
      event.preventDefault()
      const query = this.searchInputTarget.value.trim()
      
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
    this.updateTotal()
    this.updateEmptyCartVisibility()
    this.focusSearch()
  }

  playSuccessSound() {
    // Opcional: agregar sonido de "beep" cuando se escanea
    const audio = new Audio('data:audio/wav;base64,UklGRnoGAABXQVZFZm10IBAAAAABAAEAQB8AAEAfAAABAAgAZGF0YQoGAACBhYqFbF1fdJivrJBhNjVgodDbq2EcBj+a2/LDciUFLIHO8tiJNwgZaLvt559NEAxQp+PwtmMcBjiR1/LMeSwFJHfH8N2QQAoUXrTp66hVFApGn+DyvmwhBSuBzvLZiTYIEGi78OahUBELTKXh8bJpHgU2jdXuzngtBSh+yO7djkILEnC967hdIAQua9DxwHMmBTGFzvLYiTUIEWW58OOmURILSKPh8bllIAU0jtXuznctBSh+yO7djUALEHG967ldIAU') 
    audio.volume = 0.3
    audio.play().catch(() => {})
  }
}


