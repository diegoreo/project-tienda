import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["container"]

  add(event) {
    event.preventDefault()
    
    const template = document.getElementById("barcode-template").content.cloneNode(true)
    const timestamp = new Date().getTime()
    
    const html = template.firstElementChild.outerHTML.replace(/NEW_RECORD/g, timestamp)
    
    this.containerTarget.insertAdjacentHTML("beforeend", html)
  }

  remove(event) {
    event.preventDefault()
    
    const field = event.target.closest(".barcode-field")
    
    if (!field) {
      console.error("❌ No se encontró .barcode-field")
      return
    }

    console.log("✅ Campo encontrado:", field)
    console.log("📋 data-new-record:", field.dataset.newRecord)

    // Si es un registro nuevo (no guardado en BD), eliminarlo del DOM
    if (field.dataset.newRecord === "true") {
      console.log("🗑️ Eliminando registro nuevo")
      field.remove()
    } else {
      console.log("🏷️ Marcando registro existente para destruir")
      const destroyInput = field.querySelector('input[name*="_destroy"]')
      
      if (destroyInput) {
        destroyInput.value = "1"
        field.style.display = "none"
        console.log("✅ Marcado para destruir")
      } else {
        console.error("❌ No se encontró input _destroy")
      }
    }
  }
}