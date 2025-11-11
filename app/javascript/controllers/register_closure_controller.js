import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [
    "closingBalance",
    "expectedAmount",
    "countedAmount",
    "differenceCalculator",
    "differenceValue",
    "differenceStatus",
    "differenceDisplay",
    "calcTotal",
    "calc1000",
    "calc500",
    "calc200",
    "calc100",
    "calc50",
    "calc20",
    "calcCoins"
  ]

  connect() {
    console.log("Register closure controller connected")
  }

  // Calcular diferencia en tiempo real
  calculateDifference() {
    const counted = parseFloat(this.closingBalanceTarget.value) || 0
    const expected = parseFloat(this.expectedAmountTarget.textContent.replace(/,/g, ''))
    const difference = counted - expected

    if (counted > 0) {
      this.differenceCalculatorTarget.classList.remove('hidden')
      this.countedAmountTarget.textContent = counted.toFixed(2)

      if (Math.abs(difference) < 0.01) {
        // Cuadrado
        this.differenceValueTarget.textContent = '$0.00 ✓'
        this.differenceStatusTarget.textContent = '¡Perfecto! El efectivo cuadra exactamente'
        this.differenceDisplayTarget.className = 'rounded-lg p-4 text-center bg-green-100 border-2 border-green-500'
        this.differenceValueTarget.className = 'text-3xl font-black text-green-700'
        this.differenceStatusTarget.className = 'text-sm mt-1 text-green-700 font-semibold'
      } else if (difference > 0) {
        // Sobrante
        this.differenceValueTarget.textContent = '+$' + Math.abs(difference).toFixed(2)
        this.differenceStatusTarget.textContent = 'Sobrante - Hay más efectivo del esperado'
        this.differenceDisplayTarget.className = 'rounded-lg p-4 text-center bg-blue-100 border-2 border-blue-500'
        this.differenceValueTarget.className = 'text-3xl font-black text-blue-700'
        this.differenceStatusTarget.className = 'text-sm mt-1 text-blue-700 font-semibold'
      } else {
        // Faltante
        this.differenceValueTarget.textContent = '-$' + Math.abs(difference).toFixed(2)
        this.differenceStatusTarget.textContent = '⚠️ Faltante - Falta efectivo'
        this.differenceDisplayTarget.className = 'rounded-lg p-4 text-center bg-red-100 border-2 border-red-500'
        this.differenceValueTarget.className = 'text-3xl font-black text-red-700'
        this.differenceStatusTarget.className = 'text-sm mt-1 text-red-700 font-semibold'
      }
    } else {
      this.differenceCalculatorTarget.classList.add('hidden')
    }
  }

  // Actualizar calculadora rápida
  updateQuickCalculator() {
    let total = 0

    if (this.hasCalc1000Target) total += (parseFloat(this.calc1000Target.value) || 0) * 1000
    if (this.hasCalc500Target) total += (parseFloat(this.calc500Target.value) || 0) * 500
    if (this.hasCalc200Target) total += (parseFloat(this.calc200Target.value) || 0) * 200
    if (this.hasCalc100Target) total += (parseFloat(this.calc100Target.value) || 0) * 100
    if (this.hasCalc50Target) total += (parseFloat(this.calc50Target.value) || 0) * 50
    if (this.hasCalc20Target) total += (parseFloat(this.calc20Target.value) || 0) * 20
    if (this.hasCalcCoinsTarget) total += parseFloat(this.calcCoinsTarget.value) || 0

    this.calcTotalTarget.textContent = '$' + total.toFixed(2)
  }

  // Usar el total de la calculadora rápida
  useCalculatedTotal() {
    const total = this.calcTotalTarget.textContent.replace('$', '').replace(/,/g, '')
    this.closingBalanceTarget.value = total
    this.calculateDifference()
    this.closingBalanceTarget.focus()
  }
}