import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "messages", "box"]
  static values = {
    userLabel: { type: String, default: "Vous" },
    assistantLabel: { type: String, default: "Assistant" },
    resetSuccess: { type: String, default: "Conversation reinitialisee. Comment puis-je vous aider ?" }
  }

  connect() {
    this.loadHistory()
  }

  scrollToBottom() {
    this.messagesTarget.scrollTop = this.messagesTarget.scrollHeight
  }

  renderMessageText(target, text) {
    const source = text || ""
    target.replaceChildren()

    const markdownLinkRegex = /\[([^\]]+)\]\((https?:\/\/[^\s)]+)\)/g
    let cursor = 0
    let markdownMatch

    while ((markdownMatch = markdownLinkRegex.exec(source)) !== null) {
      const [fullMatch, label, href] = markdownMatch
      const start = markdownMatch.index
      const end = start + fullMatch.length

      if (start > cursor) {
        this.appendPlainTextWithUrls(target, source.slice(cursor, start))
      }

      target.appendChild(this.buildSafeAnchor(href, label))
      cursor = end
    }

    if (cursor < source.length) {
      this.appendPlainTextWithUrls(target, source.slice(cursor))
    }
  }

  appendPlainTextWithUrls(target, text) {
    const urlRegex = /(https?:\/\/[^\s]+)/g
    let cursor = 0
    let urlMatch

    while ((urlMatch = urlRegex.exec(text)) !== null) {
      const [url] = urlMatch
      const start = urlMatch.index
      const end = start + url.length

      if (start > cursor) {
        target.appendChild(document.createTextNode(text.slice(cursor, start)))
      }

      target.appendChild(this.buildSafeAnchor(url, url))
      cursor = end
    }

    if (cursor < text.length) {
      target.appendChild(document.createTextNode(text.slice(cursor)))
    }
  }

  buildSafeAnchor(href, label) {
    const a = document.createElement("a")
    a.href = href
    a.textContent = label
    a.target = "_blank"
    a.rel = "noopener noreferrer"
    a.className = "chatbox-link"
    return a
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
    this.renderMessageText(body, text)

    row.appendChild(label)
    row.appendChild(body)
    this.messagesTarget.appendChild(row)
    this.scrollToBottom()
    return body
  }

  async loadHistory() {
    try {
      const response = await fetch("/chat/history")
      const data = await response.json()

      data.messages.forEach((msg) => {
        this.appendMessage(msg.role, msg.text)
      })

      this.scrollToBottom()
    } catch (error) {
      console.error("❌ Erreur chargement historique :", error)
    }
  }

  toggle() {
    this.boxTarget.classList.toggle("visible")
  }

  async resetConversation() {
    try {
      const response = await fetch("/chat/reset", {
        method: "DELETE",
        headers: {
          "X-CSRF-Token": document.querySelector("[name='csrf-token']").content
        }
      })

      if (!response.ok) {
        return
      }

      this.messagesTarget.replaceChildren()
      this.appendMessage("assistant", this.resetSuccessValue)
    } catch (_error) {
      // silent fail to keep UX stable
    }
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
    this.scrollToBottom()

    let assistantRawText = ""

    const reader = response.body.getReader()
    const decoder = new TextDecoder("utf-8")

    while (true) {
      const { done, value } = await reader.read()
      if (done) {
        break
      }
      const chunk = decoder.decode(value, { stream: true })
      assistantRawText += chunk
      this.renderMessageText(body, assistantRawText)
      this.scrollToBottom()
    }
  }
}
