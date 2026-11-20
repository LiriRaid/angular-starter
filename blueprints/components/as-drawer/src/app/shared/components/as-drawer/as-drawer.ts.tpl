import { ChangeDetectionStrategy, Component, DestroyRef, ElementRef, TemplateRef, effect, inject, input, model, output, signal, viewChild, ViewEncapsulation } from '@angular/core';
import { NgTemplateOutlet } from '@angular/common';

import { AsIcon } from '../as-icon/as-icon';

export type AsDrawerPosition = 'left' | 'right' | 'top' | 'bottom' | 'full';

/** Tiempo que se deja montado el `<dialog>` tras cerrar, antes de destruirlo del DOM —
 *  debe ser >= la transición CSS de salida (`transform 0.3s`) para que el slide-out
 *  alcance a correr; si se destruyeran juntos, Angular removería el nodo a mitad de la
 *  animación. */
const CLOSE_TRANSITION_MS = 320;

@Component({
  selector: 'as-drawer',
  standalone: true,
  imports: [NgTemplateOutlet, AsIcon],
  templateUrl: './as-drawer.html',
  styleUrl: './as-drawer.css',
  changeDetection: ChangeDetectionStrategy.OnPush,
  encapsulation: ViewEncapsulation.None,
})
export class AsDrawer {
  readonly visible = model(false);
  readonly position = input<AsDrawerPosition>('left');
  readonly dismissible = input(true);
  readonly closeOnEscape = input(true);
  readonly closable = input(true);
  readonly headerTemplate = input<TemplateRef<unknown> | null>(null);
  readonly closeIconTemplate = input<TemplateRef<unknown> | null>(null);
  /** Nombre accesible del panel; sin él el lector de pantalla anuncia un diálogo sin título. */
  readonly ariaLabel = input<string | null>(null);
  /** Ancho de los paneles laterales (`30rem`, `40vw`…); sin valor se usa el predeterminado. Nunca pasa del ancho de la ventana. */
  readonly width = input<string | null>(null);

  readonly onShow = output<void>();
  readonly onHide = output<void>();

  /** El consumidor solo conoce `visible` — crear el `<dialog>` recién al abrir y
   *  destruirlo recién al terminar de cerrar es un detalle de implementación del drawer,
   *  no algo que cada feature (call-widget, user-preferences, etc.) deba reimplementar. */
  protected readonly mounted = signal(false);

  private readonly dialogRef = viewChild<ElementRef<HTMLDialogElement>>('dialogRef');
  private readonly destroyRef = inject(DestroyRef);
  private closeTimer?: ReturnType<typeof setTimeout>;

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

    /** `show()` en vez de `showModal()`: un `<dialog>` modal vuelve INERTE (sin click, sin
     *  hover) todo lo demás en la página — incluyendo popovers ajenos como as-toast,
     *  aunque se pinten visualmente encima. Con `show()` el drawer deja de vivir en el "top
     *  layer" (por eso el backdrop y el cierre por Escape se manejan a mano abajo), pero el
     *  resto de la página — toasts incluidos — sigue siendo interactivo. */
    effect(() => {
      const dialog = this.dialogRef()?.nativeElement;
      if (!dialog) return;

      if (this.visible()) {
        if (!dialog.open) {
          requestAnimationFrame(() => {
            if (dialog.isConnected && !dialog.open) {
              dialog.show();
              this.onShow.emit();
            }
          });
        }
        document.addEventListener('keydown', this.onDocumentKeydown);
      } else {
        if (dialog.open) dialog.close();
        document.removeEventListener('keydown', this.onDocumentKeydown);
      }
    });

    this.destroyRef.onDestroy(() => {
      clearTimeout(this.closeTimer);
      document.removeEventListener('keydown', this.onDocumentKeydown);
    });
  }

  private readonly onDocumentKeydown = (event: KeyboardEvent): void => {
    if (event.key === 'Escape' && this.closeOnEscape()) this.close();
  };

  onBackdropClick(): void {
    if (this.dismissible()) this.close();
  }

  onDialogClose(): void {
    this.visible.set(false);
    this.onHide.emit();
  }

  close(): void {
    this.dialogRef()?.nativeElement.close();
  }
}
