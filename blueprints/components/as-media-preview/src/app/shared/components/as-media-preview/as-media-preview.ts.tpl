import { ChangeDetectionStrategy, Component, ViewEncapsulation, computed, inject, input, model } from '@angular/core';
import { DomSanitizer, type SafeResourceUrl } from '@angular/platform-browser';

import { AsButton } from '../as-button/as-button';
import { AsModal } from '../as-modal/as-modal';
import { downloadFile } from '@shared/utils/download-file';

export type MediaPreviewKind = 'image' | 'pdf';

const HTTP_URL = /^https?:\/\//i;

/** Modal de zoom (imagen) / preview inline (PDF) de un adjunto del chat — construido sobre
 *  as-modal en variant="preview" (ya trae su propio botón de cerrar flotante, así
 *  que acá solo se agrega el botón de descarga cuando aplica). */
@Component({
  selector: 'as-media-preview',
  standalone: true,
  imports: [AsModal, AsButton],
  templateUrl: './as-media-preview.html',
  styleUrl: './as-media-preview.css',
  encapsulation: ViewEncapsulation.None,
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class AsMediaPreview {
  private readonly sanitizer = inject(DomSanitizer);

  readonly visible = model<boolean>(false);
  readonly kind = input<MediaPreviewKind>('image');
  readonly url = input<string>('');
  readonly fileName = input<string | null>(null);

  /** Solo `http(s)` llega al visor: cualquier otro esquema (`javascript:`, `data:`) queda en blanco. */
  readonly safeUrl = computed<SafeResourceUrl>(() => this.sanitizer.bypassSecurityTrustResourceUrl(HTTP_URL.test(this.url()) ? this.url() : 'about:blank'));

  /** El archivo vive en Supabase (otro origen), así que `download` en un `<a>` normal es
   *  ignorado por el navegador y termina navegando al archivo en vez de bajarlo — se trae
   *  como blob primero para forzar la descarga real. */
  async download(): Promise<void> {
    try {
      const response = await fetch(this.url());
      const blob = await response.blob();
      downloadFile(blob, blob.type, this.fileName() || this.fileNameFromUrl());
    } catch {
      // Mismo criterio que el visor: solo `http(s)` se abre; `javascript:` o `data:` no salen en una ventana nueva.
      if (HTTP_URL.test(this.url())) window.open(this.url(), '_blank');
    }
  }

  close(): void {
    this.visible.set(false);
  }

  /** WhatsApp no manda nombre original para imágenes/stickers — el archivo real (binario,
   *  nunca base64) igual queda guardado en el bucket con su propio nombre, así que se usa ese
   *  en vez de un genérico "archivo". */
  private fileNameFromUrl(): string {
    try {
      const path = new URL(this.url()).pathname;
      return decodeURIComponent(path.substring(path.lastIndexOf('/') + 1)) || 'archivo';
    } catch {
      return 'archivo';
    }
  }
}
