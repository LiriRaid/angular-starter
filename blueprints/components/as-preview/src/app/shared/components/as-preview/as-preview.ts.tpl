import {
  ChangeDetectionStrategy,
  Component,
  DestroyRef,
  ElementRef,
  booleanAttribute,
  inject,
  input,
  output,
  signal,
  viewChild,
} from '@angular/core';
import { AsIcon } from '../as-icon/as-icon';

/**
 * A square to choose and preview an image, for avatars, logos and covers. It shows the picture as
 * soon as the user picks it and tells you which file it is; you upload it and may set `imageUrl`.
 *
 * ```html
 * <as-preview label="logo" [imageUrl]="company.logo" (fileSelected)="upload($event)" (removed)="clear()" />
 * ```
 */
@Component({
  selector: 'as-preview',
  imports: [AsIcon],
  templateUrl: './as-preview.html',
  styleUrl: './as-preview.css',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class AsPreview {
  /** URL of the current image, when there is one. */
  readonly imageUrl = input<string | null>(null);
  readonly label = input<string>('image');
  readonly hint = input<string>('');
  /** Icon shown while there is no image. */
  readonly placeholderIcon = input<string>('image');
  readonly accept = input<string>('image/*');
  readonly disabled = input(false, { transform: booleanAttribute });

  readonly fileSelected = output<File>();
  readonly removed = output<void>();

  private readonly picker = viewChild<ElementRef<HTMLInputElement>>('picker');
  private readonly chosen = signal<string | null>(null);

  protected readonly shown = () => this.chosen() ?? this.imageUrl();

  constructor() {
    inject(DestroyRef).onDestroy(() => this.release());
  }

  protected open(): void {
    if (!this.disabled()) this.picker()?.nativeElement.click();
  }

  protected onPicked(event: Event): void {
    const input = event.target as HTMLInputElement;
    const file = input.files?.[0];
    if (!file) return;
    this.release();
    this.chosen.set(URL.createObjectURL(file));
    this.fileSelected.emit(file);
    // Choosing the same file again must fire a new change.
    input.value = '';
  }

  protected remove(): void {
    this.release();
    this.removed.emit();
  }

  private release(): void {
    const url = this.chosen();
    if (url) URL.revokeObjectURL(url);
    this.chosen.set(null);
  }
}
