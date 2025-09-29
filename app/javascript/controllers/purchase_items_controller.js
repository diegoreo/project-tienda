import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["items"]

  connect() {
    this.index = this.itemsTarget.querySelectorAll(".purchase-item-fields").length
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
      if (destroyInput) {
        destroyInput.value = "1"
      }
      item.style.display = "none"
    }
  }
}