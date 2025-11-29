import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["dateInput", "dateHidden", "timeInput", "hiddenInput", "timeButtons", "formFields"];
  static values = { periodesNonDisponibles: Array };

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
          this.updateDateTime();
          this.checkAndShowFormFields();
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
    this.checkAndShowFormFields();
  }
  
  checkAndShowFormFields() {
    console.log("=== checkAndShowFormFields appelé ===");
    
    const hasDate = this.flatpickrInstance?.selectedDates.length > 0;
    const hasTime = this.timeInputTarget.value?.trim();
    
    console.log("hasDate:", hasDate);
    console.log("hasTime:", hasTime);
    console.log("timeInputTarget.value:", this.timeInputTarget.value);
    console.log("hasFormFieldsTarget:", this.hasFormFieldsTarget);
    
    if (this.hasFormFieldsTarget) {
      console.log("formFieldsTarget existe:", this.formFieldsTarget);
      console.log("formFieldsTarget.style.display:", this.formFieldsTarget.style.display);
    } else {
      console.error("formFieldsTarget n'existe pas !");
    }
    
    if (hasDate && hasTime && this.hasFormFieldsTarget) {
      console.log("Conditions remplies, affichage des champs");
      this.formFieldsTarget.style.display = "block";
      // Animation d'apparition
      setTimeout(() => {
        this.formFieldsTarget.style.opacity = "1";
        console.log("Opacité mise à 1");
        this.formFieldsTarget.scrollIntoView({ behavior: 'smooth', block: 'start' });
      }, 50);
    } else {
      console.log("Conditions non remplies - hasDate:", hasDate, "hasTime:", hasTime, "hasFormFieldsTarget:", this.hasFormFieldsTarget);
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

  selectTime(event) {
    console.log("=== selectTime appelé ===");
    const time = event.currentTarget.dataset.time;
    console.log("Time sélectionné:", time);
    this.timeInputTarget.value = time;
    console.log("timeInputTarget.value mis à:", this.timeInputTarget.value);
    
    this.timeButtonsTarget.querySelectorAll('button').forEach(btn => {
      btn.classList.toggle('active', btn === event.currentTarget);
      btn.classList.toggle('btn-light', btn === event.currentTarget);
      btn.classList.toggle('btn-outline-light', btn !== event.currentTarget);
    });
    
    this.updateDateTime();
    this.checkAndShowFormFields();
  }
}
