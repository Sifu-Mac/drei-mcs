import { Controller } from "@hotwired/stimulus"

// Sends a quote selection to the task's comment form without duplicating forms.
export default class extends Controller {
  static values = { commentId: Number, author: String, body: String }

  select() {
    window.dispatchEvent(new CustomEvent("comment:quote", {
      detail: { commentId: this.commentIdValue, author: this.authorValue, body: this.bodyValue }
    }))
  }
}
