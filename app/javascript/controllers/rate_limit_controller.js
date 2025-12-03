import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["loginField", "submitBtn", "message", "countdown"]
  
  connect() {
    console.log("Rate limit controller connected")
    this.retryAfter = 0
    this.countdownInterval = null
    this.blockedEmail = null
    
    // Verificar localStorage al cargar
    this.checkLocalStorage()
    
    // Escuchar cambios en el campo de email
    this.loginFieldTarget.addEventListener('change', () => this.checkEmailBlocked())
    this.loginFieldTarget.addEventListener('input', () => this.checkEmailBlocked())
    
    // Interceptar el submit
    this.element.addEventListener('submit', this.handleSubmit.bind(this))
  }
  
  disconnect() {
    if (this.countdownInterval) {
      clearInterval(this.countdownInterval)
    }
  }
  
  checkLocalStorage() {
    // Buscar todos los emails bloqueados en localStorage
    for (let i = 0; i < localStorage.length; i++) {
      const key = localStorage.key(i)
      if (key.startsWith('rateLimit_')) {
        const email = key.replace('rateLimit_', '')
        const data = JSON.parse(localStorage.getItem(key))
        
        // Calcular tiempo restante
        const elapsed = Math.floor((Date.now() - data.blockedAt) / 1000)
        const remaining = data.retryAfter - elapsed
        
        if (remaining <= 0) {
          // Expiró, eliminar
          localStorage.removeItem(key)
        } else {
          // Verificar si es el email actual
          const currentEmail = this.loginFieldTarget.value.toLowerCase().trim()
          if (currentEmail === email.toLowerCase()) {
            this.showBlockedMessage(remaining, email)
          }
        }
      }
    }
  }
  
  checkEmailBlocked() {
    const email = this.loginFieldTarget.value.toLowerCase().trim()
    
    if (!email) {
      this.hideMessage()
      return
    }
    
    // Buscar en localStorage
    const key = `rateLimit_${email}`
    const data = localStorage.getItem(key)
    
    if (data) {
      const blockData = JSON.parse(data)
      const elapsed = Math.floor((Date.now() - blockData.blockedAt) / 1000)
      const remaining = blockData.retryAfter - elapsed
      
      if (remaining > 0) {
        this.showBlockedMessage(remaining, email)
      } else {
        // Expiró
        localStorage.removeItem(key)
        this.hideMessage()
      }
    } else {
      this.hideMessage()
    }
  }
  
  handleSubmit(event) {
    // Si está bloqueado, prevenir submit
    if (this.retryAfter > 0) {
      event.preventDefault()
      event.stopPropagation()
      return false
    }
  }
  
  showBlockedMessage(seconds, email) {
    this.retryAfter = seconds
    this.blockedEmail = email
    this.messageTarget.classList.remove('hidden')
    this.submitBtnTarget.disabled = true
    
    // Iniciar cuenta regresiva
    if (this.countdownInterval) clearInterval(this.countdownInterval)
    this.updateCountdown()
    this.countdownInterval = setInterval(() => this.updateCountdown(), 1000)
  }
  
  hideMessage() {
    this.messageTarget.classList.add('hidden')
    this.submitBtnTarget.disabled = false
    if (this.countdownInterval) {
      clearInterval(this.countdownInterval)
      this.countdownInterval = null
    }
    this.retryAfter = 0
    this.blockedEmail = null
  }
  
  updateCountdown() {
    if (this.retryAfter <= 0) {
      // Limpiar localStorage
      if (this.blockedEmail) {
        localStorage.removeItem(`rateLimit_${this.blockedEmail}`)
      }
      this.hideMessage()
      return
    }
    
    const minutes = Math.floor(this.retryAfter / 60)
    const seconds = this.retryAfter % 60
    this.countdownTarget.textContent = `${minutes}:${seconds.toString().padStart(2, '0')}`
    this.retryAfter--
  }
}