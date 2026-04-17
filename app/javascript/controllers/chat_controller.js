import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "messages", "box"]
  static values = {
    userLabel: { type: String, default: "Vous" },
    assistantLabel: { type: String, default: "Assistant" }
  }

  connect() {
    this.loadHistory()
  }

  appendMessage(role, text) {
    const row = document.createElement("div")
    row.classList.add(
      "chatbox-msg",
      role === "user" ? "chatbox-msg--user" : "chatbox-msg--assistant"
    )

    const label = document.createElement("span")
    label.className = "chatbox-msg__label"
    label.textContent = role === "user" ? this.userLabelValue : this.assistantLabelValue

    const body = document.createElement("div")
    body.className = "chatbox-msg__text"
    body.textContent = text

    row.appendChild(label)
    row.appendChild(body)
    this.messagesTarget.appendChild(row)
  }

  async loadHistory() {
    try {
      const response = await fetch("/chat/history")
      const data = await response.json()

      data.messages.forEach((msg) => {
        this.appendMessage(msg.role, msg.text)
      })

      this.messagesTarget.scrollTop = this.messagesTarget.scrollHeight
    } catch (error) {
      console.error("❌ Erreur chargement historique :", error)
    }
  }

  toggle() {
    this.boxTarget.classList.toggle("visible")
  }

  async send(event) {
    event.preventDefault()

    const message = this.inputTarget.value.trim()
    if (!message) {
      return
    }

    this.appendMessage("user", message)
    this.inputTarget.value = ""

    let response
    try {
      response = await fetch("/chat", {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "X-CSRF-Token": document.querySelector("[name='csrf-token']").content
        },
        body: JSON.stringify({ message: message })
      })
    } catch (error) {
      return
    }

    const row = document.createElement("div")
    row.classList.add("chatbox-msg", "chatbox-msg--assistant")

    const label = document.createElement("span")
    label.className = "chatbox-msg__label"
    label.textContent = this.assistantLabelValue

    const body = document.createElement("div")
    body.className = "chatbox-msg__text"
    body.textContent = ""

    row.appendChild(label)
    row.appendChild(body)
    this.messagesTarget.appendChild(row)

    const reader = response.body.getReader()
    const decoder = new TextDecoder("utf-8")

    while (true) {
      const { done, value } = await reader.read()
      if (done) {
        break
      }
      const chunk = decoder.decode(value, { stream: true })
      body.textContent += chunk
      this.messagesTarget.scrollTop = this.messagesTarget.scrollHeight
    }
  }
}
