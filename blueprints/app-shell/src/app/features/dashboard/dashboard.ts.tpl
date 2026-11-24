import { ChangeDetectionStrategy, Component } from '@angular/core';
import { SaIcon } from '@shared/components';

interface Metric {
  readonly label: string;
  readonly value: string;
  readonly trend: string;
  readonly icon: string;
}

interface Activity {
  readonly title: string;
  readonly detail: string;
  readonly time: string;
  readonly icon: string;
}

/** Página de ejemplo con datos de muestra: reemplázala por el resumen real del producto. */
@Component({
  selector: '__PREFIX__-dashboard',
  imports: [SaIcon],
  templateUrl: './dashboard.html',
  styleUrl: './dashboard.css',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class Dashboard {
  readonly metrics: readonly Metric[] = [
    { label: 'Users', value: '1,248', trend: '+12.5%', icon: 'Users' },
    { label: 'Organizations', value: '312', trend: '+8.1%', icon: 'Company' },
    { label: 'Records', value: '5,840', trend: '+22.3%', icon: 'Table' },
    { label: 'Revenue', value: '$28,420', trend: '+16.9%', icon: 'TrendingUp' },
  ];

  readonly activity: readonly Activity[] = [
    { title: 'New user registered', detail: 'Maria Lopez', time: '5 min ago', icon: 'UserPlus' },
    { title: 'Organization updated', detail: 'TechSolutions Inc.', time: '18 min ago', icon: 'Company' },
    { title: 'Settings changed', detail: 'Application appearance', time: '32 min ago', icon: 'Settings' },
  ];
}
