<sa-button [icon]="triggerIcon()" [iconSize]="triggerIconSize()" [size]="triggerSize()" [variant]="triggerVariant()" [styleClass]="triggerClass()" [ariaLabel]="triggerAriaLabel()" [ariaExpanded]="isOpen()" [saTooltip]="$any(triggerTooltip()) || undefined" [tooltipPosition]="triggerTooltipPosition()" [tooltipStyleClass]="triggerTooltipStyleClass()" [showDelay]="triggerTooltipDelay()" (onClick)="toggle($event)">
  <ng-content select="[popover-trigger]" />
</sa-button>

<div #popoverPanel popover="manual" [class]="panelClass()" (toggle)="onPopoverToggle($event)">
  <div class="sa-popover-content">
    @if (actions()) {
      <div class="sa-popover-actions">
        @for (action of items(); track trackAction($index, action); let last = $last) {
          <sa-button [label]="action.label" [icon]="action.icon" [iconSize]="action.iconSize ?? '16'" [disabled]="action.disabled ?? false" [variant]="actionVariant(action)" [styleClass]="actionClass(action)" (onClick)="onActionClick(action)" />

          @if (!last) {
            <hr class="sa-popover-divider" aria-hidden="true" />
          }
        }
      </div>
    } @else {
      <ng-content select=":not([popover-trigger])" />
    }
  </div>
</div>
