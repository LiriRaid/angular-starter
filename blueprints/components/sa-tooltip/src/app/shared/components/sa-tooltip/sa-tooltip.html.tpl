<div class="as-tooltip__text text-caption-2-regular">
  @if (template(); as contentTemplate) {
    <ng-container [ngTemplateOutlet]="contentTemplate" />
  } @else {
    {{ text() }}
  }
</div>
