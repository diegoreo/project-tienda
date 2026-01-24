import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["currentQuantity", "quantityInput", "finalQuantity"]

  connect() {
    this.recalculate()
  }

  recalculate() {
    // Leer stock actual (ya viene en unidades correctas desde la vista)
    const current = parseFloat(this.currentQuantityTarget.textContent.replace(/,/g, '')) || 0
    
    // Leer ajuste (en unidades de presentación o producto)
    const adjust = parseFloat(this.quantityInputTarget.value) || 0
    
    // Tipo de ajuste
    const type = this.element.querySelector("select").value

    // Calcular final (TODO en las mismas unidades)
    let final = current
    if (type === "increase") {
      final = current + adjust
    } else if (type === "decrease") {
      final = current - adjust
    }

    // Mostrar resultado formateado
    this.finalQuantityTarget.textContent = Number(final.toFixed(3)).toLocaleString('en-US', { 
      minimumFractionDigits: 0, 
      maximumFractionDigits: 3 
    })
  }
}