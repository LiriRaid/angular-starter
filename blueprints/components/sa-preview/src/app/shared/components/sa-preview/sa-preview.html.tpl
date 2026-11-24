<div class="sa-preview-box flex min-h-32 flex-col items-center justify-center gap-2 rounded-2xl border border-dashed border-(--app-border-color) p-4 text-center" [class.sa-preview-box--filled]="imageUrl()" [class.sa-preview-box--readonly]="disabled()" (click)="onBoxClick()">
  @if (imageUrl(); as url) {
    <div class="sa-preview-media">
      <img [src]="url" [alt]="label()" class="sa-preview-image" />

      <div class="sa-preview-zoom">
        <sa-icon name="ZoomIn" size="24" color="white" />
      </div>

      @if (!disabled()) {
        <sa-button icon="Cancel" iconSize="18" size="small" styleClass="sa-preview-remove sa-icon-overlay-btn" [ariaLabel]="'Quitar ' + label()" (onClick)="onRemoveClick($event)" />
      }
    </div>
  } @else if (disabled()) {
    <sa-icon name="ImageOff" size="28" color="var(--app-text-subtle)" />
    <span class="text-caption-2-regular text-(--app-text-muted)">No hay {{ label() }} subido</span>
  } @else {
    <sa-icon [name]="placeholderIcon()" size="28" color="var(--app-text-subtle)" />
    <span class="text-caption-2-regular text-(--app-text-muted)">Subir {{ label() }}</span>
    @if (hint()) {
      <span class="text-caption-2-regular text-(--app-text-subtle)">{{ hint() }}</span>
    }
  }

  <input #fileInput type="file" accept="image/*" class="hidden" (click)="$event.stopPropagation()" (change)="onFileInputChange($event)" />
</div>

<sa-modal [(visible)]="isPreviewOpen" variant="preview" [dismissableMask]="true" (hide)="closePreview()">
  @if (imageUrl(); as url) {
    <img [src]="url" [alt]="label()" />
  }
</sa-modal>
