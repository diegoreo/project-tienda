import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["currentQuantity", "quantityInput", "finalQuantity"]

  connect() {
    this.recalculate()
  }

  recalculate() {
    const current = parseFloat(this.currentQuantityTarget.textContent) || 0
    const adjust = parseFloat(this.quantityInputTarget.value) || 0
    const type = this.element.querySelector("select").value

    let final = current
    if (type === "increase") {
      final = current + adjust
    } else if (type === "decrease") {
      final = current - adjust
    }

    this.finalQuantityTarget.textContent = final.toFixed(3)
  }
}
