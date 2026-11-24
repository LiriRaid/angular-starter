import { ChangeDetectionStrategy, Component, inject } from '@angular/core';
import { RouterOutlet } from '@angular/router';
import { SaToast } from '@shared/components';
import { AlertService } from '@shared/services';

@Component({
  imports: [RouterOutlet, SaToast],
  selector: '__PREFIX__-empty',
  template: `
    <router-outlet />
    @if (alertService.toastActive()) {
      <sa-toast />
    }
  `,
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class Empty {
  protected readonly alertService = inject(AlertService);
}
