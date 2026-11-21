<ng-template #modalTemplate>
  <div class="as-modal-backdrop" [class.as-modal-backdrop--visible]="visible()" (click)="onBackdropClick()"></div>

  <div #panelRef [class]="hostClasses()" [class.as-modal--visible]="visible()" [style.width]="variant() === 'default' ? width() : null" role="dialog" aria-modal="true">
    <div class="as-modal-resize-handle" (mousedown)="onResizeMouseDown($event)"></div>

    @if (variant() === 'default') {
      <div class="as-modal-header" (mousedown)="onHeaderMouseDown($event)">
        @if (title() || titleIcon() || titleDotColor()) {
          <div class="as-modal-header-title flex min-w-0 items-center gap-2">
            @if (titleDotColor(); as dotColor) {
              <span class="as-modal-title-dot" [style.background]="dotColor"></span>
            } @else if (titleIcon(); as icon) {
              <as-icon [name]="icon" size="20" />
            }
            <span class="truncate text-body-2-bold text-(--app-text-color)">{{ title() }}</span>
          </div>
        }

        <div class="as-modal-header-actions">
          <ng-content select="[modal-header-actions]" />

          @if (closable()) {
            <as-button icon="X" iconSize="18" variant="text" size="small" styleClass="!text-(--app-text-color) hover:!text-(--as-primary-color) as-btn-r-full" ariaLabel="Cerrar" (onClick)="close()" />
          }
        </div>
      </div>
    }

    <div class="as-modal-content">
      <ng-content />
    </div>

    @if (variant() === 'preview') {
      <as-button icon="X" iconSize="18" size="small" styleClass="as-modal-preview-close as-icon-overlay-btn" ariaLabel="Cerrar" (onClick)="close()" />
    }

    @if (showFooter()) {
      <div class="as-modal-footer">
        <ng-content select="[modal-footer]" />
      </div>
    }
  </div>
</ng-template>
