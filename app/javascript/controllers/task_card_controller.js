import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { url: String }

  async open(event) {
    if (!this.hasUrlValue) return
    if (event.defaultPrevented) return
    if (typeof event.button === "number" && event.button !== 0) return
    if (window.getSelection && window.getSelection().toString()) return
    if (this.element.classList.contains("sortable-chosen") || this.element.classList.contains("sortable-drag")) return

    const ignored = event.target.closest(
      "button, form, input, textarea, select, [data-dropdown-target='menu'], [data-action*='dropdown']"
    )
    if (ignored) return

    const frame = document.getElementById("task_panel")
    if (frame) {
      const response = await fetch(this.urlValue, {
        headers: {
          "Accept": "text/html"
        },
        credentials: "same-origin"
      })

      if (!response.ok) return

      const html = await response.text()
      const doc = new DOMParser().parseFromString(html, "text/html")
      const returnedFrame = doc.getElementById("task_panel")

      if (returnedFrame) {
        frame.replaceWith(returnedFrame)
      } else {
        frame.innerHTML = html
      }

      return
    }

    window.location.href = this.urlValue
  }
}
