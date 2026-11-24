import { ChangeDetectionStrategy, Component, DestroyRef, ElementRef, TemplateRef, ViewContainerRef, ViewEncapsulation, booleanAttribute, computed, effect, inject, input, model, output, signal, viewChild } from '@angular/core';
import { Overlay, type OverlayRef } from '@angular/cdk/overlay';
import { TemplatePortal } from '@angular/cdk/portal';

import { SaButton } from '../sa-button/sa-button';
import { SaIcon } from '../sa-icon/sa-icon';
import { computeDragPosition, computeResizeSize } from './sa-modal.config';

/** Tiempo que se deja montado el panel tras cerrar, antes de destruirlo del DOM —
 *  debe ser >= la transición CSS de salida (`opacity/scale 0.3s`). Mismo criterio que
 *  sa-drawer. */
const CLOSE_TRANSITION_MS = 320;

@Component({
  selector: 'sa-modal',
  standalone: true,
  imports: [SaIcon, SaButton],
  templateUrl: './sa-modal.html',
  styleUrl: './sa-modal.css',
  encapsulation: ViewEncapsulation.None,
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class SaModal {
  readonly visible = model<boolean>(false);

  readonly title = input<string>('');
  readonly titleIcon = input<string | null>(null);
  /** Punto de color antes del título (en lugar del ícono), p. ej. el color de una etiqueta o estado. */
  readonly titleDotColor = input<string | null>(null);
  /** Ancho por defecto pensado para el caso común (formulario con grid de opciones);
   * cada consumidor puede seguir pasando `width` para achicarlo o agrandarlo. */
  readonly width = input<string>('34rem');
  readonly styleClass = input<string>('');
  readonly showFooter = input(false, { transform: booleanAttribute });
  /** El contenido maneja su propio espaciado: el área del contenido no le pone relleno (y su barra de desplazamiento queda en el borde del modal). */
  readonly flush = input(false, { transform: booleanAttribute });

  /** Con `false` el panel no se mueve al arrastrar su encabezado: se queda centrado (el cierre y el resize no cambian). */
  readonly draggable = input(true, { transform: booleanAttribute });

  readonly closable = input(true, { transform: booleanAttribute });
  readonly dismissableMask = input(true, { transform: booleanAttribute });

  /** 'preview': sin header/padding, el panel se ajusta al tamaño natural del contenido (ej. una imagen) en vez de a `width`, con botón de cerrar flotando encima. */
  readonly variant = input<'default' | 'preview'>('default');

  readonly hide = output<void>();

  private readonly modalTemplate = viewChild<TemplateRef<unknown>>('modalTemplate');
  private readonly panelRef = viewChild<ElementRef<HTMLDivElement>>('panelRef');
  private readonly overlay = inject(Overlay);
  private readonly viewContainerRef = inject(ViewContainerRef);
  private readonly destroyRef = inject(DestroyRef);
  private overlayRef?: OverlayRef;
  private closeTimer?: ReturnType<typeof setTimeout>;

  /** Igual que antes con el `<dialog>` nativo: el panel solo existe en el DOM mientras
   * `mounted` es true, así nunca queda un elemento persistente con estilos inline de un
   * arrastre/resize anterior — cada apertura arranca con un elemento 100% nuevo. Se
   * desmonta recién después de que termine la animación de salida (no de golpe al cerrar). */
  readonly mounted = signal(false);

  readonly hostClasses = computed(() => {
    const parts = ['sa-modal'];
    if (this.variant() === 'preview') parts.push('sa-modal--preview');
    if (!this.draggable()) parts.push('sa-modal--fixed');
    if (this.flush()) parts.push('sa-modal--flush');

    const extra = this.styleClass().trim();
    if (extra) parts.push(extra);

    return parts.join(' ');
  });

  /** En variant="preview" no hay header (sin lugar para el botón de cerrar propio del panel,
   * se usa el botón flotante aparte) — igual que en PrimeNG, donde `closable` internamente
   * quedaba forzado a `false` para ese caso, apagando como efecto colateral tanto el cierre por
   * click en el fondo como por Escape (solo quedaba el botón flotante para cerrar). */
  private readonly effectiveClosable = () => this.variant() === 'default' && this.closable();

  private lastPageX = 0;
  private lastPageY = 0;

  private readonly onDocumentDrag = (event: MouseEvent): void => this.handleDrag(event);
  private readonly onDocumentDragEnd = (): void => this.endDrag();
  private readonly onDocumentResize = (event: MouseEvent): void => this.handleResize(event);
  private readonly onDocumentResizeEnd = (): void => this.endResize();
  private readonly onDocumentKeydown = (event: KeyboardEvent): void => {
    if (event.key === 'Escape' && this.effectiveClosable()) this.close();
  };

  constructor() {
    effect(() => {
      if (this.visible()) {
        clearTimeout(this.closeTimer);
        this.mounted.set(true);
      } else {
        clearTimeout(this.closeTimer);
        this.closeTimer = setTimeout(() => this.mounted.set(false), CLOSE_TRANSITION_MS);
      }
    });

    /** El panel lo monta el `Overlay` del CDK de Angular en vez de reparentarlo a mano a
     * <body> (como antes) — su contenedor global (`OverlayContainer`, `providedIn: 'root'`)
     * queda atado al injector raíz de la app, así que Angular SIEMPRE llama a su
     * `ngOnDestroy` (y este remueve su elemento del DOM) cuando ese injector se destruye,
     * sin importar si el nodo vive fuera del subárbol que un `ngOnDestroy` normal recorre.
     * Antes, al reparentar a mano, un remount de Angular en caliente (HMR) mientras el
     * modal seguía abierto podía saltarse el ciclo normal de cierre y dejar un panel
     * huérfano montado en <body> — con el Overlay eso ya no puede pasar. De regalo, ya no
     * se necesita el `<dialog>` nativo con `show()` (que exigía simular a mano su propio
     * backdrop y Escape porque `show()` no vive en el "top layer", solo para evitar que
     * `showModal()` volviera inerte al resto de la página, toasts incluidos) — un overlay
     * simple no bloquea nada del resto de la página por sí solo. */
    effect(() => {
      if (this.mounted()) {
        const template = this.modalTemplate();
        if (!this.overlayRef && template) {
          this.overlayRef = this.overlay.create({ scrollStrategy: this.overlay.scrollStrategies.noop() });
          this.overlayRef.attach(new TemplatePortal(template, this.viewContainerRef));
        }
        document.addEventListener('keydown', this.onDocumentKeydown);
      } else {
        this.overlayRef?.dispose();
        this.overlayRef = undefined;
        document.removeEventListener('keydown', this.onDocumentKeydown);
      }
    });

    this.destroyRef.onDestroy(() => {
      clearTimeout(this.closeTimer);
      document.removeEventListener('keydown', this.onDocumentKeydown);
      this.overlayRef?.dispose();
    });
  }

  onBackdropClick(): void {
    if (this.effectiveClosable() && this.dismissableMask()) this.close();
  }

  close(): void {
    this.visible.set(false);
    this.hide.emit();
  }

  onHeaderMouseDown(event: MouseEvent): void {
    if (!this.draggable()) return;

    const target = event.target as HTMLElement;
    // Cualquier botón de acción del header (cerrar, "Ver UI", "Editar/Ver Perfil", etc.) no debe
    // iniciar un arrastre — si no, el simple click ya fija `position: fixed` + left/top en píxeles
    // y mata el `margin: auto` que centra el modal, dejándolo descentrado ante cualquier cambio de
    // altura posterior (cambio de tab, cambio de modo) que ya no puede recentrarse solo.
    if (target.closest('.sa-modal-header-actions')) return;

    const panel = this.panelRef()?.nativeElement;
    if (!panel) return;

    this.lastPageX = event.pageX;
    this.lastPageY = event.pageY;

    // El panel se centra por defecto con margin:auto + inset:0 implícito. Sacar el margin sin
    // fijar antes left/top/right/bottom explícitos hace que salte a (0,0) apenas se suelta el
    // auto-centrado (el inset:0 que quedaba oculto detrás del margin:auto pasa a mandar). Por
    // eso se fija la posición visual actual ANTES de tocar el margin.
    const rect = panel.getBoundingClientRect();
    panel.style.position = 'fixed';
    panel.style.left = `${rect.left}px`;
    panel.style.top = `${rect.top}px`;
    panel.style.right = 'auto';
    panel.style.bottom = 'auto';
    panel.style.margin = '0';

    document.body.style.userSelect = 'none';
    document.addEventListener('mousemove', this.onDocumentDrag);
    document.addEventListener('mouseup', this.onDocumentDragEnd);
  }

  private endDrag(): void {
    document.body.style.userSelect = '';
    document.removeEventListener('mousemove', this.onDocumentDrag);
    document.removeEventListener('mouseup', this.onDocumentDragEnd);
  }

  private handleDrag(event: MouseEvent): void {
    const panel = this.panelRef()?.nativeElement;
    if (!panel) return;

    const deltaX = event.pageX - this.lastPageX;
    const deltaY = event.pageY - this.lastPageY;
    const rect = panel.getBoundingClientRect();
    const { left, top } = computeDragPosition(rect, deltaX, deltaY, document.documentElement.clientWidth, document.documentElement.clientHeight);

    panel.style.position = 'fixed';
    if (left !== null) {
      panel.style.left = `${left}px`;
      this.lastPageX = event.pageX;
    }
    if (top !== null) {
      panel.style.top = `${top}px`;
      this.lastPageY = event.pageY;
    }
  }

  onResizeMouseDown(event: MouseEvent): void {
    event.preventDefault();

    const panel = this.panelRef()?.nativeElement;
    if (!panel) return;

    // Mismo problema que en el arrastre: mientras el panel sigue centrado por margin:auto,
    // crece de forma simétrica desde el centro en vez de anclarse desde la esquina superior
    // izquierda que el usuario está arrastrando con el handle. Se fija la posición actual antes
    // de tocar el margin para que el crecimiento se ancle correctamente.
    const rect = panel.getBoundingClientRect();
    panel.style.position = 'fixed';
    panel.style.left = `${rect.left}px`;
    panel.style.top = `${rect.top}px`;
    panel.style.right = 'auto';
    panel.style.bottom = 'auto';
    panel.style.margin = '0';

    this.lastPageX = event.pageX;
    this.lastPageY = event.pageY;
    document.body.style.userSelect = 'none';
    document.addEventListener('mousemove', this.onDocumentResize);
    document.addEventListener('mouseup', this.onDocumentResizeEnd);
  }

  private endResize(): void {
    document.body.style.userSelect = '';
    document.removeEventListener('mousemove', this.onDocumentResize);
    document.removeEventListener('mouseup', this.onDocumentResizeEnd);
  }

  private handleResize(event: MouseEvent): void {
    const panel = this.panelRef()?.nativeElement;
    if (!panel) return;

    const deltaX = event.pageX - this.lastPageX;
    const deltaY = event.pageY - this.lastPageY;
    const rect = panel.getBoundingClientRect();
    const { width, height } = computeResizeSize(rect, deltaX, deltaY, document.documentElement.clientWidth, document.documentElement.clientHeight);

    if (width !== null) {
      panel.style.width = `${width}px`;
      this.lastPageX = event.pageX;
    }
    if (height !== null) {
      panel.style.height = `${height}px`;
      this.lastPageY = event.pageY;
    }
  }
}
