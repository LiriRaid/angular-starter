import { isPlatformBrowser } from '@angular/common';
import { DestroyRef, ElementRef, PLATFORM_ID, afterNextRender, computed, inject, signal, type Signal } from '@angular/core';

/**
 * Tamaño del botón de acción según el ancho del host ('small' en <768px, 'medium' si no).
 * Observa el host con ResizeObserver. Debe llamarse en contexto de inyección.
 */
export function responsiveActionSize(): Signal<'small' | 'medium'> {
  const host = inject<ElementRef<HTMLElement>>(ElementRef);
  const destroyRef = inject(DestroyRef);
  const isBrowser = isPlatformBrowser(inject(PLATFORM_ID));
  const width = signal(0);

  afterNextRender(() => {
    if (!isBrowser) return;

    const el = host.nativeElement;
    width.set(el.getBoundingClientRect().width);

    if (typeof ResizeObserver === 'undefined') return;

    const observer = new ResizeObserver((entries) => {
      const entry = entries[0];
      if (entry) width.set(entry.contentRect.width);
    });

    observer.observe(el);
    destroyRef.onDestroy(() => observer.disconnect());
  });

  return computed(() => (width() > 0 && width() < 768 ? 'small' : 'medium'));
}
