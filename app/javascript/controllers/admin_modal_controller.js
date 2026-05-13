import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["backdrop", "modal"]

  connect() {
    this.boundHandleKeydown = this.handleKeydown.bind(this)
    document.addEventListener("keydown", this.boundHandleKeydown)

    setTimeout(() => {
      this.backdropTarget.classList.remove("hidden", "opacity-0")
      this.modalTarget.classList.remove("hidden", "opacity-0", "scale-95")
    }, 10)
  }

  disconnect() {
    document.removeEventListener("keydown", this.boundHandleKeydown)
  }

  close(event) {
    if (event) event.preventDefault()

    this.backdropTarget.classList.add("opacity-0")
    this.modalTarget.classList.add("opacity-0", "scale-95")

    setTimeout(() => {
      const frame = document.getElementById("admin_panel")
      if (frame) frame.innerHTML = ""
    }, 180)
  }

  handleKeydown(event) {
    if (event.key === "Escape") this.close()
  }
}
