import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [
    "modal",
    "modalTitle",
    "modalIcon",
    "movementType",
    "amount",
    "description",
    "authorizerSelect",
    "password",
    "errorMessage",
    "submitButton"
  ]

  connect() {
    console.log("QuickFlow controller conectado")
  }

  // Abrir modal para EGRESO
  openEgreso(event) {
    event.preventDefault()
    this.openModal("outflow", "💸 Nuevo Egreso", "Retiro de efectivo de caja")
  }

  // Abrir modal para INGRESO
  openIngreso(event) {
    event.preventDefault()
    this.openModal("inflow", "💵 Nuevo Ingreso", "Depósito de efectivo en caja")
  }

  // Abrir modal genérico
  openModal(type, title, placeholder) {
    // Resetear formulario
    this.resetForm()
    
    // Configurar tipo de movimiento
    this.movementTypeTarget.value = type
    this.modalTitleTarget.textContent = title
    this.descriptionTarget.placeholder = placeholder
    
    // Cambiar icono según tipo
    if (type === "outflow") {
      this.modalIconTarget.textContent = "💸"
      this.modalIconTarget.className = "text-5xl"
    } else {
      this.modalIconTarget.textContent = "💵"
      this.modalIconTarget.className = "text-5xl"
    }
    
    // Mostrar modal
    this.modalTarget.classList.remove("hidden")
    
    // Focus en monto
    setTimeout(() => this.amountTarget.focus(), 100)
  }

  // Cerrar modal
  closeModal(event) {
    if (event) event.preventDefault()
    this.modalTarget.classList.add("hidden")
    this.resetForm()
  }

  // Cerrar con ESC
  handleKeydown(event) {
    if (event.key === "Escape") {
      this.closeModal()
    }
  }

  // Cerrar al hacer click fuera del modal
  closeOnBackdrop(event) {
    if (event.target === this.modalTarget) {
      this.closeModal()
    }
  }

  // Submit del formulario
  async submit(event) {
    event.preventDefault()
    
    // Validar campos
    if (!this.validateForm()) {
      return
    }
    
    // Deshabilitar botón
    this.submitButtonTarget.disabled = true
    this.submitButtonTarget.textContent = "Autorizando..."
    
    // Preparar datos
    const formData = new FormData()
    formData.append("movement_type", this.movementTypeTarget.value)
    formData.append("amount", this.amountTarget.value)
    formData.append("description", this.descriptionTarget.value)
    formData.append("authorized_by_id", this.authorizerSelectTarget.value)
    formData.append("password", this.passwordTarget.value)
    
    try {
      // Obtener CSRF token
      const csrfToken = document.querySelector("[name='csrf-token']").content
      
      // Obtener session_id desde la URL o un data attribute
      const sessionId = this.getCurrentSessionId()
      
      // Hacer petición
      const response = await fetch(`/register_sessions/${sessionId}/flows/quick_create`, {
        method: "POST",
        headers: {
          "X-CSRF-Token": csrfToken,
          "Accept": "application/json"
        },
        body: formData
      })
      
      const data = await response.json()
      
      if (response.ok) {
        // Éxito
        this.showSuccess(data.message)
        this.closeModal()
      } else {
        // Error
        this.showError(data.error || "Error al crear el movimiento")
        this.submitButtonTarget.disabled = false
        this.submitButtonTarget.textContent = "✅ Autorizar y Registrar"
      }
      
    } catch (error) {
      console.error("Error:", error)
      this.showError("Error de conexión. Intenta de nuevo.")
      this.submitButtonTarget.disabled = false
      this.submitButtonTarget.textContent = "✅ Autorizar y Registrar"
    }
  }

  // Validar formulario
  validateForm() {
    // Limpiar errores previos
    this.hideError()
    
    // Validar monto
    const amount = parseFloat(this.amountTarget.value)
    if (!amount || amount <= 0) {
      this.showError("El monto debe ser mayor a $0")
      this.amountTarget.focus()
      return false
    }
    
    // Validar descripción
    if (this.descriptionTarget.value.trim().length < 5) {
      this.showError("La descripción debe tener al menos 5 caracteres")
      this.descriptionTarget.focus()
      return false
    }
    
    // Validar autorizador
    if (!this.authorizerSelectTarget.value) {
      this.showError("Selecciona quién autoriza el movimiento")
      this.authorizerSelectTarget.focus()
      return false
    }
    
    // Validar contraseña
    if (this.passwordTarget.value.length < 1) {
      this.showError("Ingresa la contraseña del autorizador")
      this.passwordTarget.focus()
      return false
    }
    
    return true
  }

  // Mostrar error
  showError(message) {
    this.errorMessageTarget.textContent = message
    this.errorMessageTarget.classList.remove("hidden")
  }

  // Ocultar error
  hideError() {
    this.errorMessageTarget.classList.add("hidden")
  }

  // Mostrar éxito
  showSuccess(message) {
    // Crear notificación de éxito
    const notification = document.createElement("div")
    notification.className = "fixed top-4 right-4 bg-green-500 text-white px-6 py-3 rounded-lg shadow-xl z-50 flex items-center gap-2"
    notification.innerHTML = `
      <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7"/>
      </svg>
      <span>${message}</span>
    `
    
    document.body.appendChild(notification)
    
    // Remover después de 3 segundos
    setTimeout(() => {
      notification.remove()
    }, 3000)
  }

  // Resetear formulario
  resetForm() {
    this.amountTarget.value = ""
    this.descriptionTarget.value = ""
    this.authorizerSelectTarget.selectedIndex = 0
    this.passwordTarget.value = ""
    this.hideError()
    this.submitButtonTarget.disabled = false
    this.submitButtonTarget.textContent = "✅ Autorizar y Registrar"
  }

  // Obtener session_id actual
  getCurrentSessionId() {
    // Buscar en data attribute del elemento del controller
    return this.element.dataset.sessionId
  }
}