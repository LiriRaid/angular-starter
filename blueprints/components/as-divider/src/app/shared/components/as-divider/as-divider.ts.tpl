import { ChangeDetectionStrategy, Component, computed, input, ViewEncapsulation } from '@angular/core';

export type AsDividerLayout = 'horizontal' | 'vertical';
export type AsDividerType = 'solid' | 'dashed' | 'dotted';
export type AsDividerAlign = 'left' | 'center' | 'right' | 'top' | 'bottom';

@Component({
  selector: 'as-divider',
  standalone: true,
  templateUrl: './as-divider.html',
  styleUrl: './as-divider.css',
  changeDetection: ChangeDetectionStrategy.OnPush,
  encapsulation: ViewEncapsulation.None,
  host: {
    role: 'separator',
    '[attr.aria-orientation]': 'layout()',
    '[class]': 'hostClasses()',
  },
})
export class AsDivider {
  readonly layout = input<AsDividerLayout>('horizontal');
  readonly type = input<AsDividerType>('solid');
  readonly align = input<AsDividerAlign | undefined>(undefined);

  readonly hostClasses = computed(() => {
    const layout = this.layout();
    const align = this.align();

    return [
      'as-divider',
      `as-divider-${layout}`,
      `as-divider-${this.type()}`,
      layout === 'horizontal' && (!align || align === 'left') ? 'as-divider-left' : '',
      layout === 'horizontal' && align === 'center' ? 'as-divider-center' : '',
      layout === 'horizontal' && align === 'right' ? 'as-divider-right' : '',
      layout === 'vertical' && align === 'top' ? 'as-divider-top' : '',
      layout === 'vertical' && (!align || align === 'center') ? 'as-divider-center' : '',
      layout === 'vertical' && align === 'bottom' ? 'as-divider-bottom' : '',
    ]
      .filter(Boolean)
      .join(' ');
  });
}
