<nav class="as-section-nav" [attr.aria-label]="title() || 'Sections'">
  @if (title()) {
    <header class="as-section-nav__header">
      <h2 class="as-section-nav__title">{{ title() }}</h2>
      @if (description()) {
        <p class="as-section-nav__description">{{ description() }}</p>
      }
    </header>
  }
  <ul class="as-section-nav__list">
    @for (item of items(); track item.id) {
      <li>
        <button
          type="button"
          class="as-section-nav__item"
          [class.as-section-nav__item--selected]="item.id === selected()"
          [attr.aria-current]="item.id === selected() ? 'page' : null"
          [disabled]="item.disabled"
          (click)="select(item)"
        >
          @if (item.icon) {
            <as-icon [name]="item.icon" [size]="18" />
          }
          <span class="as-section-nav__text">
            <span class="as-section-nav__label">{{ item.label }}</span>
            @if (item.description) {
              <span class="as-section-nav__hint">{{ item.description }}</span>
            }
          </span>
        </button>
      </li>
    }
  </ul>
</nav>
