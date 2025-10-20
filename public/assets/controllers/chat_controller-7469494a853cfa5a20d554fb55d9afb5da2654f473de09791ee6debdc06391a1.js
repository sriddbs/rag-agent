import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["messages", "input", "form", "loading"]

  connect() {
    this.abortController = null
    this.scrollToBottom()
    // keyboard enter handling
    this.inputTarget.addEventListener("keydown", (e) => {
      if (e.key === "Enter" && !e.shiftKey) {
        e.preventDefault()
        this.send(e)
      }
    })
  }

  async send(event) {
    event.preventDefault()
    const message = this.inputTarget.value.trim()
    if (!message) return

    // optimistic UI: show user message and disable input
    const tempEl = this.addMessage("user", message, { temporary: true })
    this.inputTarget.value = ""
    this.setDisabled(true)
    this.showLoading()

    // cancel previous in-flight request
    if (this.abortController) {
      this.abortController.abort()
    }
    this.abortController = new AbortController()
    const signal = this.abortController.signal

   try {
      const response = await fetch("/chat/message", {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "X-CSRF-Token": document.querySelector("[name='csrf-token']").content
        },
        body: JSON.stringify({ message }),
        signal
      })

      if (!response.ok) {
        // try to extract useful JSON info if possible
        let payload
        try {
          payload = await response.json()
        } catch {
          payload = { error: response.statusText }
        }

        if (response.status === 429) {
          this.addMessage(
            "assistant",
            "The AI is at capacity right now — please try again in a few seconds."
          )
        } else if (response.status >= 500) {
          this.addMessage(
            "assistant",
            "Server hiccup — it's not you, it's us. Try again shortly."
          )
        } else {
          this.addMessage(
            "assistant",
            `Error: ${payload.error || payload.message || response.statusText}`
          )
        }

        return
      }

      // normal success case
      const data = await response.json()
      if (tempEl && tempEl.parentNode) {
        // (optional) handle temporary placeholders here
      }
      this.addMessage("assistant", data.content || "(no content)")
    } catch (err) {
      if (err.name === "AbortError") {
        console.log("Request aborted — user typed again.")
      } else {
        console.error("Chat request failed:", err)
        this.addMessage("assistant", `Network error: ${err.message}`)
      }
    } finally {
      this.hideLoading()
      this.setDisabled(false)
      this.abortController = null
    }
  }

  addMessage(role, content, opts = {}) {
    const container = this.messagesTarget
    const tpl = document.getElementById(role === "user" ? "tpl-message-user" : "tpl-message-assistant")
    const node = tpl.content.firstElementChild.cloneNode(true)

    node.querySelector(".message-content").textContent = content
    node.querySelector(".message-time").textContent = new Date().toLocaleTimeString('en-US', { hour: '2-digit', minute: '2-digit' })

    if (opts.temporary) {
      node.dataset.temp = "true"
    }

    container.appendChild(node)
    // smooth scroll the new element into view
    node.scrollIntoView({ behavior: "smooth", block: "end" })
    return node
  }

  setDisabled(disabled = true) {
    this.inputTarget.disabled = disabled
    const submitBtn = this.element.querySelector("button[type='submit']")
    if (submitBtn) submitBtn.disabled = disabled
  }

  showLoading() {
    this.loadingTarget.classList.remove("hidden")
    // ensure visible
    this.loadingTarget.scrollIntoView({ behavior: "smooth", block: "end" })
  }

  hideLoading() {
    this.loadingTarget.classList.add("hidden")
  }

  scrollToBottom() {
    this.messagesTarget.scrollTop = this.messagesTarget.scrollHeight
  }
};
