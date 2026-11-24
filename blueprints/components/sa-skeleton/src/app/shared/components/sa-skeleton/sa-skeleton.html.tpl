@if (!loading()) {
  <ng-content />
} @else {
  @switch (layout()) {
  @case ('stat') {
    <as-skeleton [width]="valueWidth()" [textClass]="valueClass()" />
    <as-skeleton [width]="metaWidth()" [textClass]="metaClass()" />
  }
  @case ('row') {
    <div class="flex min-w-0 items-center" [style.gap]="rowGap()">
      @if (avatarShape() !== 'none') {
        <as-skeleton [shape]="avatarShape() === 'circle' ? 'circle' : 'rectangle'" [width]="avatarSize()" [height]="avatarSize()" [radius]="resolvedAvatarRadius()" />
      }
      <div class="flex min-w-0 flex-1 flex-col" [style.gap]="textGap()">
        <as-skeleton [width]="titleWidth()" [textClass]="titleClass()" />
        <as-skeleton [width]="subtitleWidth()" [textClass]="subtitleClass()" />
      </div>
    </div>
  }
  @case ('circles') {
    <div class="flex items-center" [style.gap]="itemGap()">
      @for (i of circlesRange(); track i) {
        <as-skeleton [size]="itemSize()" [radius]="itemRadius()" />
      }
    </div>
  }
  @default {
    @if (lines() > 1) {
      <div class="flex flex-col" [style.gap]="lineGap()">
        @for (i of paragraphLines(); track i) {
          <as-skeleton [width]="i === lines() - 1 ? lastLineWidth() : width()" [textClass]="textClass()" />
        }
      </div>
    } @else if (textClass()) {
      <span [class]="lineClass()">
        <span class="as-skeleton as-skeleton-bar" [style.width]="fillWidth()" style="height: 0.72em" [style.border-radius]="radius()"></span>
      </span>
    } @else {
      <div class="as-skeleton" [class]="alignClass()" [style.width]="size() ?? fillWidth()" [style.height]="size() ?? fillHeight()" [style.border-radius]="resolvedRadius()"></div>
    }
  }
  }
}
