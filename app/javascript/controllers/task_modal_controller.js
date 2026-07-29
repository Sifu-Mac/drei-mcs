import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="task-modal"
export default class extends Controller {
  static targets = ["modal", "backdrop", "form", "nameField", "descriptionField", "submitButton", "priorityField", "priorityButton", "priorityLabel", "statusPill", "statusDot", "statusLabel", "saveStatus"]
  static values = { taskId: Number, updateUrl: String, assignUrl: String, unassignUrl: String, deleteUrl: String }

  connect() {
    this.boundHandleKeydown = this.handleKeydown.bind(this)
    this.autoSaveTimeout = null
    this.isAssigned = this.element.querySelector('[data-action="click->task-modal#toggleAgent"]')?.textContent?.includes('Assigned') || false

    // Auto-open the modal when it's loaded
    setTimeout(() => {
      this.open()
    }, 10)
  }

  disconnect() {
    document.removeEventListener("keydown", this.boundHandleKeydown)
    if (this.autoSaveTimeout) {
      clearTimeout(this.autoSaveTimeout)
    }
    if (this.saveStateTimer) {
      clearTimeout(this.saveStateTimer)
    }
  }

  open(event) {
    if (event) {
      event.stopPropagation()
    }

    document.addEventListener("keydown", this.boundHandleKeydown)

    // Show backdrop
    this.backdropTarget.classList.remove("hidden")
    setTimeout(() => {
      this.backdropTarget.classList.remove("opacity-0")
    }, 10)

    // Show centered modal
    this.modalTarget.classList.remove("hidden")
    setTimeout(() => {
      this.modalTarget.classList.remove("opacity-0", "scale-95")
    }, 10)
  }

  close() {
    // Save any pending changes before closing
    if (this.autoSaveTimeout) {
      clearTimeout(this.autoSaveTimeout)
      this.autoSaveTimeout = null
      this.save()
    }

    // Hide modal
    this.modalTarget.classList.add("opacity-0", "scale-95")
    this.backdropTarget.classList.add("opacity-0")

    setTimeout(() => {
      this.modalTarget.classList.add("hidden")
      this.backdropTarget.classList.add("hidden")

      if (this.pendingTurboStream) {
        Turbo.renderStreamMessage(this.pendingTurboStream)
        this.pendingTurboStream = null
      }

      const taskPanelFrame = document.getElementById('task_panel')
      if (taskPanelFrame) {
        taskPanelFrame.innerHTML = ''
      }
    }, 200)
  }

  save(event) {
    if (event) event.preventDefault()

    const form = this.formTarget
    const formData = new FormData(form)
    const csrfToken = document.querySelector('meta[name="csrf-token"]')?.content

    this.setSaveState("saving")

    return fetch(form.action, {
      method: 'PATCH',
      body: formData,
      headers: {
        'Accept': 'text/vnd.turbo-stream.html',
        'X-CSRF-Token': csrfToken
      }
    }).then(response => {
      if (!response.ok) throw new Error('save failed')
      return response.text()
    }).then(html => {
      if (html) this._handleTurboResponse(html)
      this.setSaveState("saved")
    }).catch(() => {
      this.setSaveState("error")
    })
  }

  scheduleAutoSave() {
    if (this.autoSaveTimeout) {
      clearTimeout(this.autoSaveTimeout)
    }
    this.setSaveState("pending")
    this.autoSaveTimeout = setTimeout(() => {
      this.save()
      this.autoSaveTimeout = null
    }, 500)
  }

  handleKeydown(event) {
    if (event.key === "Escape") {
      event.preventDefault()
      this.close()
    }
  }

  // --- Priority (single cycling button) ---

  static PRIORITY_CYCLE = ["none", "low", "medium", "high"]
  static PRIORITY_CONFIG = {
    none:   { dots: 0, color: "#9ca3af", bg: "#ffffff",                border: "#e5e7eb" },
    low:    { dots: 1, color: "#60a5fa", bg: "rgba(96,165,250,0.10)",  border: "rgba(96,165,250,0.25)" },
    medium: { dots: 2, color: "#fbbf24", bg: "rgba(251,191,36,0.10)",  border: "rgba(251,191,36,0.25)" },
    high:   { dots: 3, color: "#ef4444", bg: "rgba(239,68,68,0.10)",   border: "rgba(239,68,68,0.25)" },
  }

  cyclePriority() {
    const btn = this.priorityButtonTarget
    const current = btn.dataset.priorityValue || "none"
    const cycle = this.constructor.PRIORITY_CYCLE
    const nextIndex = (cycle.indexOf(current) + 1) % cycle.length
    const next = cycle[nextIndex]
    const cfg = this.constructor.PRIORITY_CONFIG[next]

    // Update data + hidden field
    btn.dataset.priorityValue = next
    if (this.hasPriorityFieldTarget) {
      this.priorityFieldTarget.value = next
    }

    // Update button visuals
    btn.style.background = cfg.bg
    btn.style.border = `1px solid ${cfg.border}`
    if (this.hasPriorityLabelTarget) {
      this.priorityLabelTarget.textContent = next === "none" ? "None" : next.charAt(0).toUpperCase() + next.slice(1)
    }

    // Rebuild dots
    btn.innerHTML = ""
    if (cfg.dots === 0) {
      const dot = document.createElement("div")
      dot.style.cssText = `width:5px;height:5px;border-radius:50%;background:#9ca3af;opacity:0.6`
      btn.appendChild(dot)
    } else {
      for (let i = 0; i < cfg.dots; i++) {
        const dot = document.createElement("div")
        dot.style.cssText = `width:5px;height:5px;border-radius:50%;background:${cfg.color}`
        btn.appendChild(dot)
      }
    }

    if (this.hasPriorityLabelTarget) {
      const label = document.createElement("span")
      label.dataset.taskModalTarget = "priorityLabel"
      label.style.cssText = "font-size:12px;font-weight:700;color:#374151;line-height:1"
      label.textContent = next === "none" ? "None" : next.charAt(0).toUpperCase() + next.slice(1)
      btn.appendChild(label)
    }

    this.save()
  }

