@if (imageUrl(); as src) {
  <img [src]="src" [alt]="alt()" class="as-avatar as-avatar--img" [style.width]="sizeValue()" [style.height]="sizeValue()" [style.borderRadius]="radius()" />
} @else {
  <span [class]="initialsClass()" [style.width]="sizeValue()" [style.height]="sizeValue()" [style.borderRadius]="radius()" [style.background]="background()" [style.color]="color()">
    {{ label() }}
  </span>
}

@if (mode() === 'presence') {
  <span class="presence-dot" [style.width]="resolvedDotSize()" [style.height]="resolvedDotSize()" [style.bottom]="resolvedDotBottom()" [style.background]="dotBackground()" [attr.data-status]="presenceStatus()" aria-hidden="true">
    @if (dotIcon(); as icon) {
      <as-icon [name]="icon" [size]="resolvedDotIconSize()" />
    }
  </span>
}
