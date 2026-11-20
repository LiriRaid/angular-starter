import { ChangeDetectionStrategy, Component, computed, input } from '@angular/core';
import { AsIcon } from '../as-icon/as-icon';

export type AsMediaKind = 'image' | 'video' | 'audio' | 'document';

/**
 * Shows a file by its URL: an image, a video or an audio player, or a download card for any other
 * document.
 *
 * ```html
 * <as-media-preview kind="video" url="/clips/intro.mp4" fileName="intro.mp4" />
 * ```
 */
@Component({
  selector: 'as-media-preview',
  imports: [AsIcon],
  templateUrl: './as-media-preview.html',
  styleUrl: './as-media-preview.css',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class AsMediaPreview {
  readonly kind = input<AsMediaKind>('image');
  readonly url = input<string>('');
  readonly fileName = input<string>('');

  protected readonly name = computed(() => this.fileName() || this.url().split('/').pop() || 'File');
}
