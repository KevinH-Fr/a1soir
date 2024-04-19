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

  }
  
  populateSources() {
    // Check if the browser supports mediaDevices API and getUserMedia
    if (navigator.mediaDevices && navigator.mediaDevices.enumerateDevices && navigator.mediaDevices.getUserMedia) {
        // Request permission to use video inputs (camera)
        navigator.mediaDevices.getUserMedia({ video: true })
            .then(() => {
                // If permission is granted, enumerate video input devices
                navigator.mediaDevices.enumerateDevices()
                    .then((devices) => {
                        const videoInputDevices = devices.filter(device => device.kind === 'videoinput');

                        if (videoInputDevices.length >= 1) {
                            this.selectedDeviceId = videoInputDevices[0].deviceId;

                            videoInputDevices.forEach((element) => {
                                const sourceOption = document.createElement('option');
                                sourceOption.text = element.label || `Camera ${this.sourceSelect.length + 1}`;
                                sourceOption.value = element.deviceId;
                                this.sourceSelect.appendChild(sourceOption);
                            });

                            this.sourceSelect.onchange = () => {
                                this.selectedDeviceId = this.sourceSelect.value;
                            };

                            const sourceSelectPanel = this.element.querySelector('#sourceSelectPanel');
                            sourceSelectPanel.style.display = 'inline';
                        }
                    })
                    .catch((err) => {
                        console.error(err);
                    });
            })
            .catch((err) => {
                console.error('Permission to access camera denied:', err);
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
  
    // Redirect to the updated URL
    window.location.href = updatedUrl.toString();
  }
  

}
