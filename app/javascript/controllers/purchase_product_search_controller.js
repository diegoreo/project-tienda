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
    
    // Cerrar dropdown al hacer scroll o click fuera
    this.boundCloseOnScroll = this.closeSearchResults.bind(this)
    window.addEventListener('scroll', this.boundCloseOnScroll, true)
  }

  disconnect() {
    window.removeEventListener('scroll', this.boundCloseOnScroll, true)
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
      <div class="px-4 py-3 cursor-pointer border-b border-gray-200 last:border-b-0 hover:bg-green-50 transition duration-150" 
           data-index="${index}" 
           data-action="click->purchase-product-search#selectProduct">
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
    
    // Posicionar el dropdown con fixed
    this.positionDropdown()
    
    this.searchResultsTarget.classList.remove('hidden')
  }

  positionDropdown() {
    const inputRect = this.searchInputTarget.getBoundingClientRect()
    
    // Usar fixed positioning
    this.searchResultsTarget.style.position = 'fixed'
    this.searchResultsTarget.style.top = `${inputRect.bottom + 4}px`
    this.searchResultsTarget.style.left = `${inputRect.left}px`
    this.searchResultsTarget.style.width = `${inputRect.width}px`
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
    
    if (this.searchResultsTarget.classList.contains('hidden')) return
    
    const items = this.searchResultsTarget.querySelectorAll('[data-index]')
    
    if (event.key === 'ArrowDown') {
      event.preventDefault()
      this.selectedIndex = Math.min(this.selectedIndex + 1, items.length - 1)
      this.highlightSelected(items)
    } else if (event.key === 'ArrowUp') {
      event.preventDefault()
      this.selectedIndex = Math.max(this.selectedIndex - 1, 0)
      this.highlightSelected(items)
    } else if (event.key === 'Escape') {
      event.preventDefault()
      this.closeSearchResults()
    }
  }

  highlightSelected(items) {
    items.forEach((item, index) => {
      if (index === this.selectedIndex) {
        item.classList.add('bg-blue-50', 'border-l-4', 'border-blue-500')
      } else {
        item.classList.remove('bg-blue-50', 'border-l-4', 'border-blue-500')
      }
    })
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