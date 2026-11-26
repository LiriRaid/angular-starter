import { ChangeDetectionStrategy, Component, DestroyRef, ElementRef, Injector, ViewEncapsulation, afterNextRender, effect, inject, input, output, signal } from '@angular/core';
import { FormControl, ReactiveFormsModule } from '@angular/forms';

import { SaButton } from '../sa-button/sa-button';
import { SaInput } from '../sa-input/sa-input';

export type SaSearchMode = 'input' | 'collapsed' | 'chat';

@Component({
  selector: 'sa-search',
  standalone: true,
  imports: [ReactiveFormsModule, SaButton, SaInput],
  templateUrl: './sa-search.html',
  styleUrl: './sa-search.css',
  encapsulation: ViewEncapsulation.None,
  changeDetection: ChangeDetectionStrategy.OnPush,
  host: {
    '[class.sa-search--input]': 'mode() !== "collapsed" && !renderCollapsed()',
    '[class.sa-search--collapsed]': 'renderCollapsed()',
    '[class.sa-search--chat]': 'mode() === "chat" && !renderCollapsed()',
  },
})
export class SaSearch {
  private readonly collapseTransitionMs = 400;

  readonly mode = input<SaSearchMode>('input');
  readonly control = input.required<FormControl<string | null>>();
  readonly placeholder = input<string>('Buscar...');
  readonly inputClass = input<string>('');

  readonly searchEnter = output<string>();
  readonly collapsedSearchClick = output<void>();
  readonly backClick = output<void>();

  readonly renderCollapsed = signal(false);

  private collapseTimer: ReturnType<typeof setTimeout> | null = null;
  private focusOnExpand = false;
  private focusTimer: ReturnType<typeof setTimeout> | null = null;
  private readonly focusRequestMs = 1500;
  private readonly host = inject<ElementRef<HTMLElement>>(ElementRef);
  private readonly injector = inject(Injector);

  constructor() {
    let initialized = false;

    effect(() => {
      const current = this.mode();
      if (!initialized) {
        this.renderCollapsed.set(current === 'collapsed');
        initialized = true;
        return;
      }
      this.clearTimer();
      if (current === 'collapsed') {
        this.collapseTimer = setTimeout(() => {
          this.renderCollapsed.set(true);
          this.collapseTimer = null;
        }, this.collapseTransitionMs);
      } else {
        requestAnimationFrame(() => {
          this.renderCollapsed.set(false);
          this.focusFieldAfterRender();
        });
      }
    });

    inject(DestroyRef).onDestroy(() => {
      this.clearTimer();
      this.clearFocusTimer();
    });
  }

  /**
   * El padre decide el modo (el sidebar, la lista de conversaciones): el botón avisa y, cuando el padre lo expande,
   * el cursor queda en el campo sin que el padre tenga que buscarlo. Un cambio de modo que no viene del botón no roba el foco.
   */
  onCollapsedClick(): void {
    this.focusOnExpand = true;
    // Si el padre no expande el buscador, la petición caduca: un cambio de modo posterior no roba el foco.
    if (this.focusTimer) clearTimeout(this.focusTimer);
    this.focusTimer = setTimeout(() => {
      this.focusOnExpand = false;
      this.focusTimer = null;
    }, this.focusRequestMs);
    this.collapsedSearchClick.emit();
  }

  onKeyup(event: KeyboardEvent): void {
    const term = this.control().value?.trim() || '';

    if (event.key === 'Enter' || term === '') {
      this.searchEnter.emit(term);
    }
  }

  private focusFieldAfterRender(): void {
    if (!this.focusOnExpand) return;
    this.focusOnExpand = false;

    afterNextRender(() => this.host.nativeElement.querySelector<HTMLInputElement>('input')?.focus(), { injector: this.injector });
  }

  private clearFocusTimer(): void {
    if (!this.focusTimer) return;
    clearTimeout(this.focusTimer);
    this.focusTimer = null;
  }

  private clearTimer(): void {
    if (!this.collapseTimer) return;
    clearTimeout(this.collapseTimer);
    this.collapseTimer = null;
  }
}
