@if (mounted()) {
  <div class="as-drawer-backdrop" [class.as-drawer-backdrop--visible]="visible()" (click)="onBackdropClick()"></div>

  <dialog
    #dialogRef
    class="as-drawer"
    [class.as-drawer-left]="position() === 'left'"
    [class.as-drawer-right]="position() === 'right'"
    [class.as-drawer-top]="position() === 'top'"
    [class.as-drawer-bottom]="position() === 'bottom'"
    [class.as-drawer-full]="position() === 'full'"
    [attr.aria-label]="ariaLabel()"
    [style.--as-drawer-width]="width()"
    (close)="onDialogClose()"
  >
    <div class="as-drawer-header">
      <ng-container *ngTemplateOutlet="headerTemplate()"></ng-container>

      @if (closable()) {
        <button type="button" class="as-drawer-close-button" aria-label="Cerrar" (click)="close()">
          @if (closeIconTemplate()) {
            <ng-container *ngTemplateOutlet="closeIconTemplate()"></ng-container>
          } @else {
            <as-icon name="X" size="14" />
          }
        </button>
      }
    </div>

    <div class="as-drawer-content">
      <ng-content></ng-content>
    </div>

    <div class="as-drawer-footer"><ng-content select="[drawer-footer]"></ng-content></div>
  </dialog>
}
