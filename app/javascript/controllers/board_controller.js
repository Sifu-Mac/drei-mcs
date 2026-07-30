import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="board"
export default class extends Controller {
  static targets = ["columnsViewport", "column", "columnTab"]

  connect() {
    // Animate cards on page load with staggered delays
    this.animateCardsEntrance()
    this.updateActiveColumnTab()
  }

  openNewTaskModal(event) {
    event.preventDefault()
    // Get the current board path from the URL
    const path = window.location.pathname
    const newTaskPath = `${path}/tasks/new`
    Turbo.visit(newTaskPath, { frame: "new_task_modal" })
  }

  animateCardsEntrance() {
    const cards = this.element.querySelectorAll('[data-task-id]')
    cards.forEach((card, i) => {
      // Set initial state
      card.style.opacity = '0'
      card.style.transform = 'translateY(10px)'

      // Stagger the entrance animation
      setTimeout(() => {
        card.style.transition = 'opacity 300ms ease-out, transform 300ms ease-out'
        card.style.opacity = '1'
        card.style.transform = 'translateY(0)'

        // Clean up inline styles after animation completes
        setTimeout(() => {
          card.style.transition = ''
          card.style.opacity = ''
          card.style.transform = ''
        }, 300)
      }, i * 40) // 40ms stagger between each card
    })
  }

  scrollToColumn(event) {
    const columnId = String(event.params.columnId)
    const column = this.columnTargets.find((target) => target.dataset.columnId === columnId)
    if (!column) return

    column.scrollIntoView({ behavior: "smooth", inline: "start", block: "nearest" })
    this.setActiveTab(columnId)
  }

  handleColumnsScroll() {
    window.clearTimeout(this.scrollTimer)
    this.scrollTimer = window.setTimeout(() => this.updateActiveColumnTab(), 50)
  }

  updateActiveColumnTab() {
    if (!this.hasColumnsViewportTarget || window.innerWidth >= 768) return

    const viewportRect = this.columnsViewportTarget.getBoundingClientRect()
    const viewportCenter = viewportRect.left + viewportRect.width / 2

    let activeColumnId = null
    let bestDistance = Infinity

    this.columnTargets.forEach((column) => {
      const rect = column.getBoundingClientRect()
      const center = rect.left + rect.width / 2
      const distance = Math.abs(center - viewportCenter)

      if (distance < bestDistance) {
        bestDistance = distance
        activeColumnId = column.dataset.columnId
      }
    })

    if (activeColumnId) this.setActiveTab(activeColumnId)
  }

  setActiveTab(columnId) {
    this.columnTabTargets.forEach((tab) => {
      const active = tab.dataset.boardColumnIdParam === columnId
      tab.classList.toggle("bg-accent/10", active)
      tab.classList.toggle("text-accent", active)
      tab.classList.toggle("border-accent/30", active)
      tab.classList.toggle("bg-bg-elevated", !active)
      tab.classList.toggle("text-content-muted", !active)
      tab.classList.toggle("border-border", !active)
    })
  }
}
