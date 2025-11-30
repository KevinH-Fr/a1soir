import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["dateInput", "dateHidden", "timeInput", "hiddenInput", "timeButtons"];
  static values = { 
    periodesNonDisponibles: Array,
    creneauxOccupes: Object
  };

  connect() {
    // Charger Flatpickr de manière dynamique
    this.loadFlatpickr().then(() => {
      this.initCalendar();
    });
  }


  disconnect() {
    if (this.flatpickrInstance) {
      this.flatpickrInstance.destroy();
    }
  }

  async loadFlatpickr() {
    if (window.flatpickr) {
      return;
    }
    
    // Import dynamique de Flatpickr
    const flatpickrModule = await import("flatpickr");
    window.flatpickr = flatpickrModule.default;
    
    // Charger le CSS
    const link = document.createElement("link");
    link.rel = "stylesheet";
    link.href = "https://cdn.jsdelivr.net/npm/flatpickr/dist/flatpickr.min.css";
    document.head.appendChild(link);
  }

  initCalendar() {
    if (!window.flatpickr) return;
    
    const tempInput = document.createElement("input");
    tempInput.type = "text";
    tempInput.style.display = "none";
    this.dateInputTarget.appendChild(tempInput);
    
    const options = {
      mode: "single",
      dateFormat: "Y-m-d",
      minDate: "today",
      inline: true,
      disable: this.getDatesDesactivees(),
      locale: {
        firstDayOfWeek: 1,
        weekdays: {
          shorthand: ["Dim", "Lun", "Mar", "Mer", "Jeu", "Ven", "Sam"],
          longhand: ["Dimanche", "Lundi", "Mardi", "Mercredi", "Jeudi", "Vendredi", "Samedi"]
        },
        months: {
          shorthand: ["Jan", "Fév", "Mar", "Avr", "Mai", "Juin", "Juil", "Aoû", "Sep", "Oct", "Nov", "Déc"],
          longhand: ["Janvier", "Février", "Mars", "Avril", "Mai", "Juin", "Juillet", "Août", "Septembre", "Octobre", "Novembre", "Décembre"]
        }
      },
      onChange: (selectedDates, dateStr) => {
        console.log("=== onChange calendrier ===");
        console.log("Date sélectionnée:", dateStr);
        if (selectedDates.length > 0) {
          if (this.hasDateHiddenTarget) this.dateHiddenTarget.value = dateStr;
          this.loadCreneauxDisponibles(dateStr);
          this.showStep2();
          this.updateDateTime();
        }
      }
    };
    
    this.flatpickrInstance = window.flatpickr(tempInput, options);
    
    const calendarElement = this.flatpickrInstance.calendarContainer;
    if (calendarElement) {
      this.dateInputTarget.appendChild(calendarElement);
    }
  }

  updateDateTime() {
    const selectedDate = this.flatpickrInstance?.selectedDates[0];
    if (!selectedDate) return;

    const [hours, minutes] = (this.timeInputTarget.value || "10:00").split(":");
    const dateTime = new Date(selectedDate);
    dateTime.setHours(parseInt(hours) || 10, parseInt(minutes) || 0);

    const year = dateTime.getFullYear();
    const month = String(dateTime.getMonth() + 1).padStart(2, '0');
    const day = String(dateTime.getDate()).padStart(2, '0');
    const h = String(dateTime.getHours()).padStart(2, '0');
    const m = String(dateTime.getMinutes()).padStart(2, '0');

    this.hiddenInputTarget.value = `${year}-${month}-${day}T${h}:${m}`;
  }
  
  showStep2() {
    // Déclencher un clic sur le bouton de tab Bootstrap - Bootstrap gère tout automatiquement
    const step2Tab = document.querySelector('#step2-tab');
    if (step2Tab) {
      step2Tab.click();
    }
  }

  showStep3() {
    // Déclencher un clic sur le bouton de tab Bootstrap - Bootstrap gère tout automatiquement
    const step3Tab = document.querySelector('#step3-tab');
    if (step3Tab) {
      step3Tab.click();
    }
  }

  goBack(event) {
    // Empêcher le comportement par défaut du lien
    event.preventDefault();
    // Revenir à l'étape précédente en trouvant le tab actif dans le tab-content
    const activePane = document.querySelector('#rdv-tab-content .tab-pane.active');
    if (activePane) {
      const currentStep = parseInt(activePane.id.replace('step', '').replace('-pane', ''));
      if (currentStep > 1) {
        const previousTab = document.querySelector(`#step${currentStep - 1}-tab`);
        if (previousTab) {
          previousTab.click();
        }
      }
    }
  }

  getDatesDesactivees() {
    if (!this.periodesNonDisponiblesValue?.length) return [];
    
    const dates = [];
    this.periodesNonDisponiblesValue.forEach(periode => {
      const debut = new Date(periode.debut + "T00:00:00");
      const fin = new Date(periode.fin + "T00:00:00");
      const current = new Date(debut);
      
      while (current <= fin) {
        dates.push(new Date(current));
        current.setDate(current.getDate() + 1);
      }
    });
    
    return dates;
  }

  loadCreneauxDisponibles(date) {
    const creneauxOccupes = this.creneauxOccupesValue[date] || [];
    this.updateCreneauxButtons(creneauxOccupes);
  }

  updateCreneauxButtons(creneauxOccupes) {
    if (!this.hasTimeButtonsTarget) return;
    
    this.timeButtonsTarget.querySelectorAll('button[data-time]').forEach(button => {
      const isOccupe = creneauxOccupes.includes(button.dataset.time);
      
      button.disabled = isOccupe;
      button.classList.toggle('btn-secondary', isOccupe);
      button.classList.toggle('btn-outline-dark', !isOccupe);
      button.style.opacity = isOccupe ? '0.5' : '1';
      button.title = isOccupe ? 'Créneau déjà réservé' : '';
    });
  }

  selectTime(event) {
    if (event.currentTarget.disabled) return;
    
    const time = event.currentTarget.dataset.time;
    
    this.timeInputTarget.value = time;
    console.log("timeInputTarget.value mis à:", this.timeInputTarget.value);
    
    this.timeButtonsTarget.querySelectorAll('button').forEach(btn => {
      btn.classList.toggle('active', btn === event.currentTarget);
      btn.classList.toggle('btn-dark', btn === event.currentTarget);
      btn.classList.toggle('btn-outline-dark', btn !== event.currentTarget);
    });
    
    this.updateDateTime();
    this.showStep3();
  }
}
