import { Injectable, inject } from '@angular/core';
import { PresenceService } from './presence.service';

/**
 * Applies the live status to a list of items with an `id` and a `presenceStatus` (users, team
 * members, ...), so a table or a list shows it without a reload:
 * - the item that is the current user takes `PresenceService.status()`, which changes the moment
 *   the user picks a status in the menu;
 * - every other item takes the status the server last sent, and keeps its own when it sent none.
 *
 * Call it from a `computed`, so the list follows the signals it reads:
 * `rows = computed(() => this.live.apply(this.users()))`.
 */
@Injectable({ providedIn: 'root' })
export class LivePresenceService {
  private readonly presence = inject(PresenceService);

  apply<T extends { id: string; presenceStatus?: string }>(items: readonly T[]): T[] {
    const selfId = this.presence.selfId();
    const ownStatus = this.presence.status();
    const users = this.presence.users();

    return items.map((item) => {
      if (selfId !== null && item.id === selfId) return { ...item, presenceStatus: ownStatus };
      const live = users.get(item.id);
      return live ? { ...item, presenceStatus: live } : item;
    });
  }
}
