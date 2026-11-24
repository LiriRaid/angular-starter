import { ChangeDetectionStrategy, Component, computed, effect, input, model, signal } from '@angular/core';

import { AsButton } from '../as-button/as-button';
import { AsToggle } from '../as-toggle/as-toggle';

type DayKey = 'mon' | 'tue' | 'wed' | 'thu' | 'fri' | 'sat' | 'sun';

export interface AsScheduleDay {
  key: DayKey;
  label: string;
  abbr: string;
  enabled: boolean;
  start: string;
  end: string;
}

const DAY_DEFS: Array<Pick<AsScheduleDay, 'key' | 'label' | 'abbr'>> = [
  { key: 'mon', label: 'Lunes', abbr: 'Lun' },
  { key: 'tue', label: 'Martes', abbr: 'Mar' },
  { key: 'wed', label: 'Miércoles', abbr: 'Mié' },
  { key: 'thu', label: 'Jueves', abbr: 'Jue' },
  { key: 'fri', label: 'Viernes', abbr: 'Vie' },
  { key: 'sat', label: 'Sábado', abbr: 'Sáb' },
  { key: 'sun', label: 'Domingo', abbr: 'Dom' },
];

export type AsWeeklySchedulePreset = 'lv-8-17' | 'ls-9-18' | 'all-9-23' | '24h';

function defaultScheduleDays(): AsScheduleDay[] {
  return DAY_DEFS.map((d, index) => ({ ...d, enabled: index <= 4, start: '08:00', end: '17:00' }));
}

/** `H:MM` o `HH:MM`: lo que entrega un `<input type="time">` con valor; vacío (campo borrado) o cualquier otra cosa no es una hora. */
const TIME = /^\d{1,2}:\d{2}$/;

function formatTime(time: string): string {
  const [h, m] = time.split(':').map(Number);
  return `${h}:${String(m).padStart(2, '0')}`;
}

function formatSchedule(days: AsScheduleDay[]): string {
  const groups: Array<{ start: number; end: number; time: string }> = [];
  let i = 0;
  while (i < days.length) {
    const d = days[i];
    if (!d.enabled) {
      i++;
      continue;
    }
    let j = i;
    while (j + 1 < days.length && days[j + 1].enabled && days[j + 1].start === d.start && days[j + 1].end === d.end) j++;
    const isFullDay = d.start === d.end;
    const time = isFullDay ? '24 horas' : `${formatTime(d.start)}-${formatTime(d.end)}`;
    groups.push({ start: i, end: j, time });
    i = j + 1;
  }

  if (groups.length === 0) return 'Cerrado toda la semana';
  if (groups.length === 1 && groups[0].start === 0 && groups[0].end === 6) return `Todos los días ${groups[0].time}`;

  return groups
    .map((g) => {
      const dayLabel = g.start === g.end ? days[g.start].abbr : `${days[g.start].abbr}-${days[g.end].abbr}`;
      return `${dayLabel} ${g.time}`;
    })
    .join(' · ');
}

/** Total de horas por semana de un horario; un tramo que termina antes de empezar (o a la misma hora) cruza la medianoche. Exportado para quien necesite el total fuera del propio editor (ej. una tarjeta-resumen) sin reparsear el string. */
export function computeWeeklyHours(days: AsScheduleDay[]): number {
  let totalMinutes = 0;
  for (const d of days) {
    if (!d.enabled || !TIME.test(d.start) || !TIME.test(d.end)) continue;
    const [sh, sm] = d.start.split(':').map(Number);
    const [eh, em] = d.end.split(':').map(Number);
    const startMin = sh * 60 + sm;
    let endMin = eh * 60 + em;
    if (endMin <= startMin) endMin += 24 * 60;
    totalMinutes += endMin - startMin;
  }
  return Math.round((totalMinutes / 60) * 10) / 10;
}

/** Parser best-effort del string que genera `formatSchedule` (su propio formato); exportado por el mismo motivo que `computeWeeklyHours`. */
export function parseSchedule(value: string): AsScheduleDay[] {
  const days = defaultScheduleDays().map((d) => ({ ...d, enabled: false }));
  if (!value?.trim()) return days;

  const abbrIndex = new Map(DAY_DEFS.map((d, index) => [d.abbr, index]));
  const parseTimeRange = (text: string): [string, string] => {
    if (/24\s*horas/i.test(text)) return ['00:00', '00:00'];
    const match = text.match(/(\d{1,2}):(\d{2})\s*-\s*(\d{1,2}):(\d{2})/);
    if (!match) return ['08:00', '17:00'];
    return [`${match[1].padStart(2, '0')}:${match[2]}`, `${match[3].padStart(2, '0')}:${match[4]}`];
  };

  for (const segment of value.split('·').map((s) => s.trim())) {
    const allDayMatch = segment.match(/^Todos los d[ií]as (.+)$/i);
    if (allDayMatch) {
      const [start, end] = parseTimeRange(allDayMatch[1]);
      days.forEach((d) => Object.assign(d, { enabled: true, start, end }));
      continue;
    }

    const rangeMatch = segment.match(/^(\p{L}{3})-(\p{L}{3})\s+(.+)$/u);
    if (rangeMatch) {
      const startIdx = abbrIndex.get(rangeMatch[1]);
      const endIdx = abbrIndex.get(rangeMatch[2]);
      if (startIdx !== undefined && endIdx !== undefined) {
        const [start, end] = parseTimeRange(rangeMatch[3]);
        for (let k = startIdx; k <= endIdx; k++) Object.assign(days[k], { enabled: true, start, end });
      }
      continue;
    }

    const singleMatch = segment.match(/^(\p{L}{3})\s+(.+)$/u);
    if (singleMatch) {
      const idx = abbrIndex.get(singleMatch[1]);
      if (idx !== undefined) {
        const [start, end] = parseTimeRange(singleMatch[2]);
        Object.assign(days[idx], { enabled: true, start, end });
      }
    }
  }

  return days;
}

