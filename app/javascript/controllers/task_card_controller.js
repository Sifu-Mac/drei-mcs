import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { url: String }

  open(event) {
    if (!this.hasUrlValue) return
    if (event.defaultPrevented) return
    if (event.button !== 0) return
    if (window.getSelection && window.getSelection().toString()) return

    const ignored = event.target.closest(
      ".task-drag-handle, button, form, input, textarea, select, [data-dropdown-target='menu'], [data-action*='dropdown'], a"
    )
    if (ignored) return

    const frame = document.getElementById("task_panel")
    if (frame) {
      frame.src = this.urlValue
      return
    }

    window.location.href = this.urlValue
  }
}
