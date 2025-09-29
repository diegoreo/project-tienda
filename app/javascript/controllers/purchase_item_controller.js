import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["subtotal"]

  updateSubtotal() {
    const row = this.element
    const quantity = parseFloat(row.querySelector("input[name*='[quantity]']").value) || 0
    const unitCost = parseFloat(row.querySelector("input[name*='[unit_cost]']").value) || 0
    const subtotal = quantity * unitCost

    this.subtotalTarget.textContent = this.formatCurrency(subtotal)

    this.updateTotal()
  }

  updateTotal() {
    const allSubtotals = document.querySelectorAll("[data-purchase-item-target='subtotal']")
    let total = 0
    allSubtotals.forEach(cell => {
      total += this.parseCurrency(cell.textContent)
    })
    document.getElementById("purchase-total").textContent = this.formatCurrency(total)
  }

  formatCurrency(value) {
    return new Intl.NumberFormat("es-MX", {
      style: "currency",
      currency: "MXN",
      minimumFractionDigits: 2
    }).format(value)
  }

  parseCurrency(value) {
    // Elimina todo excepto números, punto y guion
    return parseFloat(value.replace(/[^0-9.-]+/g, "")) || 0
  }
}
