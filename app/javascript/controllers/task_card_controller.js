import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { url: String }

  connect() {
    this.isDragging = false
    this.lastDragEndedAt = 0
    this.handleDragStart = this.handleDragStart.bind(this)
    this.handleDragEnd = this.handleDragEnd.bind(this)

    document.addEventListener("sortable:dragstart", this.handleDragStart)
    document.addEventListener("sortable:dragend", this.handleDragEnd)
  }

  disconnect() {
    document.removeEventListener("sortable:dragstart", this.handleDragStart)
    document.removeEventListener("sortable:dragend", this.handleDragEnd)
  }

  handleDragStart(event) {
    if (event.detail?.item === this.element) this.isDragging = true
  }

  handleDragEnd(event) {
    if (event.detail?.item === this.element) {
      this.isDragging = false
      this.lastDragEndedAt = Date.now()
    }
  }

  async open(event) {
    if (!this.hasUrlValue) return
    if (event.defaultPrevented) return
    if (typeof event.button === "number" && event.button !== 0) return
    if (window.getSelection && window.getSelection().toString()) return
    if (this.isDragging || Date.now() - this.lastDragEndedAt < 250) return
    if (this.element.classList.contains("sortable-chosen") || this.element.classList.contains("sortable-drag")) return

    const ignored = event.target.closest(
      "a, button, form, input, textarea, select, label, [data-no-card-open], [data-dropdown-target='button'], [data-dropdown-target='menu'], .task-drag-handle"
    )
    if (ignored) return

    const frame = document.getElementById("task_panel")
    if (!frame) {
      window.location.href = this.urlValue
      return
    }

    const response = await fetch(this.urlValue, {
      headers: {
        "Accept": "text/html",
        "Turbo-Frame": "task_panel"
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
  }
}
