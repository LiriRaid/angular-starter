<as-modal [(visible)]="visible" variant="preview" [dismissableMask]="true" (hide)="close()">
  @if (kind() === 'image') {
    <as-button icon="Download" iconSize="20" size="small" variant="text" styleClass="as-media-preview-download as-icon-overlay-btn" ariaLabel="Descargar" (onClick)="download()" />
    <img [src]="url()" [alt]="fileName() || 'Vista previa'" class="as-media-preview-image" />
  } @else {
    <iframe [src]="safeUrl()" class="as-media-preview-frame" title="Vista previa del documento"></iframe>
  }
</as-modal>
