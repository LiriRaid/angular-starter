import { ChangeDetectionStrategy, Component, computed, input, ViewEncapsulation } from '@angular/core';

export type SaDividerLayout = 'horizontal' | 'vertical';
export type SaDividerType = 'solid' | 'dashed' | 'dotted';
export type SaDividerAlign = 'left' | 'center' | 'right' | 'top' | 'bottom';

@Component({
  selector: 'sa-divider',
  standalone: true,
  templateUrl: './sa-divider.html',
  styleUrl: './sa-divider.css',
  changeDetection: ChangeDetectionStrategy.OnPush,
  encapsulation: ViewEncapsulation.None,
  host: {
    role: 'separator',
    '[attr.aria-orientation]': 'layout()',
    '[class]': 'hostClasses()',
  },
})
export class SaDivider {
  readonly layout = input<SaDividerLayout>('horizontal');
  readonly type = input<SaDividerType>('solid');
  readonly align = input<SaDividerAlign | undefined>(undefined);

  readonly hostClasses = computed(() => {
    const layout = this.layout();
    const align = this.align();

    return [
      'sa-divider',
      `sa-divider-${layout}`,
      `sa-divider-${this.type()}`,
      layout === 'horizontal' && (!align || align === 'left') ? 'sa-divider-left' : '',
      layout === 'horizontal' && align === 'center' ? 'sa-divider-center' : '',
      layout === 'horizontal' && align === 'right' ? 'sa-divider-right' : '',
      layout === 'vertical' && align === 'top' ? 'sa-divider-top' : '',
      layout === 'vertical' && (!align || align === 'center') ? 'sa-divider-center' : '',
      layout === 'vertical' && align === 'bottom' ? 'sa-divider-bottom' : '',
    ]
      .filter(Boolean)
      .join(' ');
  });
}
