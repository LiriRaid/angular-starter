@switch (kind()) {
  @case ('image') {
    <img class="as-media-preview__media" [src]="url()" [alt]="name()" />
  }
  @case ('video') {
    <video class="as-media-preview__media" [src]="url()" controls preload="metadata"></video>
  }
  @case ('audio') {
    <audio class="as-media-preview__audio" [src]="url()" controls preload="metadata"></audio>
  }
  @default {
    <a class="as-media-preview__document" [href]="url()" [attr.download]="name()" target="_blank" rel="noopener noreferrer">
      <as-icon name="file-text" [size]="28" />
      <span class="as-media-preview__name">{{ name() }}</span>
      <as-icon name="download" [size]="18" />
    </a>
  }
}
