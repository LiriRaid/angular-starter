<ng-template #drawerTemplate>
  <div class="sa-drawer-backdrop" [class.sa-drawer-backdrop--visible]="visible()" (click)="onBackdropClick()"></div>

  <dialog #dialogRef [class]="panelClass()" [attr.aria-label]="ariaLabel()" [style.--sa-drawer-width]="width()" (close)="onDialogClose()">
    <div class="sa-drawer-header">
      <div class="sa-drawer-header-content">
        <ng-container *ngTemplateOutlet="headerTemplate()"></ng-container>
        <ng-content select="[drawer-header]"></ng-content>
      </div>

      @if (closable()) {
        <button type="button" class="sa-drawer-close-button" [attr.aria-label]="closeLabel()" (click)="close()">
          @if (closeIconTemplate()) {
            <ng-container *ngTemplateOutlet="closeIconTemplate()"></ng-container>
          } @else {
            <sa-icon [name]="closeIcon()" size="14" />
          }
        </button>
      }
    </div>

    <div class="sa-drawer-content">
      <ng-content></ng-content>
    </div>

    <div class="sa-drawer-footer"><ng-content select="[drawer-footer]"></ng-content></div>
  </dialog>
</ng-template>
