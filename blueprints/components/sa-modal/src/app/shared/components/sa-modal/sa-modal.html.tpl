<ng-template #modalTemplate>
  <div class="sa-modal-backdrop" [class.sa-modal-backdrop--visible]="visible()" (click)="onBackdropClick()"></div>

  <div #panelRef [class]="hostClasses()" [class.sa-modal--visible]="visible()" [style.width]="variant() === 'default' ? width() : null" role="dialog" aria-modal="true">
    <div class="sa-modal-resize-handle" (mousedown)="onResizeMouseDown($event)"></div>

    @if (variant() === 'default') {
      <div class="sa-modal-header" (mousedown)="onHeaderMouseDown($event)">
        @if (title() || titleIcon() || titleDotColor()) {
          <div class="sa-modal-header-title flex min-w-0 items-center gap-2">
            @if (titleDotColor(); as dotColor) {
              <span class="sa-modal-title-dot" [style.background]="dotColor"></span>
            } @else if (titleIcon(); as icon) {
              <sa-icon [name]="icon" size="20" />
            }
            <span class="truncate text-body-2-bold text-(--app-text-color)">{{ title() }}</span>
          </div>
        }

        <div class="sa-modal-header-actions">
          <ng-content select="[modal-header-actions]" />

          @if (closable()) {
            <sa-button icon="X" iconSize="18" variant="text" size="small" styleClass="!text-(--app-text-color) hover:!text-(--sa-primary-color) sa-btn-r-full" ariaLabel="Cerrar" (onClick)="close()" />
          }
        </div>
      </div>
    }

    <div class="sa-modal-content">
      <ng-content />
    </div>

    @if (variant() === 'preview') {
      <sa-button icon="X" iconSize="18" size="small" styleClass="sa-modal-preview-close sa-icon-overlay-btn" ariaLabel="Cerrar" (onClick)="close()" />
    }

    @if (showFooter()) {
      <div class="sa-modal-footer">
        <ng-content select="[modal-footer]" />
      </div>
    }
  </div>
</ng-template>
