import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "messages"]

  async send(event) {
    event.preventDefault()

    const message = this.inputTarget.value.trim()
    if (!message) return

    const userMessage = document.createElement("div")
    userMessage.classList.add("text-end", "mb-1")
    userMessage.innerText = `Vous : ${message}`
    this.messagesTarget.appendChild(userMessage)

    this.inputTarget.value = ""

    const threadId = this.element.dataset.threadId || null

    const response = await fetch("/chat", {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "X-CSRF-Token": document.querySelector("[name='csrf-token']").content
      },
      body: JSON.stringify({ message: message, thread_id: threadId })
    })

    // Récupération du thread_id renvoyé dans l'en-tête
    const returnedThreadId = response.headers.get("X-Chatbot-Thread-Id")
    if (returnedThreadId) {
      this.element.dataset.threadId = returnedThreadId
    }

    const reader = response.body.getReader()
    const decoder = new TextDecoder("utf-8")
    let aiMessage = document.createElement("div")
    aiMessage.classList.add("text-start", "mb-1")
    aiMessage.innerText = "Assistant : "
    this.messagesTarget.appendChild(aiMessage)

    while (true) {
      const { done, value } = await reader.read()
      if (done) break
      aiMessage.innerText += decoder.decode(value, { stream: true })
      this.messagesTarget.scrollTop = this.messagesTarget.scrollHeight
    }
  }
}
