<button type="button" role="switch" class="sa-toggle" [class.sa-toggle--checked]="localChecked()" [attr.aria-checked]="localChecked()" [attr.aria-label]="ariaLabel()" [disabled]="disabled()" (click)="onToggle()">
  <span class="sa-toggle-handle"></span>
</button>
