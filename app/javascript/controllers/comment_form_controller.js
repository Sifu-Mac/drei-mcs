import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="comment-form"
export default class extends Controller {
  static targets = ["input", "submit", "quoteId", "quotePreview", "quoteAuthor", "quoteBody"]

  connect() {
    this.autoResize()
  }

  selectQuote(event) {
    const { commentId, author, body } = event.detail
    this.quoteIdTarget.value = commentId
    this.quoteAuthorTarget.textContent = author
    this.quoteBodyTarget.textContent = body
    this.quotePreviewTarget.hidden = false
    this.inputTarget.focus()
  }

  clearQuote() {
    this.quoteIdTarget.value = ""
    this.quotePreviewTarget.hidden = true
    this.quoteAuthorTarget.textContent = ""
    this.quoteBodyTarget.textContent = ""
  }

  submitOnEnter(event) {
    // Submit on Enter without Shift
    if (event.key === "Enter" && !event.shiftKey) {
      event.preventDefault()
      if (this.inputTarget.value.trim()) {
        this.element.requestSubmit()
      }
    }
  }

  autoResize() {
    const input = this.inputTarget
    input.style.height = "auto"
    input.style.height = Math.min(input.scrollHeight, 120) + "px"
  }
}
