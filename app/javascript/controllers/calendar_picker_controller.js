import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["dateInput", "dateHidden", "timeInput", "hiddenInput", "timeButtons"];
  static values = {
    periodesNonDisponibles: Array,
    creneauxOccupes:        Object,
    creneauxAutorises:      Object,
    joursDesactives:        Array
  };

  connect() {
    this.loadFlatpickr().then(() => this.initCalendar());
  }

  disconnect() {
    this.flatpickrInstance?.destroy();
  }

  // ---- Chargement de Flatpickr ------------------------------------------

  async loadFlatpickr() {
    if (window.flatpickr) return;

    const flatpickrModule = await import("flatpickr");
    window.flatpickr = flatpickrModule.default;

    const link = document.createElement("link");
    link.rel   = "stylesheet";
    link.href  = "https://cdn.jsdelivr.net/npm/flatpickr/dist/flatpickr.min.css";
    document.head.appendChild(link);
  }

  // ---- Initialisation du calendrier -------------------------------------

  initCalendar() {
    if (!window.flatpickr) return;

    // Flatpickr nécessite un input DOM ; on en crée un caché qu'on remplace
    // par le container inline rendu par la librairie.
    const tempInput = document.createElement("input");
    tempInput.type  = "text";
    tempInput.style.display = "none";
    this.dateInputTarget.appendChild(tempInput);

    const options = {
      mode:       "single",
      dateFormat: "Y-m-d",
      minDate:    "today",
      inline:     true,
      disable:    this.getDatesDesactivees(),
      locale: {
        firstDayOfWeek: 1,
        weekdays: {
          shorthand: ["Dim", "Lun", "Mar", "Mer", "Jeu", "Ven", "Sam"],
          longhand:  ["Dimanche", "Lundi", "Mardi", "Mercredi", "Jeudi", "Vendredi", "Samedi"]
        },
        months: {
          shorthand: ["Jan", "Fév", "Mar", "Avr", "Mai", "Juin", "Juil", "Aoû", "Sep", "Oct", "Nov", "Déc"],
          longhand:  ["Janvier", "Février", "Mars", "Avril", "Mai", "Juin", "Juillet", "Août", "Septembre", "Octobre", "Novembre", "Décembre"]
        }
      },
      onChange: (selectedDates, dateStr) => {
        if (selectedDates.length === 0) return;
        if (this.hasDateHiddenTarget) this.dateHiddenTarget.value = dateStr;
        this.loadCreneauxDisponibles(dateStr);
        this.showStep2();
        this.updateDateTime();
      }
    };

    this.flatpickrInstance = window.flatpickr(tempInput, options);

    const calendarElement = this.flatpickrInstance.calendarContainer;
    if (calendarElement) this.dateInputTarget.appendChild(calendarElement);
  }

  // ---- Navigation entre les étapes -------------------------------------

  showStep2() {
    document.querySelector("#step2-tab")?.click();
  }

  showStep3() {
    document.querySelector("#step3-tab")?.click();
  }

  goBack(event) {
    event.preventDefault();
    const activePane = document.querySelector("#rdv-tab-content .tab-pane.active");
    if (!activePane) return;

    const currentStep = parseInt(activePane.id.replace("step", "").replace("-pane", ""));
    if (currentStep > 1) {
      document.querySelector(`#step${currentStep - 1}-tab`)?.click();
    }
  }

  // ---- Gestion des dates désactivées -----------------------------------

  getDatesDesactivees() {
    const dates = [];

    // Désactiver les périodes non disponibles (dates individuelles).
    this.periodesNonDisponiblesValue?.forEach(periode => {
      const debut   = new Date(periode.debut + "T00:00:00");
      const fin     = new Date(periode.fin   + "T00:00:00");
      const current = new Date(debut);

      while (current <= fin) {
        dates.push(new Date(current));
        current.setDate(current.getDate() + 1);
      }
    });

    // Désactiver les jours de la semaine sans capacité.
    if (this.joursDesactivesValue?.length) {
      const joursDesactives = this.joursDesactivesValue;
      dates.push(date => joursDesactives.includes(date.getDay()));
    }

    return dates;
  }

  // ---- Créneaux horaires -----------------------------------------------

  loadCreneauxDisponibles(date) {
    const creneauxOccupes  = this.creneauxOccupesValue[date] || [];
    const creneauxAutorises = (this.creneauxAutorisesValue || {})[date] || null;
    this.updateCreneauxButtons(creneauxOccupes, date, creneauxAutorises);
  }

  // Met à jour l'état visuel de chaque bouton créneau selon sa disponibilité.
  updateCreneauxButtons(creneauxOccupes, selectedDate, creneauxAutorises) {
    if (!this.hasTimeButtonsTarget) return;

    const today    = new Date();
    today.setHours(0, 0, 0, 0);
    const selected = selectedDate ? new Date(selectedDate + "T00:00:00") : null;
    const isToday  = selected?.getTime() === today.getTime();
    const now      = new Date();

    this.timeButtonsTarget.querySelectorAll("button[data-time]").forEach(button => {
      const creneauTime = button.dataset.time;
      const isOccupe    = creneauxOccupes.includes(creneauTime);
      const isAutorise  = !creneauxAutorises || creneauxAutorises.includes(creneauTime);

      // Vérifie si le créneau est dans le passé (uniquement pour aujourd'hui).
      let isPast = false;
      if (isToday && creneauTime) {
        const [h, m]    = creneauTime.split(":");
        const creneauDT = new Date(today);
        creneauDT.setHours(parseInt(h), parseInt(m), 0, 0);
        isPast = creneauDT < now;
      }

      const unavailable = isOccupe || isPast || !isAutorise;
      button.disabled   = unavailable;

      if (unavailable) {
        // Créneau indisponible : fond blanc, texte et bordure gris, opacité forcée à 1
        // (le disabled Bootstrap réduirait l'opacité, ce qu'on ne veut pas ici).
        button.classList.remove("btn-outline-dark", "btn-dark", "active");
        button.style.color           = "#6c757d";
        button.style.borderColor     = "#6c757d";
        button.style.backgroundColor = "#ffffff";
        button.style.opacity         = "1";
        button.style.cursor          = "not-allowed";
        button.style.borderRadius    = "2px";
      } else {
        // Créneau disponible : style Bootstrap par défaut, réinitialisation des overrides.
        button.classList.add("btn-outline-dark");
        button.classList.remove("btn-dark", "active");
        button.style.color           = "";
        button.style.borderColor     = "";
        button.style.backgroundColor = "";
        button.style.opacity         = "1";
        button.style.cursor          = "";
        button.style.borderRadius    = "2px";
      }

      // Infobulle d'accessibilité.
      if (isOccupe)       button.title = "Créneau déjà réservé";
      else if (isPast)    button.title = "Créneau dans le passé";
      else if (!isAutorise) button.title = "Créneau non disponible ce jour";
      else                button.title = "";
    });
  }

  selectTime(event) {
    if (event.currentTarget.disabled) return;

    const time = event.currentTarget.dataset.time;
    this.timeInputTarget.value = time;

    // Met en surbrillance le bouton sélectionné.
    this.timeButtonsTarget.querySelectorAll("button").forEach(btn => {
      const isSelected = btn === event.currentTarget;
      btn.classList.toggle("active",           isSelected);
      btn.classList.toggle("btn-dark",         isSelected);
      btn.classList.toggle("btn-outline-dark", !isSelected);
    });

    this.updateDateTime();
    this.showStep3();
  }

  // ---- Construction du datetime final ----------------------------------

  updateDateTime() {
    const selectedDate = this.flatpickrInstance?.selectedDates[0];
    if (!selectedDate) return;

    const defaultTime  = this.timeButtonsTarget.querySelector("button[data-time]")?.dataset.time || "10:00";
    const [hours, mins] = (this.timeInputTarget.value || defaultTime).split(":");
    const dt = new Date(selectedDate);
    dt.setHours(parseInt(hours) || 10, parseInt(mins) || 0);

    const pad = n => String(n).padStart(2, "0");
    this.hiddenInputTarget.value =
      `${dt.getFullYear()}-${pad(dt.getMonth() + 1)}-${pad(dt.getDate())}T${pad(dt.getHours())}:${pad(dt.getMinutes())}`;
  }
}
