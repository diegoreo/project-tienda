import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["duration"]
  static values = { openedAt: String }

  connect() {
    console.log("Session timer controller connected")
    this.updateDuration()
    this.interval = setInterval(() => this.updateDuration(), 60000) // Cada minuto
  }

  disconnect() {
    if (this.interval) {
      clearInterval(this.interval)
    }
  }

  updateDuration() {
    if (!this.hasOpenedAtValue) return

    const openedAt = new Date(this.openedAtValue)
    const now = new Date()
    const diff = now - openedAt

    const hours = Math.floor(diff / (1000 * 60 * 60))
    const minutes = Math.floor((diff % (1000 * 60 * 60)) / (1000 * 60))

    this.durationTarget.textContent = `${hours}h ${minutes}m`
  }
}