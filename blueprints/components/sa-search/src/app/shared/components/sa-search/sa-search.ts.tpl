import { ChangeDetectionStrategy, Component, DestroyRef, ViewEncapsulation, effect, inject, input, output, signal } from '@angular/core';
import { FormControl, ReactiveFormsModule } from '@angular/forms';

import { AsButton } from '../as-button/as-button';
import { AsInput } from '../as-input/as-input';

export type AsSearchMode = 'input' | 'collapsed' | 'chat';

@Component({
  selector: 'as-search',
  standalone: true,
  imports: [ReactiveFormsModule, AsButton, AsInput],
  templateUrl: './as-search.html',
  styleUrl: './as-search.css',
  encapsulation: ViewEncapsulation.None,
  changeDetection: ChangeDetectionStrategy.OnPush,
  host: {
    '[class.as-search--input]': 'mode() !== "collapsed" && !renderCollapsed()',
    '[class.as-search--collapsed]': 'renderCollapsed()',
    '[class.as-search--chat]': 'mode() === "chat" && !renderCollapsed()',
  },
})
export class AsSearch {
  private readonly collapseTransitionMs = 400;

  readonly mode = input<AsSearchMode>('input');
  readonly control = input.required<FormControl<string | null>>();
  readonly placeholder = input<string>('Buscar...');
  readonly inputClass = input<string>('');

  readonly searchEnter = output<string>();
  readonly collapsedSearchClick = output<void>();
  readonly backClick = output<void>();

  readonly renderCollapsed = signal(false);

  private collapseTimer: ReturnType<typeof setTimeout> | null = null;

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
        requestAnimationFrame(() => this.renderCollapsed.set(false));
      }
    });

    inject(DestroyRef).onDestroy(() => this.clearTimer());
  }

  onKeyup(event: KeyboardEvent): void {
    const term = this.control().value?.trim() || '';

    if (event.key === 'Enter' || term === '') {
      this.searchEnter.emit(term);
    }
  }

  private clearTimer(): void {
    if (!this.collapseTimer) return;
    clearTimeout(this.collapseTimer);
    this.collapseTimer = null;
  }
}
