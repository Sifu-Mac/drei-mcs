import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="dropdown"
export default class extends Controller {
  static targets = ["button", "menu", "container", "trigger", "input", "display", "actionList", "editPanel"]
  static values = { portal: Boolean }

  connect() {
    this.menuElement = this.hasMenuTarget ? this.menuTarget : null
    this.buttonElement = this.hasButtonTarget ? this.buttonTarget : (this.hasTriggerTarget ? this.triggerTarget : null)
    this.actionListElement = this.hasActionListTarget ? this.actionListTarget : null
    this.editPanelElement = this.hasEditPanelTarget ? this.editPanelTarget : null
    this.placeholder = null

    this.handleClickOutside = this.handleClickOutside.bind(this)
    this.handleKeydown = this.handleKeydown.bind(this)
    this.handleCloseAll = this.handleCloseAll.bind(this)
    this.handleMenuClick = this.handleMenuClick.bind(this)
    this.handleReposition = this.handleReposition.bind(this)

    document.addEventListener("dropdown:close-all", this.handleCloseAll)
    document.addEventListener("turbo:before-cache", this.handleCloseAll)
    this.menuElement?.addEventListener("click", this.handleMenuClick)
  }

  disconnect() {
    this.close()
    document.removeEventListener("dropdown:close-all", this.handleCloseAll)
    document.removeEventListener("turbo:before-cache", this.handleCloseAll)
    this.menuElement?.removeEventListener("click", this.handleMenuClick)
  }

  handleCloseAll(event) {
    if (event.detail?.except !== this.element) this.close()
  }

  toggle(event) {
    event.preventDefault()
    event.stopPropagation()

    this.isOpen ? this.close() : this.open()
  }

  open() {
    if (!this.menuElement || !this.buttonElement) return

    document.dispatchEvent(new CustomEvent("dropdown:close-all", { detail: { except: this.element } }))

    if (this.portalValue) this.portalMenu()

    this.menuElement.classList.remove("hidden")
    this.buttonElement.setAttribute("aria-expanded", "true")
    this.showActions()

    if (this.hasContainerTarget) {
      this.containerTarget.classList.remove("opacity-0")
      this.containerTarget.classList.add("opacity-100", "z-[80]")
    }

    this.positionMenu()

    document.addEventListener("click", this.handleClickOutside)
    document.addEventListener("keydown", this.handleKeydown)
    window.addEventListener("resize", this.handleReposition)
    window.addEventListener("scroll", this.handleReposition, true)
  }

  close() {
    if (!this.menuElement) return

    this.menuElement.classList.add("hidden")
    if (this.buttonElement) this.buttonElement.setAttribute("aria-expanded", "false")
    this.resetMenuPosition()
    this.restoreMenu()
    this.showActions()

    if (this.hasContainerTarget) {
      this.containerTarget.classList.remove("opacity-100", "z-[80]")
      this.containerTarget.classList.add("opacity-0")
    }

    document.removeEventListener("click", this.handleClickOutside)
    document.removeEventListener("keydown", this.handleKeydown)
    window.removeEventListener("resize", this.handleReposition)
    window.removeEventListener("scroll", this.handleReposition, true)
  }

  showPanel(event) {
    event.preventDefault()
    event.stopPropagation()
    this.showEditPanel()
    this.positionMenu()
  }

  showActions(event) {
    if (event) {
      event.preventDefault()
      event.stopPropagation()
    }
    this.actionListElement?.classList.remove("hidden")
    this.editPanelElement?.classList.add("hidden")
    this.positionMenu()
  }

  showEditPanel() {
    this.actionListElement?.classList.add("hidden")
    this.editPanelElement?.classList.remove("hidden")
  }

  select(event) {
    const value = event.currentTarget.dataset.value
    const label = event.currentTarget.dataset.label

    if (this.hasInputTarget && value !== undefined) this.inputTarget.value = value
    if (this.hasDisplayTarget && label) this.displayTarget.textContent = label

    this.close()
  }

  handleClickOutside(event) {
    const clickedTrigger = this.element.contains(event.target)
    const clickedMenu = this.menuElement?.contains(event.target)
    if (!clickedTrigger && !clickedMenu) this.close()
  }

  handleMenuClick(event) {
    const command = event.target.closest("[data-dropdown-command]")?.dataset.dropdownCommand
    if (command === "edit") {
      event.preventDefault()
      event.stopPropagation()
      this.showEditPanel()
      this.positionMenu()
      return
    }

    if (command === "actions") {
      event.preventDefault()
      event.stopPropagation()
      this.showActions()
      this.positionMenu()
      return
    }

    if (event.target.closest("[data-dropdown-keep-open]")) return
    if (event.target.closest("a, button[type='submit'], input[type='submit']")) {
      window.setTimeout(() => this.close(), 80)
    }
  }

  handleKeydown(event) {
    if (event.key === "Escape") {
      event.preventDefault()
      this.close()
    }
  }

  handleReposition() {
    if (this.isOpen) this.positionMenu()
  }

  portalMenu() {
    if (!this.menuElement || this.menuElement.parentElement === document.body) return

    this.placeholder = document.createComment("dropdown-menu-placeholder")
    this.menuElement.parentElement.insertBefore(this.placeholder, this.menuElement)
    document.body.appendChild(this.menuElement)
  }

  restoreMenu() {
    if (!this.menuElement || !this.placeholder) return

    this.placeholder.parentElement?.insertBefore(this.menuElement, this.placeholder)
    this.placeholder.remove()
    this.placeholder = null
  }

  positionMenu() {
    if (!this.menuElement || !this.buttonElement || this.menuElement.classList.contains("hidden")) return
    if (!this.portalValue) return

    const margin = 10
    const triggerRect = this.buttonElement.getBoundingClientRect()

    this.menuElement.style.position = "fixed"
    this.menuElement.style.right = "auto"
    this.menuElement.style.bottom = "auto"
    this.menuElement.style.maxWidth = `calc(100vw - ${margin * 2}px)`
    this.menuElement.style.visibility = "hidden"
    this.menuElement.style.left = "0px"
    this.menuElement.style.top = "0px"

    const menuRect = this.menuElement.getBoundingClientRect()
    const viewportWidth = window.innerWidth
    const viewportHeight = window.innerHeight

    let left = triggerRect.right - menuRect.width
    left = Math.min(Math.max(left, margin), viewportWidth - menuRect.width - margin)

    const spaceBelow = viewportHeight - triggerRect.bottom
    const openUp = spaceBelow < menuRect.height + margin && triggerRect.top > spaceBelow
    let top = openUp ? triggerRect.top - menuRect.height - 8 : triggerRect.bottom + 8
    top = Math.min(Math.max(top, margin), viewportHeight - menuRect.height - margin)

    this.menuElement.style.left = `${Math.round(left)}px`
    this.menuElement.style.top = `${Math.round(top)}px`
    this.menuElement.style.visibility = "visible"
  }

  resetMenuPosition() {
    if (!this.menuElement) return

    this.menuElement.style.position = ""
    this.menuElement.style.left = ""
    this.menuElement.style.top = ""
    this.menuElement.style.right = ""
    this.menuElement.style.bottom = ""
    this.menuElement.style.maxWidth = ""
    this.menuElement.style.visibility = ""
  }

  get isOpen() {
    return this.menuElement && !this.menuElement.classList.contains("hidden")
  }
}
