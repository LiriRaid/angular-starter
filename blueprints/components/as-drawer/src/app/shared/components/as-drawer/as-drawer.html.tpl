@if (open()) {
  <div class="as-drawer__backdrop as-animate-fade-in" (click)="onBackdropClick()">
    <aside
      #panel
      class="as-drawer__panel as-drawer__panel--{{ position() }}"
      role="dialog"
      aria-modal="true"
      tabindex="-1"
      [style.width]="width()"
      [attr.aria-labelledby]="title() ? titleId : null"
      (click)="$event.stopPropagation()"
      (keydown)="onKeydown($event)"
    >
      @if (title() || closable()) {
        <header class="as-drawer__header">
          <h2 class="as-drawer__title" [id]="titleId">{{ title() }}</h2>
          @if (closable()) {
            <button type="button" class="as-drawer__close" aria-label="Close" (click)="close()">
              <as-icon name="x" [size]="18" />
            </button>
          }
        </header>
      }
      <div class="as-drawer__body"><ng-content /></div>
      <footer class="as-drawer__footer"><ng-content select="[asDrawerFooter]" /></footer>
    </aside>
  </div>
}
