@if (showImage()) {
  <img class="as-avatar__image" [src]="src()" alt="" (error)="onError()" />
} @else {
  <span class="as-avatar__initials" aria-hidden="true">{{ initials() }}</span>
}
@if (status()) {
  <span class="as-avatar__status" [attr.data-status]="status()"></span>
}
