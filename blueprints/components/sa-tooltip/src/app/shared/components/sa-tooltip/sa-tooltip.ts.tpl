import { NgTemplateOutlet } from '@angular/common';
import { ChangeDetectionStrategy, Component, TemplateRef, ViewEncapsulation, computed, input } from '@angular/core';

@Component({
  selector: 'sa-tooltip-panel',
  standalone: true,
  imports: [NgTemplateOutlet],
  templateUrl: './sa-tooltip.html',
  encapsulation: ViewEncapsulation.None,
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class Tooltip {
  readonly content = input.required<string | TemplateRef<unknown>>();
  readonly text = computed<string | null>(() => {
    const content = this.content();
    return typeof content === 'string' ? content : null;
  });
  readonly template = computed<TemplateRef<unknown> | null>(() => {
    const content = this.content();
    return typeof content === 'string' ? null : content;
  });
}
