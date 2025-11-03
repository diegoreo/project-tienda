import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    // Auto-dismiss después de 5 segundos
    this.timeout = setTimeout(() => {
      this.dismiss()
    }, 5000)
  }

  disconnect() {
    // Limpiar timeout si el elemento se elimina manualmente antes
    clearTimeout(this.timeout)
  }

  dismiss() {
    // Agregar animación de salida
    this.element.classList.add('animate-slide-out')
    
    // Esperar a que termine la animación antes de eliminar el elemento
    setTimeout(() => {
      this.element.remove()
    }, 300)
  }
}