import { Controller } from "@hotwired/stimulus";
import { BrowserQRCodeReader } from "@zxing/library";

export default class extends Controller {
  connect() {
    console.log("[Stimulus] Contrôleur connecté");

    this.codeReader = new BrowserQRCodeReader();
    this.selectedDeviceId = null;
    this.resultsDiv = document.getElementById("results");
    this.sourceSelect = this.element.querySelector("#sourceSelect");

    this.populateSources();

    const scannerInput = this.element.querySelector("#scannerInput");
    if (scannerInput) {
      console.log("[Stimulus] Champ douchette trouvé, focus appliqué");
      scannerInput.focus();
    }

    if (sessionStorage.getItem("scanning") === "true") {
      this.startScan();
    }
  }

  populateSources() {
    console.log("[Stimulus] Initialisation des sources vidéo...");

    if (
      navigator.mediaDevices &&
      navigator.mediaDevices.enumerateDevices &&
      navigator.mediaDevices.getUserMedia
    ) {
      navigator.mediaDevices.getUserMedia({ video: true })
        .then(() => {
          navigator.mediaDevices.enumerateDevices()
            .then((devices) => {
              const videoInputDevices = devices.filter(device => device.kind === "videoinput");
              console.log("[Stimulus] Appareils vidéo détectés :", videoInputDevices);

              if (videoInputDevices.length >= 1) {
                const storedDeviceId = sessionStorage.getItem("selectedCamera");
                this.selectedDeviceId = storedDeviceId || videoInputDevices[0].deviceId;

                this.sourceSelect.innerHTML = "";
                videoInputDevices.forEach((device) => {
                  const sourceOption = document.createElement("option");
                  sourceOption.text = device.label || `Camera ${this.sourceSelect.length + 1}`;
                  sourceOption.value = device.deviceId;
                  this.sourceSelect.appendChild(sourceOption);

                  if (device.deviceId === this.selectedDeviceId) {
                    sourceOption.selected = true;
                  }
                });

                this.sourceSelect.onchange = () => {
                  this.selectedDeviceId = this.sourceSelect.value;
                  sessionStorage.setItem("selectedCamera", this.selectedDeviceId);
                };

                const sourceSelectPanel = this.element.querySelector("#sourceSelectPanel");
                sourceSelectPanel.style.display = "inline";

                if (sessionStorage.getItem("scanning") === "true") {
                  this.startScan();
                }
              } else {
                console.error("[Stimulus] Aucun périphérique vidéo détecté.");
              }
            })
            .catch((err) => {
              console.error("[Stimulus] Erreur lors de l’énumération des périphériques :", err);
            });
        })
        .catch((err) => {
          console.error("[Stimulus] Accès à la caméra refusé :", err);
        });
    } else {
      console.error("[Stimulus] API caméra non supportée par le navigateur.");
    }
  }

  startScan() {
    console.log("[Stimulus] Démarrage du scan...");

    const btnStart = this.element.querySelector("#startButton");
    btnStart.style.display = "none";

    const btnReset = this.element.querySelector("#resetButton");
    btnReset.style.display = "inline";

    if (!this.selectedDeviceId) {
      console.error("[Stimulus] Aucune caméra sélectionnée");
      return;
    }

    this.codeReader.decodeFromInputVideoDevice(this.selectedDeviceId, "video").then((result) => {
      if (result) {
        console.log("[Stimulus] QR Code détecté via caméra :", result);
        this.handleResult(result);
      }
    });
  }

  stopScan() {
    console.log("[Stimulus] Arrêt du scan");
    this.codeReader.reset();
    this.resultsDiv.textContent = "";

    const btnStart = this.element.querySelector("#startButton");
    btnStart.style.display = "inline";

    const btnReset = this.element.querySelector("#resetButton");
    btnReset.style.display = "none";

    sessionStorage.removeItem("scanning");
  }

  handleResult(result) {
    const raw = result.toString();
    console.log("[Stimulus] Traitement du QR code (caméra) :", raw);

    try {
      const resultTransforme = raw.split("produits/")[1];
      const resultTransforme2 = resultTransforme.split("?")[0];

      this.resultsDiv.innerHTML += `<p>Product ID (caméra) : ${resultTransforme2}</p>`;
      this.element.querySelector("#produit").value = resultTransforme2;

      this.codeReader.stopStreams();
      const btnReset = this.element.querySelector("#resetButton");
      btnReset.style.display = "none";

      this.startScan();
      this.refreshWithParam(resultTransforme2);
    } catch (e) {
      console.error("[Stimulus] Erreur dans le format du QR Code :", e);
    }
  }

  handleScannerInput(event) {
    const value = event.target.value.trim();
    console.log("[Stimulus] Saisie reçue depuis la douchette :", value);

    if (!value) return;

    try {
      const resultTransforme = value.split("produits/")[1];
      const resultTransforme2 = resultTransforme.split("?")[0];

      this.resultsDiv.innerHTML += `<p>Product ID (douchette) : ${resultTransforme2}</p>`;
      this.element.querySelector("#produit").value = resultTransforme2;

      this.refreshWithParam(resultTransforme2);
    } catch (e) {
      console.error("[Stimulus] Format de QR code incorrect (douchette) :", e);
    }

    event.target.value = '';
  }

  async refreshWithParam(resultTransforme2) {
    const currentUrl = window.location.href;
    const updatedUrl = new URL(currentUrl);

    updatedUrl.searchParams.set("produit", resultTransforme2);

    const existingParams = new URLSearchParams(updatedUrl.search);
    existingParams.forEach((value, key) => {
      updatedUrl.searchParams.set(key, value);
    });

    sessionStorage.setItem("scanning", "true");

    console.log("[Stimulus] Redirection vers :", updatedUrl.toString());
    window.location.href = updatedUrl.toString();
  }
}
