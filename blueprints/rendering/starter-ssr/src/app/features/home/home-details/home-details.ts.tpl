import { ChangeDetectionStrategy, Component, signal } from '@angular/core';

/**
 * Rendered on the server and hydrated by the browser only when it scrolls into view, because the
 * home page declares it inside `@defer (hydrate on viewport)`.
 */
@Component({
  selector: '__PREFIX__-home-details',
  templateUrl: './home-details.html',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class HomeDetails {
  protected readonly clicks = signal(0);

  protected increment(): void {
    this.clicks.update((count) => count + 1);
  }
}
