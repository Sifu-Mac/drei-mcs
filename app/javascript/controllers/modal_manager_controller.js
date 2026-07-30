import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["modal"]

  connect() {
    this.activeModal = null
    this.returnFocusTo = null
  }

  open(event) {
    event.preventDefault()
    const modal = this.findModal(event.params.id)
    if (!modal) return

    this.closeActiveModal()
    this.activeModal = modal
    this.returnFocusTo = event.currentTarget
    modal.classList.remove("hidden")
    modal.setAttribute("aria-hidden", "false")

    requestAnimationFrame(() => {
      modal.querySelector("input:not([type='hidden']), textarea, select, button")?.focus()
    })
  }

  close(event) {
    event?.preventDefault()
    const modal = event?.currentTarget?.closest("[data-modal-manager-target='modal']") || this.activeModal
    this.hideModal(modal)
  }

  closeOnBackdrop(event) {
    if (event.target === event.currentTarget) this.close(event)
  }

  closeOnEscape(event) {
    if (event.key !== "Escape" || !this.activeModal) return

    event.preventDefault()
    this.close()
  }

  findModal(id) {
    return this.modalTargets.find((modal) => modal.id === id)
  }

  closeActiveModal() {
    if (this.activeModal) this.hideModal(this.activeModal, false)
  }

  hideModal(modal, restoreFocus = true) {
    if (!modal) return

    modal.classList.add("hidden")
    modal.setAttribute("aria-hidden", "true")
    if (modal === this.activeModal) this.activeModal = null

    if (restoreFocus) {
      this.returnFocusTo?.focus()
      this.returnFocusTo = null
    }
  }
}
