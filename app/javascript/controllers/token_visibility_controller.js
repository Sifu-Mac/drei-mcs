import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["value", "button"]
  static values = { token: String }

  connect() {
    this.visible = false
    this.render()
  }

  toggle() {
    this.visible = !this.visible
    this.render()
  }

  render() {
    this.valueTarget.textContent = this.visible ? this.tokenValue : "••••••••••••••••••••••••••••••••"
    this.buttonTarget.textContent = this.visible ? "Verbergen" : "Anzeigen"
    this.buttonTarget.setAttribute("aria-pressed", this.visible.toString())
  }
}
