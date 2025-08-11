import { Controller } from "@hotwired/stimulus";
import { BrowserQRCodeReader } from "@zxing/library";

export default class extends Controller {
  connect() {
    console.log("[QR Code] Contrôleur qr code connecté");

    this.codeReader = new BrowserQRCodeReader();
    this.selectedDeviceId = null;
    this.resultsDiv = this.element.querySelector("#results");
    this.sourceSelect = this.element.querySelector("#sourceSelect");

    this.populateSources();

    const scannerInput = this.element.querySelector("#scannerInput");
    if (scannerInput) {
      console.log("[QR Code] Champ douchette détecté, focus appliqué");
      scannerInput.focus();
    }
  }

  populateSources() {
    console.log("[QR Code] Recherche de caméras disponibles...");

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

              console.log("[QR Code] Caméras détectées :", videoInputDevices);

              if (videoInputDevices.length >= 1) {
                this.selectedDeviceId = videoInputDevices[0].deviceId;

                this.sourceSelect.innerHTML = "";
                videoInputDevices.forEach((device) => {
                  const option = document.createElement("option");
                  option.text = device.label || `Camera ${this.sourceSelect.length + 1}`;
                  option.value = device.deviceId;
                  this.sourceSelect.appendChild(option);
                });

                this.sourceSelect.onchange = () => {
                  this.selectedDeviceId = this.sourceSelect.value;
                  console.log("[QR Code] Caméra sélectionnée :", this.selectedDeviceId);
                };

                const panel = this.element.querySelector("#sourceSelectPanel");
                panel.style.display = "inline";
              }
            })
            .catch((err) => {
              console.error("[QR Code] Erreur d'énumération des périphériques :", err);
            });
        })
        .catch((err) => {
          console.error("[QR Code] Accès caméra refusé :", err);
        });
    } else {
      console.error("[QR Code] API média non supportée");
    }
  }

  startScan() {
    console.log("[QR Code] Début du scan");

    const btnStart = this.element.querySelector("#startButton");
    btnStart.style.display = "none";

    const btnReset = this.element.querySelector("#resetButton");
    btnReset.style.display = "inline";

    if (!this.selectedDeviceId) {
      console.error("[QR Code] Aucune caméra sélectionnée");
      return;
    }

    this.codeReader.decodeFromInputVideoDevice(this.selectedDeviceId, "video").then((result) => {
      if (result) {
        console.log("[QR Code] Code détecté via caméra :", result);
        this.handleScanResult(result.text, "caméra");
        this.stopScan();
      }
    });
  }

  stopScan() {
    console.log("[QR Code] Scan arrêté");

    this.codeReader.reset();
    this.resultsDiv.textContent = "";

    const btnStart = this.element.querySelector("#startButton");
    btnStart.style.display = "inline";

    const btnReset = this.element.querySelector("#resetButton");
    btnReset.style.display = "none";
  }

  handleScannerInput(event) {
    const value = event.target.value.trim();
    console.log("[QR Code] Lecture douchette :", value);

    if (!value) return;

    this.handleScanResult(value, "douchette");
    event.target.value = '';
  }

  handleScanResult(value, source = "inconnu") {
    console.log(`[QR Code] Résultat du scan (${source}) :`, value);

    // Affichage dans la page
    const resultElement = document.createElement("p");
    resultElement.textContent = `Code (${source}) : ${value}`;
    this.resultsDiv.appendChild(resultElement);

    // Redirection si c’est une URL valide
    try {
      const url = new URL(value);
      console.log("[QR Code] Redirection vers :", url.href);
      window.location.href = url.href;
    } catch (_) {
      console.warn("[QR Code] Valeur non reconnue comme URL :", value);
    }
  }
}
