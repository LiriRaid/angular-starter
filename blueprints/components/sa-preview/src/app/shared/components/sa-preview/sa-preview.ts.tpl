import { ChangeDetectionStrategy, Component, ElementRef, ViewEncapsulation, booleanAttribute, input, output, signal, viewChild } from '@angular/core';

import type { LucideIconName } from '@core/common/icons/lucide-icons';
import { SaButton } from '../sa-button/sa-button';
import { SaIcon } from '../sa-icon/sa-icon';
import { SaModal } from '../sa-modal/sa-modal';

/**
 * Caja de subida + preview de una sola imagen (logo, icono, avatar, etc).
 * Vacía: dropzone clickeable con ícono e instrucciones.
 * Con imagen: solo la imagen (sin instrucciones), clic abre sa-modal en variant="preview"
 * (panel ajustado al tamaño natural de la imagen, sin header, botón de cerrar flotando encima).
 * La validación de archivo (tipo/tamaño) queda del lado de quien lo consume, vía `fileSelected`.
 */
@Component({
  selector: 'sa-preview',
  standalone: true,
  imports: [SaIcon, SaModal, SaButton],
  templateUrl: './sa-preview.html',
  styleUrl: './sa-preview.css',
  encapsulation: ViewEncapsulation.None,
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class SaPreview {
  readonly imageUrl = input<string | null>(null);
  readonly label = input<string>('imagen');
  readonly hint = input<string>('');
  readonly placeholderIcon = input<LucideIconName>('Image');
  readonly disabled = input(false, { transform: booleanAttribute });

  readonly fileSelected = output<File>();
  readonly removed = output<void>();

  private readonly fileInput = viewChild.required<ElementRef<HTMLInputElement>>('fileInput');

  readonly isPreviewOpen = signal(false);

  onBoxClick(): void {
    if (this.imageUrl()) {
      this.isPreviewOpen.set(true);
      return;
    }

    if (this.disabled()) return;
    this.fileInput().nativeElement.click();
  }

  onFileInputChange(event: Event): void {
    const input = event.target as HTMLInputElement;
    const file = input.files?.[0];
    input.value = '';
    if (file) this.fileSelected.emit(file);
  }

  onRemoveClick(event: MouseEvent): void {
    event.stopPropagation();
    this.removed.emit();
  }

  closePreview(): void {
    this.isPreviewOpen.set(false);
  }
}
