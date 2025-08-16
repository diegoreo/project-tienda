import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["container"]

  add(event) {
    event.preventDefault()
    // Clonamos el template
    const template = document.getElementById("barcode-template").content.cloneNode(true)
    // Reemplazamos "NEW_RECORD" por un timestamp único
    const html = template.firstElementChild.outerHTML.replace(/NEW_RECORD/g, new Date().getTime())
    // Insertamos el nuevo campo
    this.containerTarget.insertAdjacentHTML("beforeend", html)
  }

  remove(event) {
    event.preventDefault()
    const field = event.target.closest(".barcode-field")

    if (field.dataset.newRecord === "true") {
      field.remove()
    } else {
      field.querySelector('input[name*="_destroy"]').value = "1"
      field.style.display = "none"
    }
  }
}
