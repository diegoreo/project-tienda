import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [
    "searchInput",
    "searchResults", 
    "hiddenField",
    "clearButton"
  ]

  static values = {
    selectedId: Number,
    selectedName: String
  }

  connect() {
    this.boundCloseResults = this.closeOnClickOutside.bind(this)
    this.lastSearchQuery = ""
    this.selectedIndex = -1
    
    // Detectar entrada de lector de código de barras
    this.keyPressTimestamps = []
  }

  disconnect() {
    document.removeEventListener("click", this.boundCloseResults)
    if (this.searchTimeout) clearTimeout(this.searchTimeout)
  }

  // Búsqueda con debounce y detección de lector de barras
  search(event) {
    const query = this.searchInputTarget.value.trim()
    
    // Detectar si es lector de código de barras (entrada muy rápida)
    const now = Date.now()
    this.keyPressTimestamps.push(now)
    
    // Mantener solo últimas 5 pulsaciones
    if (this.keyPressTimestamps.length > 5) {
      this.keyPressTimestamps.shift()
    }
    
    // Si hay 5+ caracteres escritos en menos de 100ms, es lector de barras
    const isBarcodeScan = this.keyPressTimestamps.length >= 5 && 
                          (now - this.keyPressTimestamps[0]) < 100

    if (query.length < 2) {
      this.hideResults()
      return
    }

    // Si es el mismo query, no buscar de nuevo
    if (query === this.lastSearchQuery) return

    // Limpiar timeout anterior
    if (this.searchTimeout) clearTimeout(this.searchTimeout)

    // Si es lector de barras, buscar inmediatamente
    if (isBarcodeScan) {
      this.performSearch(query)
    } else {
      // Si es escritura manual, debounce de 300ms
      this.searchTimeout = setTimeout(() => {
        this.performSearch(query)
      }, 300)
    }
  }

  // Realizar búsqueda
  async performSearch(query) {
    this.lastSearchQuery = query

    try {
      const response = await fetch(`/products/search_master?q=${encodeURIComponent(query)}`)
      
      if (!response.ok) {
        throw new Error("Error en la búsqueda")
      }

      const products = await response.json()
      this.displayResults(products)
      
    } catch (error) {
      console.error("Error:", error)
      this.searchResultsTarget.innerHTML = `
        <div class="px-4 py-3 text-sm text-red-600">
          Error al buscar productos. Intenta de nuevo.
        </div>
      `
      this.searchResultsTarget.classList.remove("hidden")
    }
  }

  // Mostrar resultados
  displayResults(products) {
    if (products.length === 0) {
      this.searchResultsTarget.innerHTML = `
        <div class="px-4 py-3 text-sm text-gray-500 text-center">
          <svg class="w-8 h-8 mx-auto mb-2 text-gray-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9.172 16.172a4 4 0 015.656 0M9 10h.01M15 10h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z"></path>
          </svg>
          No se encontraron productos maestros
        </div>
      `
      this.searchResultsTarget.classList.remove("hidden")
      return
    }

    this.searchResultsTarget.innerHTML = products.map((product, index) => `
      <div class="px-4 py-3 hover:bg-indigo-50 cursor-pointer border-b border-gray-100 last:border-b-0 transition ${index === 0 ? 'bg-indigo-50' : ''}"
           data-action="click->master-product-search#selectProduct"
           data-product-id="${product.id}"
           data-product-name="${product.name}"
           data-index="${index}">
        <div class="flex items-center">
          <div class="flex-shrink-0 w-10 h-10 bg-indigo-100 rounded-lg flex items-center justify-center mr-3">
            <svg class="w-6 h-6 text-indigo-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M20 7l-8-4-8 4m16 0l-8 4m8-4v10l-8 4m0-10L4 7m8 4v10M4 7v10l8 4"></path>
            </svg>
          </div>
          <div class="flex-1">
            <div class="font-semibold text-gray-900">${product.name}</div>
            <div class="text-xs text-gray-500">ID: ${product.id}</div>
          </div>
          <div class="ml-2">
            <svg class="w-5 h-5 text-indigo-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 5l7 7-7 7"></path>
            </svg>
          </div>
        </div>
      </div>
    `).join('')

    this.selectedIndex = 0
    this.searchResultsTarget.classList.remove("hidden")
    
    // Agregar listener para cerrar al hacer click fuera
    document.addEventListener("click", this.boundCloseResults)
  }

  // Seleccionar producto
  selectProduct(event) {
    const productId = event.currentTarget.dataset.productId
    const productName = event.currentTarget.dataset.productName

    // Guardar en campo oculto
    this.hiddenFieldTarget.value = productId
    
    // Mostrar en input
    this.searchInputTarget.value = productName
    
    // Guardar en valores
    this.selectedIdValue = productId
    this.selectedNameValue = productName

    // Mostrar botón de limpiar
    if (this.hasClearButtonTarget) {
      this.clearButtonTarget.classList.remove("hidden")
    }

    // Ocultar resultados
    this.hideResults()
    
    // Limpiar timestamps
    this.keyPressTimestamps = []
  }

  // Navegación con teclado
  navigate(event) {
    const results = this.searchResultsTarget.querySelectorAll('[data-index]')
    
    if (results.length === 0) return

    switch(event.key) {
      case 'ArrowDown':
        event.preventDefault()
        this.selectedIndex = Math.min(this.selectedIndex + 1, results.length - 1)
        this.highlightResult(results)
        break
        
      case 'ArrowUp':
        event.preventDefault()
        this.selectedIndex = Math.max(this.selectedIndex - 1, 0)
        this.highlightResult(results)
        break
        
      case 'Enter':
        event.preventDefault()
        if (this.selectedIndex >= 0 && results[this.selectedIndex]) {
          results[this.selectedIndex].click()
        }
        break
        
      case 'Escape':
        event.preventDefault()
        this.hideResults()
        this.searchInputTarget.blur()
        break
    }
  }

  // Destacar resultado seleccionado
  highlightResult(results) {
    results.forEach((result, index) => {
      if (index === this.selectedIndex) {
        result.classList.add('bg-indigo-50')
        result.scrollIntoView({ block: 'nearest', behavior: 'smooth' })
      } else {
        result.classList.remove('bg-indigo-50')
      }
    })
  }

  // Limpiar selección
  clear() {
    this.searchInputTarget.value = ""
    this.hiddenFieldTarget.value = ""
    this.selectedIdValue = null
    this.selectedNameValue = null
    this.lastSearchQuery = ""
    this.hideResults()
    
    if (this.hasClearButtonTarget) {
      this.clearButtonTarget.classList.add("hidden")
    }
    
    this.searchInputTarget.focus()
  }

  // Ocultar resultados
  hideResults() {
    this.searchResultsTarget.classList.add("hidden")
    this.selectedIndex = -1
    document.removeEventListener("click", this.boundCloseResults)
  }

  // Cerrar al hacer click fuera
  closeOnClickOutside(event) {
    if (!this.element.contains(event.target)) {
      this.hideResults()
    }
  }
}