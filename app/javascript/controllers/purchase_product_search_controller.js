import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [
    "searchInput", 
    "searchResults", 
    "productIdInput", 
    "productNameDisplay",
    "searchContainer",
    "selectedContainer",
    "conversionInput"
  ]

  connect() {
    console.log("Purchase product search connected")
    this.searchTimeout = null
    this.selectedIndex = -1
    this.searchResultsData = []
    
    // Verificar si ya hay un producto seleccionado al cargar
    if (this.productIdInputTarget.value) {
      this.showSelectedView()
    } else {
      this.showSearchView()
    }
    
    // Cerrar dropdown al hacer click fuera
    this.boundCloseOnClickOutside = this.closeOnClickOutside.bind(this)
    document.addEventListener('click', this.boundCloseOnClickOutside)
    
    // Reposicionar o cerrar dropdown al hacer scroll
    this.boundHandleScroll = this.handleScroll.bind(this)
    window.addEventListener('scroll', this.boundHandleScroll, true)
  }

  disconnect() {
    // Limpiar event listeners al desconectar
    document.removeEventListener('click', this.boundCloseOnClickOutside)
    window.removeEventListener('scroll', this.boundHandleScroll, true)
  }

  closeOnClickOutside(event) {
    // Cerrar solo si el click fue FUERA del input y del dropdown
    if (!this.element.contains(event.target)) {
      this.closeSearchResults()
    }
  }

  handleScroll(event) {
    // Si el scroll es dentro del dropdown mismo, no hacer nada
    if (event.target === this.searchResultsTarget || 
        this.searchResultsTarget.contains(event.target)) {
      return
    }
    
    // Si el dropdown está visible, reposicionarlo
    if (!this.searchResultsTarget.classList.contains('hidden')) {
      this.positionDropdown()
    }
  }

  searchProducts(event) {
    clearTimeout(this.searchTimeout)
    const query = event.target.value.trim()
    
    if (query.length === 0) {
      this.closeSearchResults()
      return
    }
    
    this.searchTimeout = setTimeout(() => {
      this.performSearch(query)
    }, 400)
  }

  async performSearch(query) {
    try {
      const response = await fetch(`/products/search?q=${encodeURIComponent(query)}`)
      const products = await response.json()
      
      if (products.length > 0) {
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
    
    const html = products.map((product, index) => `
      <div class="search-result-item px-4 py-3 cursor-pointer border-b border-gray-200 last:border-b-0 hover:bg-green-50 transition duration-150" 
           data-index="${index}" 
           data-action="click->purchase-product-search#selectProduct mouseenter->purchase-product-search#highlightItem">
        <div class="flex justify-between items-start">
          <div class="flex-1">
            <div class="font-semibold text-gray-900">${product.name}</div>
            <div class="text-xs text-gray-500 mt-1">
              ${product.barcodes && product.barcodes.length > 0 ? `📦 ${product.barcodes.join(', ')}` : `ID: ${product.id}`}
            </div>
          </div>
          <div class="ml-3 flex-shrink-0">
            <span class="px-2 py-1 text-xs font-semibold bg-blue-100 text-blue-800 rounded-full">
              ${product.unit}
            </span>
          </div>
        </div>
      </div>
    `).join('')
    
    this.searchResultsTarget.innerHTML = html
    
    // Posicionar el dropdown justo debajo del input
    this.positionDropdown()
    
    this.searchResultsTarget.classList.remove('hidden')
    
    // Auto-scroll al item seleccionado si existe
    if (this.selectedIndex >= 0) {
      this.scrollToSelected()
    }
  }
  
  positionDropdown() {
    const inputRect = this.searchInputTarget.getBoundingClientRect()
    
    // Posicionar con fixed
    this.searchResultsTarget.style.position = 'fixed'
    this.searchResultsTarget.style.top = `${inputRect.bottom + 4}px`
    this.searchResultsTarget.style.left = `${inputRect.left}px`
    this.searchResultsTarget.style.width = `${inputRect.width}px`
    this.searchResultsTarget.style.zIndex = '99999'
  }

  showNoResults() {
    this.searchResultsTarget.innerHTML = `
      <div class="px-4 py-3 text-center text-gray-500 text-sm">
        No se encontraron productos
      </div>
    `
    this.positionDropdown()
    this.searchResultsTarget.classList.remove('hidden')
  }

  closeSearchResults() {
    this.searchResultsTarget.classList.add('hidden')
    this.searchResultsTarget.innerHTML = ''
    this.selectedIndex = -1
  }

  handleSearchKeydown(event) {
    // Enter - Seleccionar
    if (event.key === 'Enter') {
      event.preventDefault()
      
      if (!this.searchResultsTarget.classList.contains('hidden')) {
        if (this.selectedIndex >= 0 && this.searchResultsData[this.selectedIndex]) {
          this.selectProductByIndex(this.selectedIndex)
        } else if (this.searchResultsData.length === 1) {
          this.selectProductByIndex(0)
        }
      }
      return
    }
    
    // Escape - Cerrar
    if (event.key === 'Escape') {
      event.preventDefault()
      this.closeSearchResults()
      return
    }
    
    // Si el dropdown está cerrado, no procesar flechas
    if (this.searchResultsTarget.classList.contains('hidden')) return
    
    const items = this.searchResultsTarget.querySelectorAll('.search-result-item')
    
    // Flecha Abajo
    if (event.key === 'ArrowDown') {
      event.preventDefault()
      this.selectedIndex = Math.min(this.selectedIndex + 1, items.length - 1)
      this.highlightSelected(items)
      this.scrollToSelected()
    } 
    // Flecha Arriba
    else if (event.key === 'ArrowUp') {
      event.preventDefault()
      this.selectedIndex = Math.max(this.selectedIndex - 1, 0)
      this.highlightSelected(items)
      this.scrollToSelected()
    }
  }

  highlightItem(event) {
    // Highlight al pasar el mouse
    const items = this.searchResultsTarget.querySelectorAll('.search-result-item')
    const index = parseInt(event.currentTarget.dataset.index)
    this.selectedIndex = index
    this.highlightSelected(items)
  }

  highlightSelected(items) {
    items.forEach((item, index) => {
      if (index === this.selectedIndex) {
        item.classList.add('bg-green-100', 'border-l-4', 'border-green-500')
        item.classList.remove('hover:bg-green-50')
      } else {
        item.classList.remove('bg-green-100', 'border-l-4', 'border-green-500')
        item.classList.add('hover:bg-green-50')
      }
    })
  }

  scrollToSelected() {
    const items = this.searchResultsTarget.querySelectorAll('.search-result-item')
    if (this.selectedIndex >= 0 && items[this.selectedIndex]) {
      const selectedItem = items[this.selectedIndex]
      
      // Scroll suave al elemento seleccionado
      selectedItem.scrollIntoView({
        behavior: 'smooth',
        block: 'nearest'
      })
    }
  }

  selectProduct(event) {
    const index = parseInt(event.currentTarget.dataset.index)
    this.selectProductByIndex(index)
  }

  selectProductByIndex(index) {
    const product = this.searchResultsData[index]
    if (!product) return
    
    console.log('Producto seleccionado:', product.name)
    
    // Llenar campos
    this.productIdInputTarget.value = product.id
    this.productNameDisplayTarget.textContent = product.name
    
    console.log('Nombre mostrado en:', this.productNameDisplayTarget.textContent)
    
    // Llenar conversión si existe
    if (this.hasConversionInputTarget && product.unit_conversion) {
      this.conversionInputTarget.value = product.unit_conversion
    }
    
    // Limpiar búsqueda y cerrar resultados
    this.searchInputTarget.value = ''
    this.closeSearchResults()
    
    // Cambiar a vista de producto seleccionado
    this.showSelectedView()
    
    // Enfocar siguiente campo
    const row = this.element.closest('tr')
    const quantityInput = row.querySelector('input[name*="[quantity]"]')
    if (quantityInput) {
      setTimeout(() => quantityInput.focus(), 100)
    }
  }

  changeProduct() {
    console.log('Cambiar producto')
    
    // Limpiar producto
    this.productIdInputTarget.value = ''
    this.productNameDisplayTarget.textContent = ''
    
    // Cambiar a vista de búsqueda
    this.showSearchView()
    
    // Enfocar input
    setTimeout(() => this.searchInputTarget.focus(), 100)
  }

  showSearchView() {
    console.log('Mostrando vista de búsqueda')
    this.searchContainerTarget.classList.remove('hidden')
    this.selectedContainerTarget.classList.add('hidden')
  }

  showSelectedView() {
    console.log('Mostrando vista de seleccionado')
    this.searchContainerTarget.classList.add('hidden')
    this.selectedContainerTarget.classList.remove('hidden')
  }
}