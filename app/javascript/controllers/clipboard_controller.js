import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["source", "label"]
  static values = { text: String }

  async copy() {
    const text = this.hasTextValue ? this.textValue : (this.sourceTarget.textContent || this.sourceTarget.value)
    
    try {
      await navigator.clipboard.writeText(text)
      
      if (this.hasLabelTarget) {
        const originalText = this.labelTarget.textContent
        this.labelTarget.textContent = "Kopiert!"
        
        setTimeout(() => {
          this.labelTarget.textContent = originalText
        }, 2000)
      }
    } catch (err) {
      console.error("Failed to copy:", err)
      
      if (this.hasLabelTarget) {
        this.labelTarget.textContent = "Fehlgeschlagen"
        
        setTimeout(() => {
          this.labelTarget.textContent = "Kopieren"
        }, 2000)
      }
    }
  }
}
