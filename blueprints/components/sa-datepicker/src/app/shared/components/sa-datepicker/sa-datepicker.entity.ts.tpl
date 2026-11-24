/** Mismo vocabulario de variante que `sa-input`/`sa-select` — acá casi siempre se
 *  usa `'over'` (label estático arriba, fuera del campo), pero se dejan `'in'`/`'on'` disponibles
 *  para no romper el patrón si algún consumidor futuro los necesita. */
export type SaDatepickerVariant = 'over' | 'in' | 'on';

/** Una celda del grid de 6 semanas × 7 días que arma `buildCalendarDays`. */
export interface SaCalendarDay {
  date: Date;
  currentMonth: boolean;
  selected: boolean;
  today: boolean;
  enabled: boolean;
}

export type SaAmPm = 'AM' | 'PM';

/** Resultado de parsear el texto tipeado a mano ("dd/mm/aaaa" u opcionalmente con hora). */
export interface SaParsedDateTime {
  date: Date;
  hasTime: boolean;
}
