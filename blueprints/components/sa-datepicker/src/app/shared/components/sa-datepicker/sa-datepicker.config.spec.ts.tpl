import { buildCalendarDays, buildDatepickerPanelLayout, buildYearOptions, convertTo24Hour, formatDateValue, formatDisplayDate, formatHourMaskInput, formatTime12Hour, getMonthNames, getWeekdayNames, isDateEnabled, isSameDay, parseDateValue, parseInputDateTime } from './sa-datepicker.config';

describe('sa-datepicker.config', () => {
  describe('formatDateValue / parseDateValue', () => {
    it('formatea a yyyy-mm-dd (mismo contrato que producía el <input type="date"> nativo)', () => {
      expect(formatDateValue(new Date(2026, 8, 4))).toBe('2026-09-04');
      expect(formatDateValue(new Date(2026, 0, 1))).toBe('2026-01-01');
    });

    it('parsea yyyy-mm-dd de vuelta a la misma fecha local (sin corrimiento de zona horaria)', () => {
      const parsed = parseDateValue('2026-09-04');
      expect(parsed).not.toBeNull();
      expect(parsed?.getFullYear()).toBe(2026);
      expect(parsed?.getMonth()).toBe(8);
      expect(parsed?.getDate()).toBe(4);
    });

    it('devuelve null para vacío/undefined/basura', () => {
      expect(parseDateValue('')).toBeNull();
      expect(parseDateValue(null)).toBeNull();
      expect(parseDateValue(undefined)).toBeNull();
      expect(parseDateValue('no-es-una-fecha')).toBeNull();
    });

    it('round-trip: parsear lo que uno mismo formateó da la misma fecha', () => {
      const original = new Date(2026, 11, 25);
      const roundTripped = parseDateValue(formatDateValue(original));
      expect(roundTripped && isSameDay(roundTripped, original)).toBe(true);
    });
  });

  describe('parseInputDateTime — tipeo manual', () => {
    it('acepta dd/mm/aaaa sin hora', () => {
      const parsed = parseInputDateTime('04/09/2026', false);
      expect(parsed).not.toBeNull();
      expect(parsed?.hasTime).toBe(false);
      expect(parsed?.date.getFullYear()).toBe(2026);
      expect(parsed?.date.getMonth()).toBe(8);
      expect(parsed?.date.getDate()).toBe(4);
    });

    it('acepta dd/mm/aaaa hh:mm AM/PM cuando allowTime=true', () => {
      const parsed = parseInputDateTime('04/09/2026 07:40 AM', true);
      expect(parsed?.hasTime).toBe(true);
      expect(parsed?.date.getHours()).toBe(7);
      expect(parsed?.date.getMinutes()).toBe(40);
    });

    it('convierte 12 PM a las 12:00 (mediodía) y 12 AM a las 00:00 (medianoche)', () => {
      expect(parseInputDateTime('04/09/2026 12:00 PM', true)?.date.getHours()).toBe(12);
      expect(parseInputDateTime('04/09/2026 12:00 AM', true)?.date.getHours()).toBe(0);
    });

    it('ignora la hora tipeada cuando allowTime=false (modo sin edición manual)', () => {
      const parsed = parseInputDateTime('04/09/2026 07:40 AM', false);
      expect(parsed?.hasTime).toBe(false);
    });

    it('rechaza fechas que no existen (31 de febrero)', () => {
      expect(parseInputDateTime('31/02/2026', false)).toBeNull();
    });

    it('rechaza mes/día fuera de rango', () => {
      expect(parseInputDateTime('01/13/2026', false)).toBeNull();
      expect(parseInputDateTime('32/01/2026', false)).toBeNull();
    });

    it('rechaza hora fuera de rango (13 en formato 12h, minutos >59)', () => {
      expect(parseInputDateTime('04/09/2026 13:00 PM', true)).toBeNull();
      expect(parseInputDateTime('04/09/2026 07:60 AM', true)).toBeNull();
    });

    it('rechaza texto que no matchea el formato en absoluto', () => {
      expect(parseInputDateTime('hola', false)).toBeNull();
      expect(parseInputDateTime('2026-09-04', false)).toBeNull();
    });

    it('devuelve null para texto vacío', () => {
      expect(parseInputDateTime('', false)).toBeNull();
      expect(parseInputDateTime('   ', false)).toBeNull();
    });
  });

  describe('formatDisplayDate / formatTime12Hour / convertTo24Hour', () => {
    it('formatea solo fecha cuando includeTime=false', () => {
      expect(formatDisplayDate(new Date(2026, 8, 4), false)).toBe('04/09/2026');
    });

    it('agrega hora 12h cuando includeTime=true', () => {
      const date = new Date(2026, 8, 4, 15, 30);
      expect(formatDisplayDate(date, true)).toBe('04/09/2026 03:30 PM');
    });

    it('formatTime12Hour convierte medianoche/mediodía correctamente', () => {
      expect(formatTime12Hour(new Date(2026, 0, 1, 0, 0)).hour).toBe('12:00');
      expect(formatTime12Hour(new Date(2026, 0, 1, 0, 0)).ampm).toBe('AM');
      expect(formatTime12Hour(new Date(2026, 0, 1, 12, 0)).hour).toBe('12:00');
      expect(formatTime12Hour(new Date(2026, 0, 1, 12, 0)).ampm).toBe('PM');
    });

    it('convertTo24Hour es la inversa de formatTime12Hour para todas las horas del día', () => {
      for (let hour24 = 0; hour24 < 24; hour24++) {
        const { hour, ampm } = formatTime12Hour(new Date(2026, 0, 1, hour24, 0));
        const hour12 = Number(hour.split(':')[0]);
        expect(convertTo24Hour(hour12, ampm)).toBe(hour24);
      }
    });
  });

  describe('formatHourMaskInput', () => {
    it('inserta ":" automáticamente tras 2 dígitos', () => {
      expect(formatHourMaskInput('0')).toBe('0');
      expect(formatHourMaskInput('07')).toBe('07');
      expect(formatHourMaskInput('074')).toBe('07:4');
      expect(formatHourMaskInput('0740')).toBe('07:40');
    });

    it('ignora caracteres no numéricos y limita a 4 dígitos', () => {
      expect(formatHourMaskInput('07:40:99')).toBe('07:40');
      expect(formatHourMaskInput('ab07cd40ef99')).toBe('07:40');
    });
  });

  describe('isDateEnabled / min-max', () => {
    const minDate = new Date(2026, 8, 1);
    const maxDate = new Date(2026, 8, 30);

    it('permite fechas dentro del rango (bordes inclusive)', () => {
      expect(isDateEnabled(minDate, minDate, maxDate)).toBe(true);
      expect(isDateEnabled(maxDate, minDate, maxDate)).toBe(true);
      expect(isDateEnabled(new Date(2026, 8, 15), minDate, maxDate)).toBe(true);
    });

    it('rechaza fechas antes de minDate o después de maxDate', () => {
      expect(isDateEnabled(new Date(2026, 7, 31), minDate, maxDate)).toBe(false);
      expect(isDateEnabled(new Date(2026, 9, 1), minDate, maxDate)).toBe(false);
    });

    it('ignora la hora del día al comparar (solo importa el día calendario)', () => {
      const lateInDay = new Date(2026, 8, 1, 23, 59, 59);
      expect(isDateEnabled(lateInDay, minDate, maxDate)).toBe(true);
    });

    it('sin minDate/maxDate, cualquier fecha está habilitada', () => {
      expect(isDateEnabled(new Date(2000, 0, 1))).toBe(true);
    });
  });

  describe('buildCalendarDays', () => {
    it('genera 42 celdas (6 semanas)', () => {
      const days = buildCalendarDays(8, 2026, null);
      expect(days).toHaveLength(42);
    });

    it('empieza en domingo y contiene todos los días del mes pedido', () => {
      const days = buildCalendarDays(8, 2026, null); // septiembre 2026
      expect(days[0].date.getDay()).toBe(0);

      const daysInMonth = days.filter((day) => day.currentMonth);
      expect(daysInMonth).toHaveLength(30); // septiembre tiene 30 días
      expect(daysInMonth[0].date.getDate()).toBe(1);
      expect(daysInMonth.at(-1)?.date.getDate()).toBe(30);
    });

    it('marca como seleccionado solo el día que coincide con `selected`', () => {
      const selected = new Date(2026, 8, 4);
      const days = buildCalendarDays(8, 2026, selected);
      const selectedDays = days.filter((day) => day.selected);

      expect(selectedDays).toHaveLength(1);
      expect(selectedDays[0].date.getDate()).toBe(4);
    });

    it('marca como `today` el día que coincide con la fecha de referencia inyectada', () => {
      const referenceToday = new Date(2026, 8, 10);
      const days = buildCalendarDays(8, 2026, null, undefined, undefined, referenceToday);
      const todays = days.filter((day) => day.today);

      expect(todays).toHaveLength(1);
      expect(todays[0].date.getDate()).toBe(10);
    });

    it('respeta minDate/maxDate marcando `enabled: false` fuera de rango', () => {
      const minDate = new Date(2026, 8, 10);
      const maxDate = new Date(2026, 8, 20);
      const days = buildCalendarDays(8, 2026, null, minDate, maxDate);

      const day5 = days.find((day) => day.currentMonth && day.date.getDate() === 5);
      const day15 = days.find((day) => day.currentMonth && day.date.getDate() === 15);
      const day25 = days.find((day) => day.currentMonth && day.date.getDate() === 25);

      expect(day5?.enabled).toBe(false);
      expect(day15?.enabled).toBe(true);
      expect(day25?.enabled).toBe(false);
    });
  });

  describe('buildYearOptions', () => {
    it('genera el rango [centro-before, centro+after] inclusive', () => {
      const years = buildYearOptions(2026, 2, 1);
      expect(years).toEqual([2024, 2025, 2026, 2027]);
    });

    it('usa los defaults -50/+10 cuando no se pasan', () => {
      const years = buildYearOptions(2026);
      expect(years[0]).toBe(1976);
      expect(years.at(-1)).toBe(2036);
      expect(years).toHaveLength(61);
    });
  });

  describe('getMonthNames / getWeekdayNames', () => {
    it('devuelve 12 nombres de mes capitalizados en español', () => {
      const months = getMonthNames();
      expect(months).toHaveLength(12);
      expect(months[0]).toBe('Enero');
      expect(months[8]).toBe('Septiembre');
      expect(months[11]).toBe('Diciembre');
    });

    it('devuelve 7 nombres de día empezando en domingo', () => {
      const weekdays = getWeekdayNames();
      expect(weekdays).toHaveLength(7);
      expect(weekdays[0].toLowerCase()).toContain('dom');
      expect(weekdays[6].toLowerCase()).toContain('sáb');
    });
  });

  describe('buildDatepickerPanelLayout', () => {
    const rect = (top: number, left: number, width = 160, height = 40) => ({ top, left, bottom: top + height, right: left + width, width, height }) as DOMRect;

    it('sin bounds mide contra la ventana: abajo si cabe', () => {
      expect(buildDatepickerPanelLayout(rect(100, 200), 300, 320, 1000, 800)).toMatchObject({ placement: 'bottom', top: 144 });
    });

    it('con bounds mide contra el área visible del campo: si el contenedor no deja lugar abajo, abre arriba aunque la ventana sí tenga', () => {
      const bounds = { top: 0, left: 0, right: 1000, bottom: 400 };
      expect(buildDatepickerPanelLayout(rect(300, 200), 300, 320, 1000, 800, 4, 8, bounds)).toMatchObject({ placement: 'top' });
    });

    it('con bounds y lugar en ambos lados prefiere abajo', () => {
      const bounds = { top: 0, left: 0, right: 1000, bottom: 800 };
      expect(buildDatepickerPanelLayout(rect(100, 200), 300, 320, 1000, 800, 4, 8, bounds).placement).toBe('bottom');
    });
  });
});
