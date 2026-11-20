import { ChangeDetectionStrategy, Component, signal } from '@angular/core';

/** Sección de ejemplo con datos de muestra. */
@Component({
  selector: '__PREFIX__-settings-general',
  templateUrl: './settings-general.html',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class SettingsGeneral {
  readonly organization = signal('My organization');
  readonly language = signal('English');
  readonly timeZone = signal('UTC');
}
