@if (!loading()) {
  <ng-content />
} @else {
  @switch (layout()) {
  @case ('stat') {
    <sa-skeleton [width]="valueWidth()" [textClass]="valueClass()" />
    <sa-skeleton [width]="metaWidth()" [textClass]="metaClass()" />
  }
  @case ('row') {
    <div class="flex min-w-0 items-center" [style.gap]="rowGap()">
      @if (avatarShape() !== 'none') {
        <sa-skeleton [shape]="avatarShape() === 'circle' ? 'circle' : 'rectangle'" [width]="avatarSize()" [height]="avatarSize()" [radius]="resolvedAvatarRadius()" />
      }
      <div class="flex min-w-0 flex-1 flex-col" [style.gap]="textGap()">
        <sa-skeleton [width]="titleWidth()" [textClass]="titleClass()" />
        <sa-skeleton [width]="subtitleWidth()" [textClass]="subtitleClass()" />
      </div>
    </div>
  }
  @case ('circles') {
    <div class="flex items-center" [style.gap]="itemGap()">
      @for (i of circlesRange(); track i) {
        <sa-skeleton [size]="itemSize()" [radius]="itemRadius()" />
      }
    </div>
  }
  @default {
    @if (lines() > 1) {
      <div class="flex flex-col" [style.gap]="lineGap()">
        @for (i of paragraphLines(); track i) {
          <sa-skeleton [width]="i === lines() - 1 ? lastLineWidth() : width()" [textClass]="textClass()" />
        }
      </div>
    } @else if (textClass()) {
      <span [class]="lineClass()">
        <span class="sa-skeleton sa-skeleton-bar" [style.width]="fillWidth()" style="height: 0.72em" [style.border-radius]="radius()"></span>
      </span>
    } @else {
      <div class="sa-skeleton" [class]="alignClass()" [style.width]="size() ?? fillWidth()" [style.height]="size() ?? fillHeight()" [style.border-radius]="resolvedRadius()"></div>
    }
  }
  }
}