/** Editor de horario semanal reutilizable. El valor es un string compacto (ej. "Lun-Vie 8:00-17:00 · Sáb 9:00-13:00") para no exigir un tipo de columna nuevo a cada entidad que lo use: basta un texto en su esquema.
 *
 *  Bidireccional con `[(value)]`. Un string vacío se interpreta como "todavía no hay dato guardado" y se muestra el predeterminado (Lun-Vie 8:00-17:00), no "cerrado toda la semana". */
@Component({
  selector: 'as-weekly-schedule',
  imports: [AsButton, AsToggle],
  templateUrl: './as-weekly-schedule.html',
  styleUrl: './as-weekly-schedule.css',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class AsWeeklySchedule {
  readonly value = model<string>('');
  readonly label = input('Horario de atención');

  readonly days = signal<AsScheduleDay[]>(defaultScheduleDays());
  readonly summary = computed(() => formatSchedule(this.days()));
  readonly weeklyHours = computed(() => computeWeeklyHours(this.days()));

  constructor() {
    // Un valor externo vacío pasa por dos casos: (1) todavía no hay dato real (entidad nueva o carga en curso): se resetea
    // `days` al predeterminado y se siembra hacia afuera, así "guardar sin tocar nada" persiste un horario razonable y no un
    // string vacío; (2) el string ya es el propio (`summary()`): no hay nada que reparsear, evita el bucle de reparsear lo que
    // este mismo componente acaba de emitir. Ambos conviven en el mismo effect: el `value.set` del caso (1) dispara una segunda
    // pasada que cae en el (2) y ahí converge.
    //
    // Ojo con el caso (1): el componente puede reutilizarse sin destruirse entre entidades distintas (ej. un modal que queda
    // montado y solo se abre y cierra para cada registro). Sin resetear `days`, un valor vacío (registro B sin horario) volvería a
    // emitir el `summary()` que quedó del registro anterior (A) y le filtraría su horario al nuevo.
    effect(() => {
      const external = this.value();
      if (!external) {
        this.days.set(defaultScheduleDays());
        this.value.set(this.summary());
        return;
      }
      if (external === this.summary()) return;
      this.days.set(parseSchedule(external));
    });
  }

  toggleDay(index: number): void {
    this.days.update((days) => days.map((d, i) => (i === index ? { ...d, enabled: !d.enabled } : d)));
    this.emit();
  }

  updateTime(index: number, field: 'start' | 'end', value: string): void {
    // Un campo borrado emite '': se conserva la hora anterior en vez de guardar un horario roto.
    if (!TIME.test(value)) return;

    this.days.update((days) => days.map((d, i) => (i === index ? { ...d, [field]: value } : d)));
    this.emit();
  }

  /** `change` de un campo de hora: aplica el valor y, si era inválido (campo borrado), el campo vuelve a mostrar la hora vigente. */
  onTimeChange(index: number, field: 'start' | 'end', event: Event): void {
    const input = event.target as HTMLInputElement;

    this.updateTime(index, field, input.value);
    input.value = this.days()[index][field];
  }

  copyDay(index: number): void {
    const source = this.days()[index];
    this.days.update((days) => days.map((d) => (d.enabled ? { ...d, start: source.start, end: source.end } : d)));
    this.emit();
  }

  applyPreset(preset: AsWeeklySchedulePreset): void {
    this.days.update((days) =>
      days.map((d, index) => {
        switch (preset) {
          case 'lv-8-17':
            return { ...d, enabled: index <= 4, start: '08:00', end: '17:00' };
          case 'ls-9-18':
            return { ...d, enabled: index <= 5, start: '09:00', end: '18:00' };
          case 'all-9-23':
            return { ...d, enabled: true, start: '09:00', end: '23:00' };
          case '24h':
            return { ...d, enabled: true, start: '00:00', end: '00:00' };
        }
      }),
    );
    this.emit();
  }

  private emit(): void {
    this.value.set(this.summary());
  }
}
