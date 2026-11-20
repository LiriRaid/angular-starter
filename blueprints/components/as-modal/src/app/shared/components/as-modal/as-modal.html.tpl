@if (open()) {
  <div class="as-modal__backdrop as-animate-fade-in" (click)="onBackdropClick()">
    <div
      #panel
      class="as-modal__panel as-modal__panel--{{ size() }} as-animate-scale-in"
      role="dialog"
      aria-modal="true"
      tabindex="-1"
      [attr.aria-labelledby]="title() ? titleId : null"
      (click)="$event.stopPropagation()"
      (keydown)="onKeydown($event)"
    >
      @if (title() || closable()) {
        <header class="as-modal__header">
          <h2 class="as-modal__title" [id]="titleId">{{ title() }}</h2>
          @if (closable()) {
            <button type="button" class="as-modal__close" aria-label="Close" (click)="close()">
              <as-icon name="x" [size]="18" />
            </button>
          }
        </header>
      }
      <div class="as-modal__body"><ng-content /></div>
      <footer class="as-modal__footer"><ng-content select="[asModalFooter]" /></footer>
    </div>
  </div>
}
