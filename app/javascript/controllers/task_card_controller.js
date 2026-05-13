import { Controller } from "@hotwired/stimulus"
import { Turbo } from "@hotwired/turbo-rails"

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

    Turbo.visit(this.urlValue, { frame: "task_panel" })
  }
}
