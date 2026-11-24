<sa-modal [(visible)]="visible" variant="preview" [dismissableMask]="true" (hide)="close()">
  @if (kind() === 'image') {
    <sa-button icon="Download" iconSize="20" size="small" variant="text" styleClass="sa-media-preview-download sa-icon-overlay-btn" ariaLabel="Descargar" (onClick)="download()" />
    <img [src]="url()" [alt]="fileName() || 'Vista previa'" class="sa-media-preview-image" />
  } @else {
    <iframe [src]="safeUrl()" class="sa-media-preview-frame" title="Vista previa del documento"></iframe>
  }
</sa-modal>
