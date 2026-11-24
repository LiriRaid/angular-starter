/**
 * Wiring compartida por los paneles `[popover="manual"]` propios (sa-popover,
 * sa-theme-color-picker): cierre por click afuera / Escape, y reposicionamiento
 * agendado por requestAnimationFrame en scroll/resize. No incluye el cálculo de la posición
 * en sí (eso vive en sa-popover.config.ts) porque cada consumidor tiene su propia
 * fórmula de layout — esto solo evita duplicar la parte de lifecycle/listeners.
 */

/** Versión de bajo nivel para consumidores que necesitan mantener su propia lógica de
 *  onOutsidePointerDown/onEscapeKeyDown testeable de forma directa (unit tests que llaman al
 *  handler sin pasar por un evento real de `document`) — solo agrupa el alta/baja de los 6
 *  listeners y el scheduling por rAF, sin decidir cuándo cerrar. `NativeOverlayRuntime` (más
 *  abajo) se apoya en estas mismas funciones para no reimplementar el wiring. */
export type NativeOverlayListenerHandlers = {
  reposition: () => void;
  onOutsidePointerDown: (event: PointerEvent) => void;
  onEscapeKeyDown: (event: KeyboardEvent) => void;
};

export function addNativeOverlayListeners(document: Document, handlers: NativeOverlayListenerHandlers): void {
  window.addEventListener('scroll', handlers.reposition, true);
  window.addEventListener('resize', handlers.reposition);
  window.visualViewport?.addEventListener('resize', handlers.reposition);
  window.visualViewport?.addEventListener('scroll', handlers.reposition);

  document.addEventListener('pointerdown', handlers.onOutsidePointerDown, true);
  document.addEventListener('keydown', handlers.onEscapeKeyDown, true);
}

export function removeNativeOverlayListeners(document: Document, handlers: NativeOverlayListenerHandlers): void {
  window.removeEventListener('scroll', handlers.reposition, true);
  window.removeEventListener('resize', handlers.reposition);
  window.visualViewport?.removeEventListener('resize', handlers.reposition);
  window.visualViewport?.removeEventListener('scroll', handlers.reposition);

  document.removeEventListener('pointerdown', handlers.onOutsidePointerDown, true);
  document.removeEventListener('keydown', handlers.onEscapeKeyDown, true);
}

export class NativeOverlayScheduler {
  private animationFrameId: number | null = null;

  constructor(private readonly onReposition: () => void) {}

  schedule(): void {
    this.cancel();
    this.animationFrameId = requestAnimationFrame(() => this.onReposition());
  }

  cancel(): void {
    if (this.animationFrameId === null) return;

    cancelAnimationFrame(this.animationFrameId);
    this.animationFrameId = null;
  }
}

/** Ambos paneles envuelven su trigger en un `sa-button`, cuyo `<button>`/`<a>` interno
 *  siempre lleva la clase `sa-btn` (nombre heredado del theme, no de una dependencia real de
 *  PrimeNG en runtime). */
export function resolveOverlayTriggerElement(event: MouseEvent): HTMLElement | null {
  const element = event.currentTarget as HTMLElement | null;

  if (!element) return null;

  return element.classList.contains('sa-btn') ? element : (element.querySelector<HTMLElement>('.sa-btn') ?? element);
}

export function isEventInsideOverlay(event: Event, panel: HTMLElement | null | undefined, trigger: HTMLElement | null): boolean {
  const target = event.target as Node | null;

  if (!target) return false;

  return Boolean(panel?.contains(target) || trigger?.contains(target));
}

/** Versión de alto nivel: además del wiring de bajo nivel de arriba, decide ella misma cuándo
 *  hay que cerrar el panel (click afuera / Escape) — pensada para consumidores que no necesitan
 *  testear esa decisión de forma aislada (sa-popover). */
export type NativeOverlayHandlers = {
  getPanelElement: () => HTMLElement | null | undefined;
  getTriggerElement: () => HTMLElement | null;
  isVisible: () => boolean;
  onDismiss: () => void;
  onReposition: () => void;
};

export class NativeOverlayRuntime {
  private readonly scheduler = new NativeOverlayScheduler(() => this.handlers.onReposition());

  constructor(
    private readonly document: Document,
    private readonly handlers: NativeOverlayHandlers,
  ) {}

  private readonly reposition = (): void => this.scheduleReposition();

  private readonly onOutsidePointerDown = (event: PointerEvent): void => {
    if (!this.handlers.isVisible() || this.isEventInside(event)) return;

    this.handlers.onDismiss();
  };

  private readonly onEscapeKeyDown = (event: KeyboardEvent): void => {
    if (this.handlers.isVisible() && event.key === 'Escape') {
      this.handlers.onDismiss();
    }
  };

  scheduleReposition(): void {
    if (!this.handlers.isVisible()) return;

    this.scheduler.schedule();
  }

  cancelScheduled(): void {
    this.scheduler.cancel();
  }

  addListeners(): void {
    addNativeOverlayListeners(this.document, {
      reposition: this.reposition,
      onOutsidePointerDown: this.onOutsidePointerDown,
      onEscapeKeyDown: this.onEscapeKeyDown,
    });
  }

  removeListeners(): void {
    removeNativeOverlayListeners(this.document, {
      reposition: this.reposition,
      onOutsidePointerDown: this.onOutsidePointerDown,
      onEscapeKeyDown: this.onEscapeKeyDown,
    });
  }

  cleanup(): void {
    this.cancelScheduled();
    this.removeListeners();
  }

  /** Un consumidor puede renderizar sub-paneles propios (ej. los submenús de estado/duración
   *  del user-menu) fuera del DOM del popover — con `position: fixed` propio, para no heredar
   *  ningún `overflow`/stacking del panel — marcándolos con `data-popover-sub-panel` para que un
   *  click ahí no se interprete como "click afuera" y cierre el popover antes de que su propio
   *  handler llegue a disparar. */
  private isEventInside(event: Event): boolean {
    const target = event.target as Node | null;

    if (!target) return false;

    const panel = this.handlers.getPanelElement();
    const trigger = this.handlers.getTriggerElement();

    if (panel?.contains(target) || trigger?.contains(target)) return true;

    return target instanceof Element && target.closest('[data-popover-sub-panel]') !== null;
  }
}
