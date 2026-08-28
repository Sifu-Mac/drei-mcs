import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["button", "input"]

  select(event) {
    const button = event.currentTarget

    this.inputTarget.value = button.dataset.icon
    this.buttonTargets.forEach((iconButton) => {
      iconButton.classList.remove("ring-2", "ring-accent")
    })
    button.classList.add("ring-2", "ring-accent")
  }
}