  // --- Status (fetch-based, no form submission) ---

  changeStatus(event) {
    const btn = event.currentTarget
    const newStatus = btn.dataset.status
    const label = btn.dataset.statusLabel
    const dotColor = btn.dataset.statusDot

    // Optimistic UI: update the status trigger button and header pill
    if (this.hasStatusLabelTarget) this.statusLabelTarget.textContent = label
    if (this.hasStatusDotTarget) this.statusDotTarget.style.background = dotColor
    if (this.hasStatusPillTarget) this.statusPillTarget.textContent = label

    // Close the dropdown
    const dropdownMenu = btn.closest('[data-dropdown-target="menu"]')
    if (dropdownMenu) dropdownMenu.classList.add('hidden')

    // Send PATCH via fetch
    const csrfToken = document.querySelector('meta[name="csrf-token"]')?.content
    const formData = new FormData()
    formData.append('task[status]', newStatus)

    fetch(this.updateUrlValue, {
      method: 'PATCH',
      body: formData,
      headers: {
        'Accept': 'text/vnd.turbo-stream.html',
        'X-CSRF-Token': csrfToken
      }
    }).then(response => {
      if (response.ok) return response.text()
    }).then(html => {
      if (html) {
        // Apply turbo stream updates immediately (card move between columns)
        Turbo.renderStreamMessage(html)
      }
    })
  }

  // --- Agent toggle (fetch-based) ---

  toggleAgent() {
    const url = this.isAssigned ? this.unassignUrlValue : this.assignUrlValue
    const csrfToken = document.querySelector('meta[name="csrf-token"]')?.content

    fetch(url, {
      method: 'PATCH',
      headers: {
        'Accept': 'text/vnd.turbo-stream.html',
        'X-CSRF-Token': csrfToken
      }
    }).then(response => {
      if (response.ok) return response.text()
    }).then(html => {
      if (html) {
        Turbo.renderStreamMessage(html)
      }
      // Reload the panel to reflect the new agent state
      this.isAssigned = !this.isAssigned
      // Re-fetch the panel content
      const taskPanelFrame = document.getElementById('task_panel')
      if (taskPanelFrame) {
        taskPanelFrame.src = taskPanelFrame.src || window.location.href
        // Visit the task show URL to reload panel
        const taskLink = document.querySelector(`[data-task-id="${this.taskIdValue}"] a[data-turbo-frame="task_panel"]`)
        if (taskLink) taskLink.click()
      }
    })
  }

  deleteTask() {
    if (!this.deleteUrlValue) return
    if (!window.confirm('Task wirklich löschen?')) return

    const csrfToken = document.querySelector('meta[name="csrf-token"]')?.content

    fetch(this.deleteUrlValue, {
      method: 'DELETE',
      headers: {
        'Accept': 'text/vnd.turbo-stream.html',
        'X-CSRF-Token': csrfToken
      }
    }).then(response => {
      if (!response.ok) throw new Error('delete failed')
      return response.text()
    }).then(html => {
      if (html) {
        Turbo.renderStreamMessage(html)
      }
      this.close()
    }).catch(() => {
      this.setSaveState('error')
    })
  }

  // --- Internal helpers ---

  _handleTurboResponse(html) {
    const parser = new DOMParser()
    const doc = parser.parseFromString(html, 'text/html')
    const streams = doc.querySelectorAll('turbo-stream')

    let activityStreams = ''
    let otherStreams = ''

    streams.forEach(stream => {
      const target = stream.getAttribute('target') || ''
      if (target.startsWith('task-activities-')) {
        activityStreams += stream.outerHTML
      } else {
        otherStreams += stream.outerHTML
      }
    })

    // Apply activity updates now
    if (activityStreams) {
      Turbo.renderStreamMessage(activityStreams)
    }

    // Store card updates for when modal closes
    if (otherStreams) {
      this.pendingTurboStream = otherStreams
    }
  }

  setSaveState(state) {
    if (!this.hasSaveStatusTarget) return

    const states = {
      pending: { text: 'Unsaved changes', color: '#fbbf24' },
      saving: { text: 'Saving…', color: '#60a5fa' },
      saved: { text: 'Saved', color: '#34d399' },
      error: { text: 'Save failed', color: '#ef4444' }
    }

    const cfg = states[state] || { text: 'Auto-save active', color: '#666' }
    this.saveStatusTarget.textContent = cfg.text
    this.saveStatusTarget.style.color = cfg.color

    if (state === 'saved') {
      clearTimeout(this.saveStateTimer)
      this.saveStateTimer = setTimeout(() => {
        if (this.hasSaveStatusTarget) {
          this.saveStatusTarget.textContent = 'Auto-save active'
          this.saveStatusTarget.style.color = '#666'
        }
      }, 1500)
    }
  }
}
