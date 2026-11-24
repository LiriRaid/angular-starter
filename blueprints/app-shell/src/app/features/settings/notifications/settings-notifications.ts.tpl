import { ChangeDetectionStrategy, Component, signal } from '@angular/core';
import { SaToggle } from '@shared/components';

/** Sección de ejemplo con datos de muestra. */
@Component({
  selector: '__PREFIX__-settings-notifications',
  imports: [SaToggle],
  templateUrl: './settings-notifications.html',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class SettingsNotifications {
  readonly email = signal(true);
  readonly weeklySummary = signal(false);
}
