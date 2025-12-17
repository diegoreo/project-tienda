import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["filtersSection", "buttonText", "arrow"]
  
  connect() {
    console.log("Table filters controller connected")
    
    // Detectar página actual desde data-page attribute
    const page = this.element.dataset.page || 'default'
    this.storageKey = `${page}_filters_visible`
    
    console.log(`Storage key: ${this.storageKey}`)
    
    this.loadFilterPreference()
    
    // Cerrar con ESC
    this.handleEscape = this.handleEscape.bind(this)
    document.addEventListener('keydown', this.handleEscape)
  }
  
  // Cargar preferencia guardada
  loadFilterPreference() {
    const isVisible = localStorage.getItem(this.storageKey)
    
    // Por defecto visible (null = primera vez)
    if (isVisible === null || isVisible === "true") {
      this.showFilters()
    } else {
      this.hideFilters()
    }
  }
  
  // Toggle filtros
  toggleFilters() {
    if (this.filtersSectionTarget.classList.contains('hidden')) {
      this.showFilters()
      localStorage.setItem(this.storageKey, "true")
    } else {
      this.hideFilters()
      localStorage.setItem(this.storageKey, "false")
    }
  }
  
  // Mostrar filtros
  showFilters() {
    this.filtersSectionTarget.classList.remove('hidden')
    this.buttonTextTarget.textContent = '🔍 Filtros'
    this.arrowTarget.style.transform = 'rotate(0deg)'
    
    // Cambiar color del botón a verde (activo)
    const button = this.element.querySelector('[data-action*="toggleFilters"]')
    button.classList.remove('bg-gray-100', 'text-gray-700')
    button.classList.add('bg-green-100', 'text-green-700')
  }
  
  // Ocultar filtros
  hideFilters() {
    this.filtersSectionTarget.classList.add('hidden')
    this.buttonTextTarget.textContent = '🔍 Filtros'
    this.arrowTarget.style.transform = 'rotate(-90deg)'
    
    // Cambiar color del botón a gris (inactivo)
    const button = this.element.querySelector('[data-action*="toggleFilters"]')
    button.classList.remove('bg-green-100', 'text-green-700')
    button.classList.add('bg-gray-100', 'text-gray-700')
  }

  // Manejar tecla ESC
  handleEscape(event) {
    if (event.key === 'Escape') {
      // Si los filtros están visibles, ocultarlos
      if (this.hasFiltersSectionTarget && !this.filtersSectionTarget.classList.contains('hidden')) {
        this.hideFilters()
        localStorage.setItem(this.storageKey, "false")
      }
    }
  }
  
  // Limpiar event listener al desconectar
  disconnect() {
    document.removeEventListener('keydown', this.handleEscape)
  }
}