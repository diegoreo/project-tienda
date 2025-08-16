import { Controller } from "@hotwired/stimulus"

// Conecta con data-controller="conversion"
export default class extends Controller {
  static targets = [
    "stockQuantity", 
    "unitConversion", 
    "result", 
    "purchaseUnitSelect", 
    "stockLabel"
  ]

  connect() {
    this.updateStockLabel()
    this.calculate()
  }

  updateStockLabel() {
    const selectedOption = this.purchaseUnitSelectTarget.selectedOptions[0]
    const unitName = selectedOption ? selectedOption.textContent.trim() : "unidad"
    this.stockLabelTarget.textContent = `Inventario inicial (en: ${unitName})`
  }

  calculate() {
    const stock = parseFloat(this.stockQuantityTarget.value) || 0
    const conversion = parseFloat(this.unitConversionTarget.value) || 0

    if (stock > 0 && conversion > 0) {
      const total = stock * conversion
      this.resultTarget.textContent = `= ${total} unidades de venta`
    } else {
      this.resultTarget.textContent = "Ingresa cantidad y conversión"
    }
  }
}
