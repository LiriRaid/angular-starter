import { Signal, signal } from '@angular/core';
import type { DesignPreferences } from './design-preferences.service';
import type { DesignPreferencesDocument, DesignPreferencesStore } from './design-preferences.store';

export interface HttpDesignPreferencesStoreOptions {
  /** The endpoint of the document, for example `/api/design-preferences` (see `docs/design-preferences.md`). */
  readonly url: string;
  /** Headers of every request, such as the token of the session. */
  readonly headers?: () => Record<string, string>;
  /** Who may press "Guardar cambios". Default: everybody; the server answers 403 to whoever may not. */
  readonly canSave?: Signal<boolean>;
  /** Replaces `fetch`; for tests. */
  readonly fetch?: typeof fetch;
}

/** `{ version, preferences }`, or `null` when the server answered without a document. */
const toDocument = (body: unknown): DesignPreferencesDocument => {
  const { version, preferences } = (body ?? {}) as Record<string, unknown>;
  if (typeof version !== 'string') throw new Error('The design document has no version.');
  return { version, preferences };
};

/**
 * The design of the platform on your server, over `fetch` (it needs no module and carries the cookies). `GET` brings
 * the document, `PUT` saves it; the contract of the endpoint is in `docs/design-preferences.md`. For `HttpClient` and
 * its interceptors, write a store that injects it: the contract is the interface, this is one implementation.
 */
export class HttpDesignPreferencesStore implements DesignPreferencesStore {
  readonly canSave: Signal<boolean>;

  constructor(private readonly options: HttpDesignPreferencesStoreOptions) {
    this.canSave = options.canSave ?? signal(true).asReadonly();
  }

  async load(): Promise<DesignPreferencesDocument | null> {
    const response = await this.request({ method: 'GET' });
    if (response.status === 404 || response.status === 204) return null;
    if (!response.ok) throw new Error(`The design could not be loaded (${response.status}).`);
    return toDocument(await response.json());
  }

  async save(preferences: DesignPreferences): Promise<DesignPreferencesDocument> {
    const response = await this.request({ method: 'PUT', body: JSON.stringify({ preferences }), contentType: 'application/json' });
    if (!response.ok) throw new Error(`The design could not be saved (${response.status}).`);
    return toDocument(await response.json());
  }

  private request({ method, body, contentType }: { method: string; body?: string; contentType?: string }): Promise<Response> {
    const headers: Record<string, string> = { accept: 'application/json', ...(contentType ? { 'content-type': contentType } : {}), ...this.options.headers?.() };
    return (this.options.fetch ?? fetch)(this.options.url, { method, headers, body, credentials: 'include' });
  }
}
