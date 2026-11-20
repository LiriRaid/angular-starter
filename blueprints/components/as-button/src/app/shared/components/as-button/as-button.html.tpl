<ng-template #content>
  @if (loading()) {
    <as-icon name="loader-circle" [spin]="true" [size]="16" />
  } @else if (icon() && iconPosition() === 'left') {
    <as-icon [name]="icon()" [size]="16" />
  }
  @if (label()) {
    <span class="as-btn__label">{{ label() }}</span>
  }
  <ng-content />
  @if (!loading() && icon() && iconPosition() === 'right') {
    <as-icon [name]="icon()" [size]="16" />
  }
</ng-template>

@if (href()) {
  <a
    [class]="classes()"
    [class.as-btn--icon-only]="iconOnly()"
    [class.as-btn--inactive]="inactive()"
    [attr.href]="inactive() ? null : href()"
    [attr.target]="target() || null"
    [attr.rel]="target() === '_blank' ? 'noopener noreferrer' : null"
    [attr.aria-label]="ariaLabel() || null"
    [attr.aria-disabled]="inactive() || null"
    (click)="handleClick($event)"
  >
    <ng-container [ngTemplateOutlet]="content" />
  </a>
} @else {
  <button
    [class]="classes()"
    [class.as-btn--icon-only]="iconOnly()"
    [type]="type()"
    [disabled]="inactive()"
    [attr.aria-label]="ariaLabel() || null"
    [attr.aria-busy]="loading() || null"
    (click)="handleClick($event)"
  >
    <ng-container [ngTemplateOutlet]="content" />
  </button>
}
