import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["items"]

  connect() {
    console.log("Purchase items controller connected")
    this.index = this.itemsTarget.querySelectorAll(".purchase-item-fields").length
    
    // Inicializar valores existentes al cargar (para edit)
    this.initializeExistingRows()
  }

  initializeExistingRows() {
    const rows = this.itemsTarget.querySelectorAll(".purchase-item-fields")
    rows.forEach(row => {
      // Leer valores de los campos hidden
      const subtotalInput = row.querySelector("input[name*='[subtotal]']")
      const costInput = row.querySelector("input[name*='[cost_per_piece]']")
      
      if (subtotalInput && subtotalInput.value) {
        const subtotalCell = row.querySelector("[data-purchase-item-target='subtotal']")
        if (subtotalCell) {
          subtotalCell.childNodes[0].textContent = this.formatCurrency(parseFloat(subtotalInput.value))
        }
      }
      
      if (costInput && costInput.value) {
        const costCell = row.querySelector("[data-purchase-item-target='costPerPiece']")
        if (costCell) {
          costCell.childNodes[0].textContent = this.formatCurrency(parseFloat(costInput.value))
        }
      }
    })
    
    // Calcular total inicial
    this.updateTotal()
  }

  addItem(event) {
    event.preventDefault()
    const template = document.querySelector("#purchase-item-template")
    if (!template) return
    
    const clone = template.content.cloneNode(true)
    const html = clone.querySelector("tr").outerHTML.replace(/NEW_RECORD/g, this.index)
    
    this.itemsTarget.insertAdjacentHTML("beforeend", html)
    this.index++
  }

  removeItem(event) {
    event.preventDefault()
    const item = event.target.closest(".purchase-item-fields")
    
    if (item.dataset.newRecord === "true") {
      item.remove()
    } else {
      const destroyInput = item.querySelector("input[name*='_destroy']")
      if (destroyInput) destroyInput.value = "1"
      item.style.display = "none"
    }
    
    this.updateTotal()
  }

  updateSubtotal(event) {
    const row = event.target.closest(".purchase-item-fields")
    const quantity = parseFloat(row.querySelector("input[name*='[quantity]']").value) || 0
    const price = parseFloat(row.querySelector("input[name*='[purchase_price]']").value) || 0
    const conversion = parseFloat(row.querySelector("input[name*='[conversion_factor]']").value) || 1

    const subtotal = quantity * price
    const costPerPiece = conversion > 0 ? price / conversion : price

    // Actualizar display (texto visible)
    const subtotalCell = row.querySelector("[data-purchase-item-target='subtotal']")
    const costCell = row.querySelector("[data-purchase-item-target='costPerPiece']")
    
    if (subtotalCell) {
      subtotalCell.childNodes[0].textContent = this.formatCurrency(subtotal)
    }
    if (costCell) {
      costCell.childNodes[0].textContent = this.formatCurrency(costPerPiece)
    }

    // Actualizar campos hidden para enviar al servidor
    const subtotalInput = row.querySelector("input[name*='[subtotal]']")
    const costInput = row.querySelector("input[name*='[cost_per_piece]']")
    
    if (subtotalInput) subtotalInput.value = subtotal.toFixed(2)
    if (costInput) costInput.value = costPerPiece.toFixed(4)

    this.updateTotal()
  }

  updateTotal() {
    let total = 0
    
    // Sumar todos los campos hidden de subtotal
    const subtotalInputs = this.element.querySelectorAll("input[name*='[subtotal]']")
    
    subtotalInputs.forEach(input => {
      const row = input.closest(".purchase-item-fields")
      // Solo sumar si la fila no está marcada para eliminar
      if (row && row.style.display !== "none") {
        total += parseFloat(input.value) || 0
      }
    })
    
    const totalElement = document.getElementById("purchase-total")
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
}