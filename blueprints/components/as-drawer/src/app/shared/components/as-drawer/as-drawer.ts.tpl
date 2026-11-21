import { ChangeDetectionStrategy, Component, DestroyRef, ElementRef, TemplateRef, ViewContainerRef, ViewEncapsulation, computed, effect, inject, input, model, output, signal, viewChild } from '@angular/core';
import { NgTemplateOutlet } from '@angular/common';
import { Overlay, type OverlayRef } from '@angular/cdk/overlay';
import { TemplatePortal } from '@angular/cdk/portal';

import { AsIcon } from '../as-icon/as-icon';

export type AsDrawerPosition = 'left' | 'right' | 'top' | 'bottom' | 'full';

/** `comfortable`: el aire de siempre (cabecera y cuerpo de 1.25rem). `compact`: el de los paneles de la app (cabecera de 0.75rem a los lados, cuerpo de 1rem). */
export type AsDrawerDensity = 'comfortable' | 'compact';

/** Tiempo que se deja montado el `<dialog>` tras cerrar, antes de destruirlo del DOM —
 *  debe ser >= la transición CSS de salida (`transform 0.3s`) para que el slide-out
 *  alcance a correr; si se destruyeran juntos, Angular removería el nodo a mitad de la
 *  animación. */
const CLOSE_TRANSITION_MS = 320;

/**
 * Panel con tres zonas fijas, siempre en este orden:
 *  - header (`[drawer-header]` o `headerTemplate`): títulos y lo que haga falta a la izquierda; el botón de cerrar va siempre a su derecha.
 *  - content (lo demás que se proyecta): ocupa todo el alto entre el header y el footer y, si es largo, se desplaza.
 *  - footer (`[drawer-footer]`): los botones de acción, fijos abajo y fuera del desplazamiento; sin botones no se pinta.
 *
 * El panel se monta en el contenedor de overlays (hijo de `<body>`), así que se pinta sobre toda la página
 * aunque el `<as-drawer>` viva dentro de un área de contenido con `transform`, `overflow` o su propio z-index.
 */
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
  /** Aire de las tres zonas. */
  readonly density = input<AsDrawerDensity>('comfortable');
  /** El contenido maneja su propio espaciado (y su propio desplazamiento): el cuerpo no le pone padding. */
  readonly flush = input(false);
  /** Ícono del botón de cerrar (un `X` normal, o el que corresponda a lo que hace cerrar este panel). */
  readonly closeIcon = input<string>('X');
  readonly closeLabel = input<string>('Cerrar');
  /** Clase del consumidor sobre el panel, para sus estilos propios. */
  readonly styleClass = input<string>('');

  readonly onShow = output<void>();
  readonly onHide = output<void>();

  /** El consumidor solo conoce `visible` — crear el `<dialog>` recién al abrir y
   *  destruirlo recién al terminar de cerrar es un detalle de implementación del drawer,
   *  no algo que cada feature (call-widget, user-preferences, etc.) deba reimplementar. */
  protected readonly mounted = signal(false);

  protected readonly panelClass = computed(() => ['as-drawer', `as-drawer-${this.position()}`, this.density() === 'compact' ? 'as-drawer--compact' : '', this.flush() ? 'as-drawer--flush' : '', this.styleClass().trim()].filter(Boolean).join(' '));

  private readonly drawerTemplate = viewChild<TemplateRef<unknown>>('drawerTemplate');
  private readonly dialogRef = viewChild<ElementRef<HTMLDialogElement>>('dialogRef');
  private readonly overlay = inject(Overlay);
  private readonly viewContainerRef = inject(ViewContainerRef);
  private readonly destroyRef = inject(DestroyRef);
  private overlayRef?: OverlayRef;
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

    /** El panel lo monta el `Overlay` del CDK (mismo mecanismo que as-modal): queda como hijo
     *  de <body>, por encima de cualquier área de contenido, y Angular lo desmonta con la app aunque
     *  el host ya no exista. */
    effect(() => {
      if (this.mounted()) {
        const template = this.drawerTemplate();
        if (!this.overlayRef && template) {
          this.overlayRef = this.overlay.create({ scrollStrategy: this.overlay.scrollStrategies.noop() });
          this.overlayRef.attach(new TemplatePortal(template, this.viewContainerRef));
        }
      } else {
        this.overlayRef?.dispose();
        this.overlayRef = undefined;
      }
    });

    /** `show()` en vez de `showModal()`: un `<dialog>` modal vuelve INERTE (sin click, sin
     *  hover) todo lo demás en la página — incluyendo popovers ajenos como as-toast,
     *  aunque se pinten visualmente encima. Con `show()` el resto de la página — toasts
     *  incluidos — sigue siendo interactivo; el backdrop y el cierre por Escape se manejan a mano. */
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
      this.overlayRef?.dispose();
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
