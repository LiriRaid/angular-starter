import { ChangeDetectionStrategy, Component, DestroyRef, ElementRef, Injector, ViewEncapsulation, afterNextRender, computed, effect, inject, signal, viewChild, viewChildren } from '@angular/core';
import { NgStyle } from '@angular/common';
import { type ButtonSeverity } from '../sa-button/sa-button';

import { SaButton, SaIcon } from '..';
import { EAsToastType, type IAsToastAction, type ToastItem } from './sa-toast.types';
import { AlertService } from '@shared/services';
import { escapeHtml } from '@shared/utils/escape-html';

const GAP = 8;

@Component({
  selector: 'sa-toast',
  standalone: true,
  imports: [NgStyle, SaIcon, SaButton],
  templateUrl: './sa-toast.html',
  styleUrl: './sa-toast.css',
  encapsulation: ViewEncapsulation.None,
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class SaToast {
  protected readonly alertService = inject(AlertService);
  protected readonly messages = this.alertService.messages;
  protected readonly position = computed(() => this.alertService.toastPosition());
  protected readonly hovered = signal(false);
  protected readonly newestId = signal<string | null>(null);
  protected readonly SaToastType = EAsToastType;

  protected readonly itemHeights = signal<number[]>([]);
  protected readonly isBottom = computed(() => this.position().startsWith('bottom'));

  protected readonly layouts = computed(() => {
    const msgs = this.messages();
    const heights = this.itemHeights();
    const bottom = this.isBottom();

    if (!this.hovered() || msgs.length <= 1) {
      return msgs.map((_, i) => ({
        y: bottom ? -i * GAP : i * GAP,
        scaleX: 1 - i * 0.04,
        opacity: Math.max(0.55, 1 - i * 0.15),
        z: 10 - i,
      }));
    }

    const result: { y: number; scaleX: number; opacity: number; z: number }[] = [];
    let offset = 0;
    for (let i = 0; i < msgs.length; i++) {
      const h = heights[i] ?? 85;
      result.push({ y: bottom ? -offset : offset, scaleX: 1, opacity: 1, z: 10 - i });
      offset += h + GAP;
    }
    return result;
  });

  protected readonly trackHeight = computed(() => {
    const heights = this.itemHeights();
    const msgs = this.messages();
    if (heights.length === 0) return null;
    if (!this.hovered() || msgs.length <= 1) return heights[0] ?? 85;
    return heights.slice(0, msgs.length).reduce((s, h) => s + h, 0) + GAP * Math.max(0, msgs.length - 1);
  });

  protected itemStyle(i: number, id: string): Record<string, string> {
    if (this.alertService.leavingIds().has(id)) {
      const dir = this.isBottom() ? 1 : -1;
      return { transform: `translateY(${dir * 20}px) scaleX(0.93)`, opacity: '0', 'pointer-events': 'none' };
    }
    const l = this.layouts()[i];
    if (!l) return {};
    return {
      transform: `translateY(${l.y}px) scaleX(${l.scaleX})`,
      opacity: String(l.opacity),
      'z-index': String(l.z),
    };
  }

  private readonly toastItems = viewChildren<ElementRef<HTMLDivElement>>('toastItem');
  private readonly wrapperRef = viewChild<ElementRef<HTMLElement>>('wrapperRef');

  private readonly injector = inject(Injector);
  private readonly destroyRef = inject(DestroyRef);
  private readonly seenIds = new Set<string>();
  private newestTimer: ReturnType<typeof setTimeout> | null = null;

  constructor() {
    afterNextRender(() => this.alertService.markToastReady());

    effect(() => {
      void this.messages();
      afterNextRender(() => this.measureHeights(), { injector: this.injector });
    });

    /** `popover="manual"` en el wrapper entero (no en cada item) mete TODO el stack de
     *  toasts al "top layer" del navegador como una sola unidad — necesario porque un
     *  `<dialog>` abierto (ej. sa-drawer) también vive en el top layer y ningún
     *  z-index normal le gana. Ponerle popover a cada item por separado (lo que se probó
     *  antes) rompía el efecto de escalera, porque cada uno se iba a su propia capa aislada
     *  del top layer, perdiendo el posicionamiento relativo que calculan `layouts()`. */
    effect(() => {
      const wrapper = this.wrapperRef()?.nativeElement;
      if (!wrapper) return;

      if (this.messages().length > 0) {
        if (!wrapper.matches(':popover-open')) wrapper.showPopover();
      } else if (wrapper.matches(':popover-open')) {
        wrapper.hidePopover();
      }
    });

    effect(() => {
      const msgs = this.messages();
      if (msgs.length > 0 && !this.seenIds.has(msgs[0].id)) {
        this.seenIds.add(msgs[0].id);
        if (this.newestTimer) clearTimeout(this.newestTimer);
        this.newestId.set(msgs[0].id);
        this.newestTimer = setTimeout(() => this.newestId.set(null), 420);
      }
    });

    this.destroyRef.onDestroy(() => {
      if (this.newestTimer) clearTimeout(this.newestTimer);
    });
  }

  private measureHeights(): void {
    const items = this.toastItems();
    const next = items.map((el) => el.nativeElement.offsetHeight);
    const cur = this.itemHeights();
    if (next.length !== cur.length || next.some((h, i) => h !== cur[i])) {
      this.itemHeights.set(next);
    }
  }

  protected close(id: string): void {
    this.alertService.removeMessage(id);
  }

  protected executeAction(action: IAsToastAction, id: string): void {
    this.alertService.removeMessage(id);
    action.execute();
  }

  protected hasIcon(): boolean {
    return true;
  }

  protected showProgressBar(msg: ToastItem): boolean {
    return msg.type !== EAsToastType.Loading && !msg.persistent;
  }

  protected toastIcon(msg: ToastItem): string {
    switch (msg.type) {
      case EAsToastType.Success:
        return 'CheckCircle';
      case EAsToastType.Error:
        return 'CloseCircle';
      case EAsToastType.Warning:
        return 'Info';
      case EAsToastType.Loading:
        return 'Settings';
      default:
        return this.basicIcon(msg.context);
    }
  }

  protected actionSeverity(action: IAsToastAction): ButtonSeverity | undefined {
    return action.variant === 'danger' || /eliminar|borrar|delete/i.test(action.label) ? 'danger' : undefined;
  }

  /** Todo el texto se escapa y solo `{{…}}` sale en negrita: un dato de usuario (nombre de marca, canal o contacto) no puede meter etiquetas, imágenes ni enlaces en el toast. */
  protected formattedMessage(raw: string): string {
    return raw
      .split(/(\{\{.*?\}\})/g)
      .map((part) => (part.startsWith('{{') && part.endsWith('}}') ? `<strong>${escapeHtml(part.slice(2, -2).trim())}</strong>` : escapeHtml(part)))
      .join('');
  }

  protected toastDuration(msg: ToastItem): string {
    return `${msg.duration}ms`;
  }

  private basicIcon(ctx?: 'view' | 'edit' | 'create'): string {
    if (ctx === 'edit') return 'Edit';
    if (ctx === 'create') return 'Add';
    return 'Info';
  }
}
