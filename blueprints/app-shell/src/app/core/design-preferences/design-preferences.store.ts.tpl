import { InjectionToken, Signal, signal } from '@angular/core';
import type { DesignPreferences } from './design-preferences.service';

/** What the platform keeps: the preferences and the version that identifies this save (an ETag, a revision, a timestamp). */
export interface DesignPreferencesDocument {
  readonly version: string;
  /** Not trusted: the service keeps only the valid values, so an old or edited document never breaks the page. */
  readonly preferences: unknown;
}

/**
 * Where the design of the platform lives (ADR-0029): one document for every user, kept by your backend. The
 * administrator saves it, the others load it when the application starts. It is never the storage of the browser,
 * which would be seen by one person only.
 */
export interface DesignPreferencesStore {
  /** Who may press "Guardar cambios": connect it to your permissions. */
  readonly canSave: Signal<boolean>;
  /** The document of the platform, or `null` while nobody has saved one. Rejecting is the same as `null`. */
  load(): Promise<DesignPreferencesDocument | null>;
  /** Keeps the preferences for everyone and answers with the document, whose `version` is the new one. */
  save(preferences: DesignPreferences): Promise<DesignPreferencesDocument>;
}

/**
 * The store a project has until it connects its own: the document lives in memory, so a save lasts until the page is
 * reloaded. Without a backend there is nothing else to keep it in; see `docs/design-preferences.md`.
 */
export class MemoryDesignPreferencesStore implements DesignPreferencesStore {
  readonly canSave = signal(true).asReadonly();
  private document: DesignPreferencesDocument | null = null;
  private revision = 0;

  async load(): Promise<DesignPreferencesDocument | null> {
    return this.document;
  }

  async save(preferences: DesignPreferences): Promise<DesignPreferencesDocument> {
    this.document = { version: String(++this.revision), preferences };
    return this.document;
  }
}

export const DESIGN_PREFERENCES_STORE = new InjectionToken<DesignPreferencesStore>('DESIGN_PREFERENCES_STORE', {
  providedIn: 'root',
  factory: () => new MemoryDesignPreferencesStore(),
});
