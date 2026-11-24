import { ChangeDetectionStrategy, Component, computed, input } from '@angular/core';

/** `layout`: 'line' (default, una barra) | 'stat' (valor+meta) | 'row' (avatar+título+
 *  subtítulo) | 'circles' (fila fija de círculos, `count` la fija, nunca se infiere).
 *  `loading` (default `true`): en `false` ignora `layout` y proyecta `<ng-content>` — así
 *  una sola etiqueta cubre shimmer y contenido real (`[loading]="isPageLoading()"` alrededor
 *  del markup real de siempre), sin duplicar el árbol. No mide ni recuerda nada entre
 *  cargas (ver [[feedback_skeleton_no_dynamic_size_learning]] en memoria de proyecto).
 *
 *  CONVENCIÓN — botones/acciones estáticas NUNCA van adentro de un `sa-skeleton` ni
 *  detrás de un `@if (isLoading())`: "Editar", "Nuevo ticket", "Agregar", "Crear usuario", etc.
 *  no dependen de la data que está cargando (solo ejecutan una acción), así que se renderizan
 *  siempre, desde el primer render — igual que en Usuarios/Marcas/Roles y Permisos. Únicamente
 *  la etiqueta/valor que sí es dinámico (texto, número, avatar) va envuelto en este componente.
 *  No hay una utilidad/directiva aparte para esto — es una decisión de dónde se ubica el botón
 *  en el template, no lógica que se pueda extraer; este comentario es la referencia compartida
 *  para no reinventar el criterio feature por feature. */
@Component({
  selector: 'sa-skeleton',
  standalone: true,
  imports: [SaSkeleton],
  templateUrl: './sa-skeleton.html',
  styleUrl: './sa-skeleton.css',
  changeDetection: ChangeDetectionStrategy.OnPush,
  host: {
    '[class.sa-skeleton-fill]': 'fill()',
    // Clase de tipografía en el HOST (no solo en el hijo proyectado) — mismo textClass del shimmer.
    '[class]': 'textClass()',
    // display:contents: sin caja propia ni en 'stat' ni con loading=false (el contenido real se comporta como si no hubiera wrapper).
    '[style.display]': "!loading() || layout() === 'stat' ? 'contents' : null",
  },
})
export class SaSkeleton {
  readonly layout = input<'line' | 'stat' | 'row' | 'circles'>('line');

  // ── modo 'line' (átomo original) ──────────────────────────────────────
  readonly shape = input<'rectangle' | 'circle'>('rectangle');
  readonly width = input<string>('100%');
  readonly height = input<string>('1rem');
  readonly size = input<string | undefined>(undefined);
  readonly radius = input<string>('0.5rem');
  readonly fill = input(false);
  readonly textClass = input<string>('');
  /** Alinea el placeholder donde aparecerá el contenido real (celda de tabla centrada, etc.). */
  readonly align = input<'left' | 'center' | 'right'>('left');
  /** Líneas de un párrafo — arma N barras, la última más corta (`lastLineWidth`). */
  readonly lines = input<number>(1);
  readonly lastLineWidth = input<string>('60%');
  readonly lineGap = input<string>('0');
  /** Atajo semántico (usa tokens del design system):
   * input=form field con label flotante (~52px) · select=select compacto sin label (~40px)
   * · button/button-sm · chip. */
  readonly variant = input<'input' | 'select' | 'button' | 'button-sm' | 'chip' | undefined>(undefined);
  readonly loading = input(true);

  // ── modo 'stat' (par valor + meta) ────────────────────────────────────
  readonly valueWidth = input('3rem');
  readonly valueClass = input('text-body-1-bold');
  readonly metaWidth = input('8rem');
  readonly metaClass = input('text-caption-2-regular');

  // ── modo 'row' (avatar/ícono + título + subtítulo) ───────────────────
  readonly avatarShape = input<'square' | 'circle' | 'none'>('square');
  readonly avatarSize = input('3rem');
  readonly avatarRadius = input('0.75rem'); // ignorado si avatarShape === 'circle'
  readonly titleWidth = input('9rem');
  readonly titleClass = input('text-body-2-bold');
  readonly subtitleWidth = input('13rem');
  readonly subtitleClass = input('text-caption-2-regular');
  readonly rowGap = input('0.75rem');
  readonly textGap = input('0.5rem');

  // ── modo 'circles' (fila fija de círculos) ────────────────────────────
  readonly count = input(3);
  readonly itemSize = input('2rem');
  readonly itemRadius = input('9999px');
  readonly itemGap = input('0.25rem');

  protected readonly resolvedAvatarRadius = computed(() => (this.avatarShape() === 'circle' ? '9999px' : this.avatarRadius()));
  protected readonly resolvedRadius = computed(() => (this.shape() === 'circle' ? '50%' : this.radius()));
  protected readonly lineClass = computed(() => `sa-skeleton-line ${this.textClass()} ${this.alignClass()}`);
  protected readonly paragraphLines = computed(() => Array.from({ length: this.lines() }, (_, i) => i));
  protected readonly circlesRange = computed(() => Array.from({ length: this.count() }, (_, i) => i));
  protected readonly alignClass = computed(() => {
    if (this.align() === 'center') return 'sa-align-center';
    if (this.align() === 'right') return 'sa-align-right';
    return '';
  });

  protected readonly fillWidth = computed(() => (this.fill() ? '100%' : this.width()));
  protected readonly fillHeight = computed(() => {
    if (this.fill()) return '100%';
    switch (this.variant()) {
      case 'input':
        return 'var(--sa-sk-input-h, 3.25rem)';
      case 'select':
        return 'var(--sa-sk-select-h, 2.5rem)';
      case 'button':
        return 'var(--sa-sk-button-h, 2.25rem)';
      case 'button-sm':
        return 'var(--sa-sk-button-sm-h, 1.875rem)';
      case 'chip':
        return 'var(--sa-sk-chip-h, 1.625rem)';
      default:
        return this.height();
    }
  });
}
