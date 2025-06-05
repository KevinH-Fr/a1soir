import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "messages", "box"]

  connect() {
    this.loadHistory()
  }

  async loadHistory() {
    try {
      const response = await fetch("/chat/history")
      const data = await response.json()

      data.messages.forEach((msg) => {
        const msgEl = document.createElement("div")
        msgEl.classList.add("mb-1")
        msgEl.classList.add(msg.role === "user" ? "text-end" : "text-start")
        msgEl.innerText = `${msg.role === "user" ? "Vous" : "Assistant"} : ${msg.text}`
        this.messagesTarget.appendChild(msgEl)
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
   // console.log("📨 Formulaire soumis.")

    const message = this.inputTarget.value.trim()
    if (!message) {
   //   console.log("⚠️ Message vide.")
      return
    }

    console.log("📝 Message : ", message)

    const userMessage = document.createElement("div")
    userMessage.classList.add("text-end", "mb-1")
    userMessage.innerText = `Vous : ${message}`
    this.messagesTarget.appendChild(userMessage)

    this.inputTarget.value = ""

    let response
    try {
      response = await fetch("/chat", {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "X-CSRF-Token": document.querySelector("[name='csrf-token']").content
        },
        body: JSON.stringify({ message: message }) // ✅ plus de thread_id ici
      })
    } catch (error) {
   //   console.error("❌ Erreur lors de la requête :", error)
      return
    }

    const reader = response.body.getReader()
    const decoder = new TextDecoder("utf-8")

    let aiMessage = document.createElement("div")
    aiMessage.classList.add("text-start", "mb-1")
    aiMessage.innerText = "Assistant : "
    this.messagesTarget.appendChild(aiMessage)

    console.log("📡 Réception en cours...")

    while (true) {
      const { done, value } = await reader.read()
      if (done) {
        console.log("✅ Fin du stream.")
        break
      }
      const chunk = decoder.decode(value, { stream: true })
  //    console.log("🧩 Chunk :", chunk)
      aiMessage.innerText += chunk
      this.messagesTarget.scrollTop = this.messagesTarget.scrollHeight
    }
  }
}
