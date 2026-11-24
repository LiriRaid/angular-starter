<div #panel popover="manual" class="as-color-picker-panel" (toggle)="onPanelToggle($event)">
  <div class="color-picker-content">
    <div class="color-picker-section">
      <p class="color-picker-label text-caption-2-semibold">Colores Primarios</p>

      <div class="color-picker-grid">
        @for (color of primaryColors; track color.key) {
          <button type="button" class="color-swatch" [class.active]="currentPrimaryKey() === color.key" [style.background]="color.swatch" [asTooltip]="color.label" tooltipPosition="top" [attr.aria-label]="'Seleccionar color ' + color.label" [attr.aria-pressed]="currentPrimaryKey() === color.key" (click)="selectPrimary(color.key, panel)">
            @if (currentPrimaryKey() === color.key) {
              <span class="check text-caption-2-bold" aria-hidden="true">✓</span>
            }
          </button>
        }
      </div>
    </div>

    <div class="color-picker-section">
      <p class="color-picker-label text-caption-2-semibold">Surface</p>

      <div class="color-picker-grid color-picker-grid--surface">
        @for (surface of surfaceColors; track surface.key) {
          <button type="button" class="color-swatch" [class.active]="currentSurfaceKey() === surface.key" [style.background]="surface.swatch" [asTooltip]="surface.label" tooltipPosition="top" [attr.aria-label]="'Seleccionar superficie ' + surface.label" [attr.aria-pressed]="currentSurfaceKey() === surface.key" (click)="selectSurface(surface.key)">
            @if (currentSurfaceKey() === surface.key) {
              <span class="check text-caption-2-bold" aria-hidden="true">✓</span>
            }
          </button>
        }
      </div>
    </div>
  </div>
</div>

<as-button icon="Palette" variant="outlined" [size]="size()" iconSize="20" [styleClass]="pickerButtonClass()" ariaLabel="Seleccionar paleta de colores" [asTooltip]="$any(triggerTooltip()) || undefined" [tooltipPosition]="triggerTooltipPosition()" [tooltipStyleClass]="triggerTooltipStyleClass()" [showDelay]="triggerTooltipDelay()" (onClick)="toggle(panel, $event)" />
