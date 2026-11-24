import { Directive } from '@angular/core';

/** Réplica nativa del efecto pRipple de PrimeNG: al hacer clic crea un círculo
 *  (.as-ink, ver button-styles.css) centrado en el punto del clic que se expande
 *  y desvanece, y se elimina solo al terminar la animación. El host necesita
 *  position: relative + overflow: hidden (los .as-btn ya lo traen de base). */
@Directive({
  selector: '[asRipple]',
  standalone: true,
  host: { '(click)': 'spawn($event)' },
})
export class AsRipple {
  protected spawn(event: MouseEvent): void {
    const host = event.currentTarget;
    if (!(host instanceof HTMLElement) || host.matches(':disabled, .as-disabled')) return;

    const rect = host.getBoundingClientRect();
    const diameter = Math.max(rect.width, rect.height);
    const ink = host.ownerDocument.createElement('span');
    ink.className = 'as-ink';
    ink.style.width = `${diameter}px`;
    ink.style.height = `${diameter}px`;
    ink.style.left = `${event.clientX - rect.left - diameter / 2}px`;
    ink.style.top = `${event.clientY - rect.top - diameter / 2}px`;
    host.appendChild(ink);
    ink.addEventListener('animationend', () => ink.remove());
  }
}
