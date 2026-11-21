<ng-template #drawerTemplate>
  <div class="as-drawer-backdrop" [class.as-drawer-backdrop--visible]="visible()" (click)="onBackdropClick()"></div>

  <dialog #dialogRef [class]="panelClass()" [attr.aria-label]="ariaLabel()" [style.--as-drawer-width]="width()" (close)="onDialogClose()">
    <div class="as-drawer-header">
      <div class="as-drawer-header-content">
        <ng-container *ngTemplateOutlet="headerTemplate()"></ng-container>
        <ng-content select="[drawer-header]"></ng-content>
      </div>

      @if (closable()) {
        <button type="button" class="as-drawer-close-button" [attr.aria-label]="closeLabel()" (click)="close()">
          @if (closeIconTemplate()) {
            <ng-container *ngTemplateOutlet="closeIconTemplate()"></ng-container>
          } @else {
            <as-icon [name]="closeIcon()" size="14" />
          }
        </button>
      }
    </div>

    <div class="as-drawer-content">
      <ng-content></ng-content>
    </div>

    <div class="as-drawer-footer"><ng-content select="[drawer-footer]"></ng-content></div>
  </dialog>
</ng-template>
