import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [
    "typeSelect",
    "baseHelp",
    "masterHelp", 
    "presentationHelp",
    "presentationFields"
  ]

  connect() {
    // Ejecutar al cargar la página para mostrar campos correctos
    this.toggleFields()
  }

  toggleFields() {
    const selectedType = this.typeSelectTarget.value
    
    // Ocultar todas las ayudas
    this.baseHelpTarget.classList.add("hidden")
    this.masterHelpTarget.classList.add("hidden")
    this.presentationHelpTarget.classList.add("hidden")
    
    // Ocultar campos de presentación
    this.presentationFieldsTarget.classList.add("hidden")
    
    // Mostrar según el tipo seleccionado
    switch(selectedType) {
      case "base":
        this.baseHelpTarget.classList.remove("hidden")
        break
        
      case "master":
        this.masterHelpTarget.classList.remove("hidden")
        break
        
      case "presentation":
        this.presentationHelpTarget.classList.remove("hidden")
        this.presentationFieldsTarget.classList.remove("hidden")
        break
    }
  }
}