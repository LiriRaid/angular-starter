import { signal } from '@angular/core';
import { DEFAULT_DESIGN_PREFERENCES } from './design-preferences.service';
import { HttpDesignPreferencesStore } from './http-design-preferences.store';

const answer = (status: number, body?: unknown): Response => new Response(body === undefined ? null : JSON.stringify(body), { status, headers: { 'content-type': 'application/json' } });

describe('HttpDesignPreferencesStore', () => {
  const url = '/api/design-preferences';
  let fetchSpy: ReturnType<typeof vi.fn<typeof fetch>>;

  const create = (options: Partial<ConstructorParameters<typeof HttpDesignPreferencesStore>[0]> = {}) => new HttpDesignPreferencesStore({ url, fetch: fetchSpy, ...options });

  beforeEach(() => {
    fetchSpy = vi.fn<typeof fetch>();
  });

  describe('load', () => {
    it('gets the document of the platform with the credentials and the headers of the project', async () => {
      fetchSpy.mockResolvedValue(answer(200, { version: 'v3', preferences: { radius: 'sharp' } }));
      const document = await create({ headers: () => ({ authorization: 'Bearer token' }) }).load();
      expect(document).toEqual({ version: 'v3', preferences: { radius: 'sharp' } });
      const [address, init] = fetchSpy.mock.calls[0];
      expect(address).toBe(url);
      expect(init?.credentials).toBe('include');
      expect(new Headers(init?.headers).get('authorization')).toBe('Bearer token');
    });

    it('has no document while nobody has saved one (404 or 204)', async () => {
      fetchSpy.mockResolvedValueOnce(answer(404)).mockResolvedValueOnce(answer(204));
      expect(await create().load()).toBeNull();
      expect(await create().load()).toBeNull();
    });

    it('rejects when the server fails or answers with something else than a document', async () => {
      fetchSpy.mockResolvedValueOnce(answer(500)).mockResolvedValueOnce(answer(200, { preferences: {} }));
      await expect(create().load()).rejects.toThrow();
      await expect(create().load()).rejects.toThrow();
    });
  });

  describe('save', () => {
    it('puts the preferences and answers with the new version', async () => {
      fetchSpy.mockResolvedValue(answer(200, { version: 'v4', preferences: DEFAULT_DESIGN_PREFERENCES }));
      const document = await create().save(DEFAULT_DESIGN_PREFERENCES);
      expect(document.version).toBe('v4');
      const [address, init] = fetchSpy.mock.calls[0];
      expect(address).toBe(url);
      expect(init?.method).toBe('PUT');
      expect(new Headers(init?.headers).get('content-type')).toBe('application/json');
      expect(JSON.parse(String(init?.body))).toEqual({ preferences: DEFAULT_DESIGN_PREFERENCES });
    });

    it('rejects when the server does not accept it (403, 500)', async () => {
      fetchSpy.mockResolvedValueOnce(answer(403)).mockResolvedValueOnce(answer(500));
      await expect(create().save(DEFAULT_DESIGN_PREFERENCES)).rejects.toThrow();
      await expect(create().save(DEFAULT_DESIGN_PREFERENCES)).rejects.toThrow();
    });
  });

  describe('canSave', () => {
    it('lets everybody try, the server decides', () => {
      expect(create().canSave()).toBe(true);
    });

    it('is the signal of the project when it has one', () => {
      const allowed = signal(false);
      const store = create({ canSave: allowed });
      expect(store.canSave()).toBe(false);
      allowed.set(true);
      expect(store.canSave()).toBe(true);
    });
  });
});
