import { ChangeDetectionStrategy, Component } from '@angular/core';
import { SaIcon } from '@shared/components';

interface SampleReport {
  readonly name: string;
  readonly description: string;
  readonly lastRun: string;
}

/** Página de ejemplo con datos de muestra: reemplázala por los reportes reales del producto. */
@Component({
  selector: '__PREFIX__-reports',
  imports: [SaIcon],
  templateUrl: './reports.html',
  styleUrl: './reports.css',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class Reports {
  readonly reports: readonly SampleReport[] = [
    { name: 'Monthly summary', description: 'Totals and trends of the last 30 days.', lastRun: 'Today, 08:00' },
    { name: 'Activity by user', description: 'What each user did and when.', lastRun: 'Yesterday, 18:30' },
    { name: 'Growth', description: 'New users and organizations per week.', lastRun: '3 days ago' },
  ];
}
