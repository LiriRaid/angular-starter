<as-popover [(open)]="open" placement="bottom-end">
  <button
    asPopoverTrigger
    type="button"
    class="as-theme-picker__trigger"
    aria-label="Theme"
    [attr.aria-expanded]="open()"
    (click)="open.set(!open())"
  >
    <as-icon name="palette" [size]="18" />
  </button>

  <div class="as-theme-picker">
    <section class="as-theme-picker__section">
      <h3 class="as-theme-picker__heading">Mode</h3>
      <div class="as-theme-picker__modes" role="group" aria-label="Mode">
        <button
          type="button"
          class="as-theme-picker__mode"
          [class.as-theme-picker__mode--active]="theme.mode() === 'light'"
          [attr.aria-pressed]="theme.mode() === 'light'"
          (click)="theme.setMode('light')"
        >
          <as-icon name="sun" [size]="16" /> Light
        </button>
        <button
          type="button"
          class="as-theme-picker__mode"
          [class.as-theme-picker__mode--active]="theme.mode() === 'dark'"
          [attr.aria-pressed]="theme.mode() === 'dark'"
          (click)="theme.setMode('dark')"
        >
          <as-icon name="moon" [size]="16" /> Dark
        </button>
      </div>
    </section>

    <section class="as-theme-picker__section">
      <h3 class="as-theme-picker__heading">Accent color</h3>
      <div class="as-theme-picker__swatches" role="group" aria-label="Accent color">
        @for (color of primaryColors; track color.key) {
          <button
            type="button"
            class="as-theme-picker__swatch"
            [class.as-theme-picker__swatch--active]="theme.primaryColorKey() === color.key"
            [style.background]="color.swatch"
            [attr.aria-label]="color.label"
            [attr.aria-pressed]="theme.primaryColorKey() === color.key"
            (click)="theme.setPrimaryColor(color.key)"
          ></button>
        }
      </div>
    </section>

    <section class="as-theme-picker__section">
      <h3 class="as-theme-picker__heading">Surface color</h3>
      <div class="as-theme-picker__swatches" role="group" aria-label="Surface color">
        @for (color of surfaceColors; track color.key) {
          <button
            type="button"
            class="as-theme-picker__swatch"
            [class.as-theme-picker__swatch--active]="theme.surfaceColorKey() === color.key"
            [style.background]="color.swatch"
            [attr.aria-label]="color.label"
            [attr.aria-pressed]="theme.surfaceColorKey() === color.key"
            (click)="theme.setSurfaceColor(color.key)"
          ></button>
        }
      </div>
    </section>
  </div>
</as-popover>
