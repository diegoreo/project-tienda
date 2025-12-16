import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["column", "header", "columnToggle", "dropdown"]
  
  connect() {
    console.log("Table columns controller connected")
    this.storageKey = "sales_visible_columns"
    this.loadColumnPreferences()
    
    // Cerrar con ESC
    this.handleEscape = this.handleEscape.bind(this)
    document.addEventListener('keydown', this.handleEscape)
  }
  
  disconnect() {
    document.removeEventListener('keydown', this.handleEscape)
  }
  
  // Manejar tecla ESC
  handleEscape(event) {
    if (event.key === 'Escape' && this.hasDropdownTarget) {
      this.dropdownTarget.classList.add('hidden')
    }
  }
  
  // Cargar preferencias guardadas
  loadColumnPreferences() {
    const saved = localStorage.getItem(this.storageKey)
    if (saved) {
      const preferences = JSON.parse(saved)
      this.applyColumnVisibility(preferences)
    }
  }
  
  // Aplicar visibilidad de columnas
  applyColumnVisibility(preferences) {
    this.columnTargets.forEach(column => {
      const columnName = column.dataset.column
      const isVisible = preferences[columnName] !== false // Default true
      
      column.classList.toggle('hidden', !isVisible)
      
      // Actualizar checkbox
      const checkbox = this.columnToggleTargets.find(
        toggle => toggle.dataset.column === columnName
      )
      if (checkbox) {
        checkbox.checked = isVisible
      }
    })
  }
  
  // Toggle columna
  toggleColumn(event) {
    const columnName = event.target.dataset.column
    const isVisible = event.target.checked
    
    // Actualizar visibilidad en DOM
    this.columnTargets.forEach(column => {
      if (column.dataset.column === columnName) {
        column.classList.toggle('hidden', !isVisible)
      }
    })
    
    // Guardar en localStorage
    this.saveColumnPreferences()
  }
  
  // Guardar preferencias
  saveColumnPreferences() {
    const preferences = {}
    
    this.columnToggleTargets.forEach(checkbox => {
      preferences[checkbox.dataset.column] = checkbox.checked
    })
    
    localStorage.setItem(this.storageKey, JSON.stringify(preferences))
  }
  
  // Toggle dropdown
  toggleDropdown() {
    this.dropdownTarget.classList.toggle('hidden')
  }
  
  // Cerrar dropdown al hacer click fuera
  closeDropdown(event) {
    // Solo procesar si el dropdown existe y está visible
    if (!this.hasDropdownTarget) return
    
    // Verificar si el dropdown está oculto (no hacer nada si ya está cerrado)
    if (this.dropdownTarget.classList.contains('hidden')) return
    
    // Buscar el contenedor del botón y dropdown (el div con position relative)
    const buttonContainer = this.dropdownTarget.closest('.relative')
    
    // Si el click fue dentro del botón/dropdown, no hacer nada
    if (buttonContainer && buttonContainer.contains(event.target)) return
    
    // Si el click fue fuera del botón/dropdown, cerrar
    this.dropdownTarget.classList.add('hidden')
  }
  
  // Restablecer a valores por defecto
  resetColumns() {
    const defaults = {
      folio: true,
      fecha: true,
      cliente: true,
      vendedor: true,
      caja: true,
      almacen: false,
      total: true,
      metodo: true,
      pago: true,
      estado: true,
      acciones: true
    }
    
    this.applyColumnVisibility(defaults)
    localStorage.setItem(this.storageKey, JSON.stringify(defaults))
  }
}