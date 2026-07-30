import { Controller } from "@hotwired/stimulus"
import Sortable from "sortablejs"

let updatePending = false

// Connects to data-controller="sortable"
// Used for kanban board column drag-and-drop
export default class extends Controller {
  static values = {
    group: String,
    columnId: String,
    url: String
  }

  connect() {
    this.element.sortableController = this
    const options = {
      animation: 150,
      ghostClass: "sortable-ghost",
      dragClass: "sortable-drag",
      handle: ".task-drag-handle",
      delay: 180,
      delayOnTouchOnly: true,
      touchStartThreshold: 5,
      fallbackTolerance: 4,
      emptyInsertThreshold: 50,
      swapThreshold: 0.65,
      invertSwap: true,
      filter: '[style*="display: none"]',
      onStart: this.handleStart.bind(this),
      onEnd: this.handleEnd.bind(this),
      onMove: this.move.bind(this),
      onChange: this.handleChange.bind(this),
      onUpdate: this.handleUpdate.bind(this)
    }

    // Board mode: enable cross-column dragging
    if (this.hasGroupValue) {
      options.group = this.groupValue
      options.onAdd = this.handleAdd.bind(this)
    }

    this.sortable = Sortable.create(this.element, options)
  }

  disconnect() {
    if (this.sortable) {
      this.sortable.destroy()
    }
    delete this.element.sortableController
    window.clearTimeout(this.errorTimeout)
  }

  // Dispatch event when drag starts (for delete zone visibility)
  handleStart(event) {
    event.item.sortableSnapshot = this.captureBoardState()
    document.dispatchEvent(new CustomEvent("sortable:dragstart", { detail: { item: event.item } }))
  }

  // Dispatch event when drag ends (for delete zone visibility)
  handleEnd(event) {
    document.dispatchEvent(new CustomEvent("sortable:dragend", { detail: { item: event.item } }))

    // Remove column highlight from all columns
    document.querySelectorAll('.column-drag-over').forEach(el => {
      el.classList.remove('column-drag-over')
    })
  }

  // Handle visual feedback during drag
  handleChange(event) {
    // Add column highlight to the column being dragged over
    const targetColumn = event.to.closest('[data-column-id]')
    if (targetColumn) {
      // Remove highlight from all columns first
      document.querySelectorAll('.column-drag-over').forEach(el => {
        el.classList.remove('column-drag-over')
      })
      // Add highlight to current column
      targetColumn.classList.add('column-drag-over')
    }
  }

  move(event) {
    // Don't allow moving hidden (filtered) items
    if (event.related?.style?.display === 'none') {
      return false
    }
    return true
  }

  // Handle reordering within the same column
  async handleUpdate(event) {
    if (!this.hasUrlValue) return

    await this.persistMove(event, {
      task_id: event.item.dataset.taskId,
      task_ids: this.taskIds(this.element),
      board_column_id: this.columnIdValue,
      source_column_id: this.columnIdValue
    })
  }

  // Handle task added from another column (board mode)
  async handleAdd(event) {
    if (!this.hasUrlValue || !this.hasColumnIdValue) return

    const taskId = event.item.dataset.taskId
    const newColumnId = this.columnIdValue
    const oldColumnId = this.columnIdFor(event.from)

    // Get all task IDs in their new order (including the newly added one)
    const taskIds = this.taskIds(this.element)

    // Update the task's data attributes
    event.item.dataset.taskColumnId = newColumnId

    this.setColumnCount(oldColumnId, this.taskIds(event.from).length)
    this.setColumnCount(newColumnId, taskIds.length)

    await this.persistMove(event, {
      task_id: taskId,
      board_column_id: newColumnId,
      source_column_id: oldColumnId,
      task_ids: taskIds
    })
  }

  get csrfToken() {
    return document.querySelector("[name='csrf-token']")?.content || ""
  }

  async persistMove(event, payload) {
    if (updatePending) {
      this.restoreBoardState(event.item.sortableSnapshot)
      this.showError("Die vorherige Verschiebung wird noch gespeichert.")
      return
    }

    updatePending = true
    this.setDraggingEnabled(false)

    try {
      const response = await fetch(this.urlValue, {
        method: "PATCH",
        headers: {
          "Content-Type": "application/json",
          "Accept": "application/json",
          "X-CSRF-Token": this.csrfToken
        },
        body: JSON.stringify(payload)
      })

      if (!response.ok) {
        const body = await response.json().catch(() => ({}))
        throw new Error(body.error || "Die Kartenposition konnte nicht gespeichert werden.")
      }
    } catch (error) {
      this.restoreBoardState(event.item.sortableSnapshot)
      this.showError(error.message)
      console.error("Error updating task positions:", error)
    } finally {
      delete event.item.sortableSnapshot
      updatePending = false
      this.setDraggingEnabled(true)
    }
  }

  captureBoardState() {
    return Array.from(document.querySelectorAll('[data-controller~="sortable"][data-sortable-column-id-value]')).map(element => ({
      element,
      columnId: this.columnIdFor(element),
      items: Array.from(element.querySelectorAll(":scope > [data-task-id]")),
      count: document.getElementById(`column-${this.columnIdFor(element)}-count`)?.textContent
    }))
  }

  restoreBoardState(snapshot) {
    if (!snapshot) return

    snapshot.forEach(column => {
      column.items.forEach(item => {
        column.element.appendChild(item)
        item.dataset.taskColumnId = column.columnId
      })
      if (column.count !== undefined) {
        this.setColumnCount(column.columnId, column.count)
      }
    })
  }

  setDraggingEnabled(enabled) {
    document.querySelectorAll('[data-controller~="sortable"]').forEach(element => {
      element.sortableController?.sortable?.option("disabled", !enabled)
    })
  }

  taskIds(element) {
    return Array.from(element.querySelectorAll(":scope > [data-task-id]"))
      .map(item => item.dataset.taskId)
  }

  columnIdFor(element) {
    return element.dataset.sortableColumnIdValue || element.id.replace("column-", "")
  }

  setColumnCount(columnId, value) {
    const countEl = document.getElementById(`column-${columnId}-count`)
    if (countEl) {
      countEl.textContent = value
    }
  }

  showError(message) {
    let error = document.getElementById("board-drag-error")
    if (!error) {
      error = document.createElement("div")
      error.id = "board-drag-error"
      error.setAttribute("role", "alert")
      error.className = "fixed right-4 top-4 z-[300] max-w-sm rounded-lg border border-red-200 bg-red-50 px-4 py-3 text-sm font-semibold text-red-700 shadow-lg"
      document.body.appendChild(error)
    }

    error.textContent = message || "Die Kartenposition konnte nicht gespeichert werden."
    window.clearTimeout(this.errorTimeout)
    this.errorTimeout = window.setTimeout(() => error.remove(), 5000)
  }
}
