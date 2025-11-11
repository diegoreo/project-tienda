import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = {
    duration: { type: Number, default: 3000 } // 3 segundos por defecto
  }

  connect() {
    console.log("Success alert controller connected")
    
    // Mostrar la alerta con animación de entrada
    this.element.classList.add('animate-slide-in')
    
    // Programar desaparición automática
    this.timeout = setTimeout(() => {
      this.hide()
    }, this.durationValue)
  }

  disconnect() {
    // Limpiar timeout si se desconecta antes
    if (this.timeout) {
      clearTimeout(this.timeout)
    }
  }

  hide() {
    // Agregar animación de salida
    this.element.classList.remove('animate-slide-in')
    this.element.classList.add('animate-slide-out')
    
    // Remover el elemento después de la animación
    setTimeout(() => {
      this.element.remove()
    }, 300) // Duración de la animación de salida
  }

  // Método para cerrar manualmente si se hace click en la alerta
  dismiss() {
    if (this.timeout) {
      clearTimeout(this.timeout)
    }
    this.hide()
  }
}