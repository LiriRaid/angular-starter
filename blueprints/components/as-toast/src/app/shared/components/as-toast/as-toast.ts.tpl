import { ChangeDetectionStrategy, Component, inject, input } from '@angular/core';
import { AsIcon } from '../as-icon/as-icon';
import { AsToastService, type AsToastSeverity } from './as-toast.service';

const ICONS: Record<AsToastSeverity, string> = {
  success: 'circle-check',
  info: 'info',
  warn: 'triangle-alert',
  error: 'circle-alert',
};

/**
 * The stack of messages that `AsToastService` shows. Place it once, for example at the end of the
 * template of the root component: `<as-toast />`.
 */
@Component({
  selector: 'as-toast',
  imports: [AsIcon],
  templateUrl: './as-toast.html',
  styleUrl: './as-toast.css',
  changeDetection: ChangeDetectionStrategy.OnPush,
  host: { '[attr.data-position]': 'position()' },
})
export class AsToast {
  readonly position = input<'top-right' | 'top-left' | 'bottom-right' | 'bottom-left'>('top-right');

  protected readonly service = inject(AsToastService);
  protected readonly icons = ICONS;
}
