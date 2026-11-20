<as-button [icon]="triggerIcon()" [iconSize]="triggerIconSize()" [size]="triggerSize()" [variant]="triggerVariant()" [styleClass]="triggerClass()" [ariaLabel]="triggerAriaLabel()" [ariaExpanded]="isOpen()" [asTooltip]="$any(triggerTooltip()) || undefined" [tooltipPosition]="triggerTooltipPosition()" [tooltipStyleClass]="triggerTooltipStyleClass()" [showDelay]="triggerTooltipDelay()" (onClick)="toggle($event)">
  <ng-content select="[popover-trigger]" />
</as-button>

<div #popoverPanel popover="manual" [class]="panelClass()" (toggle)="onPopoverToggle($event)">
  <div class="as-popover-content">
    @if (actions()) {
      <div class="as-popover-actions">
        @for (action of items(); track trackAction($index, action); let last = $last) {
          <as-button [label]="action.label" [icon]="action.icon" [iconSize]="action.iconSize ?? '16'" [disabled]="action.disabled ?? false" [variant]="actionVariant(action)" [styleClass]="actionClass(action)" (onClick)="onActionClick(action)" />

          @if (!last) {
            <hr class="as-popover-divider" aria-hidden="true" />
          }
        }
      </div>
    } @else {
      <ng-content select=":not([popover-trigger])" />
    }
  </div>
</div>
