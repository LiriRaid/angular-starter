import { ChangeDetectionStrategy, Component, computed, input } from '@angular/core';

/**
 * A placeholder shaped like the content that is loading.
 *
 * ```html
 * <as-skeleton shape="text" [lines]="3" />
 * <as-skeleton shape="circle" width="3rem" />
 * <as-skeleton shape="rect" width="100%" height="8rem" />
 * ```
 */
@Component({
  selector: 'as-skeleton',
  templateUrl: './as-skeleton.html',
  styleUrl: './as-skeleton.css',
  changeDetection: ChangeDetectionStrategy.OnPush,
  host: {
    role: 'status',
    'aria-busy': 'true',
    'aria-label': 'Loading',
    '[class]': '"as-skeleton--" + shape()',
    '[style.--as-skeleton-width]': 'width()',
    '[style.--as-skeleton-height]': 'height()',
  },
})
export class AsSkeleton {
  readonly shape = input<'text' | 'rect' | 'circle'>('rect');
  /** Any CSS length. A circle uses it for both sides. */
  readonly width = input<string>('100%');
  readonly height = input<string>('');
  /** How many lines a `text` skeleton draws; the last one is shorter. */
  readonly lines = input<number>(1);

  protected readonly rows = computed(() =>
    Array.from({ length: Math.max(1, this.lines()) }, (_, index) => index),
  );
}
