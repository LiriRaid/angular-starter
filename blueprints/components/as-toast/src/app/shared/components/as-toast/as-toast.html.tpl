<div class="as-toast__stack" role="region" aria-label="Notifications" aria-live="polite">
  @for (toast of service.toasts(); track toast.id) {
    <div
      class="as-toast as-toast--{{ toast.severity }} as-animate-slide-up"
      [attr.role]="toast.severity === 'error' ? 'alert' : 'status'"
    >
      <as-icon class="as-toast__icon" [name]="icons[toast.severity]" [size]="20" />
      <div class="as-toast__content">
        @if (toast.title) {
          <p class="as-toast__title">{{ toast.title }}</p>
        }
        <p class="as-toast__message">{{ toast.message }}</p>
      </div>
      <button
        type="button"
        class="as-toast__close"
        aria-label="Dismiss"
        (click)="service.dismiss(toast.id)"
      >
        <as-icon name="x" [size]="16" />
      </button>
    </div>
  }
</div>
