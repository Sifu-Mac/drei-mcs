import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="inline-add"
// Handles Trello-style inline card creation
export default class extends Controller {
  static targets = ["form", "button", "input", "submit", "error"]
  static values = {
    columnId: String,
    url: String
  }

  connect() {
    this.handleClickOutside = this.handleClickOutside.bind(this)
  }

  disconnect() {
    document.removeEventListener("click", this.handleClickOutside)
  }

  show() {
    this.buttonTarget.classList.add("hidden")
    this.formTarget.classList.remove("hidden")
    this.inputTarget.focus()
    this.clearError()
    // Add click outside listener after a brief delay to avoid immediate trigger
    setTimeout(() => {
      document.addEventListener("click", this.handleClickOutside)
    }, 0)
  }

  cancel() {
    this.formTarget.classList.add("hidden")
    this.buttonTarget.classList.remove("hidden")
    this.inputTarget.value = ""
    this.clearError()
    document.removeEventListener("click", this.handleClickOutside)
  }

  handleClickOutside(event) {
    // If click is outside the form, cancel
    if (!this.formTarget.contains(event.target)) {
      this.cancel()
    }
  }

  handleKeydown(event) {
    this.clearError()

    if (event.key === "Enter" && !event.shiftKey) {
      event.preventDefault()
      this.submit()
    } else if (event.key === "Escape") {
      this.cancel()
    }
  }

  async submit() {
    const title = this.inputTarget.value.trim()
    if (!title) {
      this.showError()
      return
    }

    try {
      const response = await fetch(this.urlValue, {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "Accept": "text/vnd.turbo-stream.html",
          "X-CSRF-Token": this.csrfToken
        },
        body: JSON.stringify({
          task: {
            title: title,
            board_column_id: this.columnIdValue
          }
        })
      })

      if (response.ok) {
        // Process turbo stream response to add the card and update counts
        const html = await response.text()
        Turbo.renderStreamMessage(html)

        // Clear input but keep form open for rapid entry
        this.inputTarget.value = ""
        this.inputTarget.focus()
      } else {
        this.showError("Karte konnte nicht erstellt werden.")
      }
    } catch (error) {
      console.error("Error creating task:", error)
      this.showError("Karte konnte nicht erstellt werden.")
    }
  }

  clearError() {
    if (!this.hasErrorTarget) return

    this.errorTarget.textContent = ""
    this.errorTarget.classList.add("hidden")
    this.inputTarget.removeAttribute("aria-invalid")
  }

  showError(message = "Bitte einen Kartentitel eingeben.") {
    if (!this.hasErrorTarget) return

    this.errorTarget.textContent = message
    this.errorTarget.classList.remove("hidden")
    this.inputTarget.setAttribute("aria-invalid", "true")
    this.inputTarget.focus()
  }

  get csrfToken() {
    return document.querySelector("[name='csrf-token']").content
  }
}
