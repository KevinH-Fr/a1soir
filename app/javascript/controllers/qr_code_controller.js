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
    this.codeReader.getVideoInputDevices()
      .then((videoInputDevices) => {
        if (videoInputDevices.length >= 1) {
          this.selectedDeviceId = videoInputDevices[0].deviceId;

          videoInputDevices.forEach((element) => {
            const sourceOption = document.createElement('option');
            sourceOption.text = element.label;
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
        // Assuming the QR code content is a URL
        window.location.href = result.text; // Open the URL in the current window
        this.stopScan();

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
  

}
