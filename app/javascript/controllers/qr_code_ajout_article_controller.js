// stimulus/controllers/qr_code_controller.js
import { Controller } from "@hotwired/stimulus";
import { BrowserQRCodeReader } from "@zxing/library";

export default class extends Controller {
  connect() {

    this.codeReader = new BrowserQRCodeReader();
    this.selectedDeviceId = null;
    this.resultsDiv = document.getElementById('results');
    this.sourceSelect = this.element.querySelector("#sourceSelect");

    this.populateSources();

    // Restart scan if previously active
    if (sessionStorage.getItem("scanning") === "true") {
      this.startScan();
    }
  }
  
  populateSources() {
    if (navigator.mediaDevices && navigator.mediaDevices.enumerateDevices && navigator.mediaDevices.getUserMedia) {
        navigator.mediaDevices.getUserMedia({ video: true })
            .then(() => {
                navigator.mediaDevices.enumerateDevices()
                    .then((devices) => {
                        const videoInputDevices = devices.filter(device => device.kind === 'videoinput');

                        if (videoInputDevices.length >= 1) {
                            // Retrieve the previously used device from sessionStorage
                            const storedDeviceId = sessionStorage.getItem("selectedCamera");

                            // Default to the first camera if no previous selection exists
                            this.selectedDeviceId = storedDeviceId || videoInputDevices[0].deviceId;

                            // Populate the dropdown with camera options
                            this.sourceSelect.innerHTML = ""; // Clear previous options
                            videoInputDevices.forEach((element) => {
                                const sourceOption = document.createElement('option');
                                sourceOption.text = element.label || `Camera ${this.sourceSelect.length + 1}`;
                                sourceOption.value = element.deviceId;
                                this.sourceSelect.appendChild(sourceOption);

                                // Preselect the previously used camera
                                if (element.deviceId === this.selectedDeviceId) {
                                    sourceOption.selected = true;
                                }
                            });

                            this.sourceSelect.onchange = () => {
                                this.selectedDeviceId = this.sourceSelect.value;
                                sessionStorage.setItem("selectedCamera", this.selectedDeviceId); // Save selection
                            };

                            // Show camera selection dropdown
                            const sourceSelectPanel = this.element.querySelector('#sourceSelectPanel');
                            sourceSelectPanel.style.display = 'inline';

                            // Automatically start scanning if it was active before
                            if (sessionStorage.getItem("scanning") === "true") {
                                this.startScan();
                            }
                        } else {
                            console.error("No video input devices detected.");
                        }
                    })
                    .catch((err) => {
                        console.error("Error enumerating devices:", err);
                    });
            })
            .catch((err) => {
                console.error('Camera access denied:', err);
            });
    } else {
        console.error('getUserMedia or enumerateDevices() not supported on this browser.');
    }
  }


  startScan() {

    console.log('Scan started!');
        
    const btnStart = this.element.querySelector("#startButton");
    btnStart.style.display = "none";

    const btnReset = this.element.querySelector("#resetButton");
    btnReset.style.display = "inline";

    if (!this.selectedDeviceId) {
      console.error("No video input devices available");
      return;
    }

    this.codeReader.decodeFromInputVideoDevice(this.selectedDeviceId, 'video').then((result) => {
      if (result) {
        console.log('Found QR code!', result);
        this.handleResult(result);
      }
    });

  }

  stopScan() {
    this.codeReader.reset();
    this.resultsDiv.textContent = "";
    console.log('Scan stopped.');

    const btnStart = this.element.querySelector("#startButton");
    btnStart.style.display = "inline";

    const btnReset = this.element.querySelector("#resetButton");
    btnReset.style.display = "none";

    // Remove scanning state (only when manually stopped)
    sessionStorage.removeItem("scanning");
  }


  handleResult(result) {

    // Display product information on the page
    // transforme value
    var  resultTransforme = result.toString().split('produits/')[1];
    var  resultTransforme2 = resultTransforme.split('?')[0];
    
    const resultElement = document.createElement('p');
    resultElement.textContent = `Product ID: ${resultTransforme2}`;
    this.resultsDiv.appendChild(resultElement);

    console.log(resultTransforme2);

    this.element.querySelector("#produit").value = resultTransforme2

    this.codeReader.stopStreams();
    const btnReset = this.element.querySelector("#resetButton");
    btnReset.style.display = "none";

    // Ensure scanning continues
    this.startScan();

    this.refreshWithParam(resultTransforme2);

  }


  async refreshWithParam(resultTransforme2) {
    const currentUrl = window.location.href;
  
    // Create a URL object
    const updatedUrl = new URL(currentUrl);
  
    // Add the new parameter
    updatedUrl.searchParams.set('produit', resultTransforme2);
  
    // Preserve existing parameters
    const existingParams = new URLSearchParams(updatedUrl.search);
    existingParams.forEach((value, key) => {
      updatedUrl.searchParams.set(key, value);
    });
  
    // Save scanning state
    sessionStorage.setItem("scanning", "true");

    // Redirect to the updated URL
    window.location.href = updatedUrl.toString();
  }
  

}
