<ng-template #buttonIcon>
  @if (loading()) {
    <sa-icon [name]="loadingIcon()" [spin]="true" [size]="iconSize()" [color]="iconColor()" [ngClass]="computedIconClass()" />
  } @else if (icon(); as iconName) {
    <sa-icon [name]="iconName" [size]="iconSize()" [color]="iconColor()" [ngClass]="computedIconClass()" />
  }
</ng-template>

<ng-template #buttonContent>
  @if (showIconBefore()) {
    <ng-container [ngTemplateOutlet]="buttonIcon" />
  }

  <ng-content />

  @if (label()) {
    <span [ngClass]="computedLabelClass()">
      {{ label() }}
    </span>
  }

  @if (hasBadge()) {
    <span [ngClass]="computedBadgeClass()">
      {{ badge() }}
    </span>
  }

  @if (showIconAfter()) {
    <ng-container [ngTemplateOutlet]="buttonIcon" />
  }

  @if (trailingIcon(); as trailingIconName) {
    <sa-icon [name]="trailingIconName" [size]="trailingIconSize()" [color]="trailingIconColor()" [extraClass]="trailingIconExtraClass()" class="sa-button__trailing-icon" />
  }
</ng-template>

@if (href()) {
  <a saRipple [href]="href()!" [attr.target]="target() || null" [attr.rel]="rel() || null" [attr.aria-label]="ariaLabel() || undefined" [attr.aria-controls]="ariaControls() || undefined" [attr.aria-expanded]="ariaExpanded() === null ? undefined : ariaExpanded()" [attr.aria-pressed]="ariaPressed() === null ? undefined : ariaPressed()" [attr.aria-busy]="loading() || null" [attr.aria-disabled]="isDisabled()" [attr.tabindex]="isDisabled() ? -1 : null" [class]="buttonClass()" [class.sa-disabled]="isDisabled()" (click)="handleClick($event)">
    <ng-container [ngTemplateOutlet]="buttonContent" />
  </a>
} @else {
  <button saRipple [type]="type()" [disabled]="isDisabled()" [attr.aria-busy]="loading() || null" [attr.aria-label]="ariaLabel() || undefined" [attr.aria-controls]="ariaControls() || undefined" [attr.aria-expanded]="ariaExpanded() === null ? undefined : ariaExpanded()" [attr.aria-pressed]="ariaPressed() === null ? undefined : ariaPressed()" [class]="buttonClass()" [class.sa-disabled]="isDisabled()" (click)="handleClick($event)">
    <ng-container [ngTemplateOutlet]="buttonContent" />
  </button>
}
