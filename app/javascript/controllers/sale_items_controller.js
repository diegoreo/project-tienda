import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["items"]

  connect() {
    this.index = this.itemsTarget.querySelectorAll(".sale-item-fields").length
    this.productPrices = this.loadProductPrices()
  }

  loadProductPrices() {
    // Cargar precios de productos desde data attributes o API
    const prices = {}
    // Por ahora usaremos un enfoque simple con fetch
    return prices
  }

  addItem(event) {
    event.preventDefault()
    const template = document.querySelector("#sale-item-template")
    if (!template) return
    
    const clone = template.content.cloneNode(true)
    const html = clone.querySelector("tr").outerHTML.replace(/NEW_RECORD/g, this.index)
    
    this.itemsTarget.insertAdjacentHTML("beforeend", html)
    this.index++
  }

  removeItem(event) {
    event.preventDefault()
    const item = event.target.closest(".sale-item-fields")
    
    if (item.dataset.newRecord === "true") {
      item.remove()
    } else {
      const destroyInput = item.querySelector("input[name*='_destroy']")
      if (destroyInput) destroyInput.value = "1"
      item.style.display = "none"
    }
    
    this.updateTotal()
  }

  async loadProductPrice(event) {
    const productId = event.target.value
    if (!productId) return
    
    const row = event.target.closest(".sale-item-fields")
    const priceField = row.querySelector("input[name*='[unit_price]']")
    
    try {
      const response = await fetch(`/products/${productId}.json`)
      const product = await response.json()
      
      if (product.price) {
        priceField.value = parseFloat(product.price).toFixed(2)
        this.updateSubtotal({ target: priceField })
      }
    } catch (error) {
      console.error("Error cargando precio:", error)
    }
  }

  updateSubtotal(event) {
    const row = event.target.closest(".sale-item-fields")
    const quantity = parseFloat(row.querySelector("input[name*='[quantity]']").value) || 0
    const unitPrice = parseFloat(row.querySelector("input[name*='[unit_price]']").value) || 0
    const discount = parseFloat(row.querySelector("input[name*='[discount]']").value) || 0

    const subtotal = (quantity * unitPrice) - discount
    
    const subtotalCell = row.querySelector("[data-sale-item-target='subtotal']")
    const subtotalInput = row.querySelector("input[name*='[subtotal]']")
    
    if (subtotalCell) {
      subtotalCell.childNodes[0].textContent = this.formatCurrency(subtotal)
    }
    if (subtotalInput) {
      subtotalInput.value = subtotal.toFixed(2)
    }

    this.updateTotal()
  }

  updateTotal() {
    let total = 0
    const subtotalInputs = this.element.querySelectorAll("input[name*='[subtotal]']")
    
    subtotalInputs.forEach(input => {
      const row = input.closest(".sale-item-fields")
      if (row && row.style.display !== "none") {
        total += parseFloat(input.value) || 0
      }
    })
    
    const totalElement = document.getElementById("sale-total")
    if (totalElement) {
      totalElement.textContent = this.formatCurrency(total)
    }
  }

  formatCurrency(value) {
    return new Intl.NumberFormat("es-MX", {
      style: "currency",
      currency: "MXN",
      minimumFractionDigits: 2
    }).format(value)
  }

  checkPaymentMethod(event) {
    const method = event.target.value
    
    if (method === 'credit') {
      alert('Para ventas a crédito debe seleccionar un cliente con límite de crédito.')
    }
  }

  checkCreditLimit(event) {
    // Validar límite de crédito del cliente
  }
}