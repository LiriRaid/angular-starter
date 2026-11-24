import { ChangeDetectionStrategy, Component, DestroyRef, ElementRef, ViewEncapsulation, afterRenderEffect, inject, input, model, signal } from '@angular/core';
import { SaAvatar } from '../sa-avatar/sa-avatar';
import { SaIcon } from '../sa-icon/sa-icon';
import { SaRipple } from '../sa-button/sa-ripple';
import { SaTooltip } from '../sa-tooltip/sa-tooltip.directive';

export interface SaTabAvatar {
  readonly label: string;
  readonly background: string;
  /** El avatar de una tab siempre es chico — SIEMPRE el ícono de marca, nunca el logo (el logo
   *  es horizontal, no cabe recortado ahí). */
  readonly iconUrl?: string | null;
}

export interface SaTab {
  readonly id: string;
  readonly label?: string;
  readonly icon?: string | null;
  readonly count?: number;
  /** `danger` resalta un contador que espera una decisión (pendientes, errores); por defecto `primary`. */
  readonly countTone?: 'primary' | 'danger';
  readonly avatar?: SaTabAvatar;
  readonly color?: string;
  readonly tooltip?: string;
}

@Component({
  selector: 'sa-tabs',
  standalone: true,
  imports: [SaAvatar, SaIcon, SaRipple, SaTooltip],
  templateUrl: './sa-tabs.html',
  styleUrl: './sa-tabs.css',
  encapsulation: ViewEncapsulation.None,
  changeDetection: ChangeDetectionStrategy.OnPush,
  host: {
    '[class.sa-tabs--pills]': 'variant() === "pills"',
    '[class.sa-tabs--compact]': 'size() === "compact"',
  },
})
export class SaTabs {
  readonly tabs = input<readonly SaTab[]>([]);
  readonly ariaLabel = input<string>('');
  readonly variant = input<'default' | 'pills'>('default');
  readonly size = input<'default' | 'compact'>('default');

  readonly active = model<string>('');

  readonly tabLabelClass = input<string>('text-caption-1-bold');

  readonly showPrevButton = signal(false);
  readonly showNextButton = signal(false);

  private readonly host = inject<ElementRef<HTMLElement>>(ElementRef);

  constructor() {
    // Recalcula la barra activa, el scroll y las flechas prev/next cuando cambia la lista
    // de tabs (el ancho del contenido) — corre después de que el @for ya pintó el DOM.
    afterRenderEffect(() => {
      this.tabs();
      this.active();
      this.resetScrollWhenFits();
      this.syncActiveBar();
      this.updateScrollButtons();
    });

    // Y también ante cambios de tamaño del contenedor (responsive).
    if (typeof ResizeObserver === 'undefined') return;
    const observer = new ResizeObserver(() => {
      this.resetScrollWhenFits();
      this.syncActiveBar();
      this.updateScrollButtons();
    });
    observer.observe(this.host.nativeElement);
    inject(DestroyRef).onDestroy(() => observer.disconnect());
  }

  private get content(): HTMLElement | null {
    return this.host.nativeElement.querySelector<HTMLElement>('.sa-tablist-content');
  }

  // Si el carril ya cabe, resetea scrollLeft para que las flechas queden ocultas.
  private resetScrollWhenFits(): void {
    const content = this.content;
    if (!content) return;
    if (content.scrollWidth - content.clientWidth > 1) return;
    content.scrollLeft = 0;
  }

  onScroll(): void {
    this.updateScrollButtons();
  }

  private updateScrollButtons(): void {
    const content = this.content;
    if (!content) return;

    const overflow = content.scrollWidth - content.clientWidth > 1;
    this.showPrevButton.set(overflow && content.scrollLeft > 0);
    this.showNextButton.set(overflow && content.scrollLeft + content.clientWidth < content.scrollWidth - 1);
  }

  scrollByPage(direction: -1 | 1): void {
    const content = this.content;
    if (!content) return;

    const delta = content.clientWidth * 0.8 * direction;
    content.scrollTo({ left: content.scrollLeft + delta, behavior: 'smooth' });
  }

  selectTab(tab: SaTab, event: Event): void {
    this.active.set(tab.id);
    const el = event.currentTarget as HTMLElement | null;
    if (!el) return;
    this.scrollTabIntoView(el);
    this.syncActiveBar(el);
  }

  // Trae el tab a la vista desplazando solo el carril de tabs (nunca la página).
  private scrollTabIntoView(tab: HTMLElement): void {
    const content = this.content;
    if (!content) return;

    const pad = 52;
    const start = tab.offsetLeft;
    const end = start + tab.offsetWidth;
    const viewStart = content.scrollLeft;
    const viewEnd = viewStart + content.clientWidth;

    if (start - pad < viewStart) {
      content.scrollTo({ left: Math.max(0, start - pad), behavior: 'smooth' });
    } else if (end + pad > viewEnd) {
      content.scrollTo({ left: end + pad - content.clientWidth, behavior: 'smooth' });
    }
  }

  // Ajusta la barra activa al ancho/posición exactos del tab seleccionado.
  private syncActiveBar(tab?: HTMLElement | null): void {
    const root = this.host.nativeElement;
    const bar = root.querySelector<HTMLElement>('.sa-tablist-active-bar');
    const target = tab ?? root.querySelector<HTMLElement>('.sa-tab--active');
    if (!bar || !target) return;

    bar.style.width = `${target.offsetWidth}px`;
    bar.style.left = `${target.offsetLeft}px`;

    if (this.variant() === 'pills') {
      const color = target.style.getPropertyValue('--sa-tab-color').trim();
      bar.style.background = color || '';
    }
  }
}
