import { ChangeDetectionStrategy, Component, computed, input, signal } from '@angular/core';
import { deriveInitials } from '../../utils/derive-initials';

export type AsAvatarSize = 'xs' | 'sm' | 'md' | 'lg' | 'xl';
export type AsAvatarStatus = 'online' | 'away' | 'busy' | 'offline';

/**
 * A person or entity: its picture, or its initials when there is no picture (or it fails to load).
 *
 * ```html
 * <as-avatar name="Ada Lovelace" />
 * <as-avatar name="Ada Lovelace" src="/ada.png" size="lg" status="online" />
 * ```
 */
@Component({
  selector: 'as-avatar',
  templateUrl: './as-avatar.html',
  styleUrl: './as-avatar.css',
  changeDetection: ChangeDetectionStrategy.OnPush,
  host: {
    '[class]': '"as-avatar--" + size() + " as-avatar--" + shape()',
    '[attr.role]': '"img"',
    '[attr.aria-label]': 'name() || "Avatar"',
    '[style.--as-avatar-hue]': 'hue()',
  },
})
export class AsAvatar {
  readonly name = input<string>('');
  readonly src = input<string>('');
  readonly size = input<AsAvatarSize>('md');
  readonly shape = input<'circle' | 'square'>('circle');
  readonly status = input<AsAvatarStatus | ''>('');

  private readonly failed = signal<string | null>(null);

  protected readonly showImage = computed(() => !!this.src() && this.failed() !== this.src());
  protected readonly initials = computed(() => deriveInitials(this.name()));

  /** A stable color for each name, so the same person always has the same avatar. */
  protected readonly hue = computed(() => {
    let hash = 0;
    for (const character of this.name()) hash = (hash * 31 + character.charCodeAt(0)) % 360;
    return hash;
  });

  protected onError(): void {
    this.failed.set(this.src());
  }
}
