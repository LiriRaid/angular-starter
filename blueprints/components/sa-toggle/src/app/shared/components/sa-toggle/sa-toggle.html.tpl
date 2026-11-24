<button type="button" role="switch" class="as-toggle" [class.as-toggle--checked]="localChecked()" [attr.aria-checked]="localChecked()" [attr.aria-label]="ariaLabel()" [disabled]="disabled()" (click)="onToggle()">
  <span class="as-toggle-handle"></span>
</button>
