import { ChangeDetectionStrategy, Component, computed, inject, signal } from '@angular/core';

import { DesignPreferencesService } from '@core/design-preferences/design-preferences.service';
import { SaButton } from '@shared/components';

/**
 * El aviso de que el administrador guardó otro diseño (ADR-0029). No lo aplica: ofrece recargar la página, para que
 * nadie pierda lo que está haciendo. Cerrarlo lo oculta hasta que llegue un cambio nuevo.
 */
@Component({
  selector: '__PREFIX__-design-update-notice',
  imports: [SaButton],
  templateUrl: './design-update-notice.html',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class DesignUpdateNotice {
  protected readonly designPreferences = inject(DesignPreferencesService);

  private readonly dismissedVersion = signal<string | null>(null);

  protected readonly visible = computed(() => this.designPreferences.updateAvailable() && this.designPreferences.announcedVersion() !== this.dismissedVersion());

  protected reload(): void {
    this.designPreferences.reload();
  }

  protected dismiss(): void {
    this.dismissedVersion.set(this.designPreferences.announcedVersion());
  }
}
