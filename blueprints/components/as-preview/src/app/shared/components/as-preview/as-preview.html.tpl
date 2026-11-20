<div class="as-preview" [class.as-preview--disabled]="disabled()">
  <button
    type="button"
    class="as-preview__frame"
    [attr.aria-label]="shown() ? 'Change ' + label() : 'Choose ' + label()"
    [disabled]="disabled()"
    (click)="open()"
  >
    @if (shown(); as url) {
      <img class="as-preview__image" [src]="url" [alt]="label()" />
    } @else {
      <as-icon class="as-preview__placeholder" [name]="placeholderIcon()" [size]="32" />
    }
  </button>

  <div class="as-preview__side">
    @if (hint()) {
      <p class="as-preview__hint">{{ hint() }}</p>
    }
    @if (shown() && !disabled()) {
      <button type="button" class="as-preview__remove" (click)="remove()">
        <as-icon name="trash-2" [size]="14" />
        Remove {{ label() }}
      </button>
    }
  </div>

  <input #picker class="as-preview__input" type="file" tabindex="-1" aria-hidden="true" [accept]="accept()" (change)="onPicked($event)" />
</div>
