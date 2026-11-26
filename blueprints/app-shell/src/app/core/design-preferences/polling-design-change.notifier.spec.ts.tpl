import { PollingDesignChangeNotifier } from './polling-design-change.notifier';
import type { DesignChange } from './design-change-notifier';

const versionResponse = (version: string): Response => new Response(JSON.stringify({ version }), { status: 200, headers: { 'content-type': 'application/json' } });

describe('PollingDesignChangeNotifier', () => {
  const url = '/api/design-preferences/version';
  let fetchSpy: ReturnType<typeof vi.fn<typeof fetch>>;
  let changes: DesignChange[];
  let notifier: PollingDesignChangeNotifier;
  const listener = (change: DesignChange): void => {
    changes.push(change);
  };

  const hide = (hidden: boolean): void => {
    Object.defineProperty(document, 'hidden', { configurable: true, get: () => hidden });
    document.dispatchEvent(new Event('visibilitychange'));
  };

  beforeEach(() => {
    vi.useFakeTimers();
    changes = [];
    fetchSpy = vi.fn<typeof fetch>().mockImplementation(async () => versionResponse('v2'));
    notifier = new PollingDesignChangeNotifier({ url, intervalMs: 60_000, minGapMs: 10_000, fetch: fetchSpy });
  });

  afterEach(() => {
    notifier.disconnect();
    hide(false);
    vi.useRealTimers();
  });

  it('asks for the version of the design every minute and reports it', async () => {
    notifier.connect(listener);
    expect(fetchSpy).not.toHaveBeenCalled();
    await vi.advanceTimersByTimeAsync(60_000);
    expect(fetchSpy).toHaveBeenCalledTimes(1);
    expect(fetchSpy.mock.calls[0][0]).toBe(url);
    expect(changes).toEqual([{ version: 'v2' }]);
    await vi.advanceTimersByTimeAsync(60_000);
    expect(fetchSpy).toHaveBeenCalledTimes(2);
  });

  it('sends the headers of the project', async () => {
    notifier = new PollingDesignChangeNotifier({ url, fetch: fetchSpy, headers: () => ({ authorization: 'Bearer token' }) });
    notifier.connect(listener);
    await vi.advanceTimersByTimeAsync(60_000);
    expect(new Headers(fetchSpy.mock.calls[0][1]?.headers).get('authorization')).toBe('Bearer token');
  });

  it('checks again when the tab comes back after a while, but not right after a check', async () => {
    notifier.connect(listener);
    hide(true);
    await vi.advanceTimersByTimeAsync(30_000);
    hide(false);
    await vi.advanceTimersByTimeAsync(0);
    expect(fetchSpy).toHaveBeenCalledTimes(1);
    hide(true);
    await vi.advanceTimersByTimeAsync(5_000);
    hide(false);
    await vi.advanceTimersByTimeAsync(0);
    expect(fetchSpy).toHaveBeenCalledTimes(1);
  });

  it('does not ask while the tab is hidden', async () => {
    notifier.connect(listener);
    hide(true);
    await vi.advanceTimersByTimeAsync(120_000);
    expect(fetchSpy).not.toHaveBeenCalled();
  });

  it('ignores a failure and an answer without a version, and goes on', async () => {
    fetchSpy.mockRejectedValueOnce(new Error('offline')).mockResolvedValueOnce(new Response('{}', { status: 200 })).mockResolvedValueOnce(new Response(null, { status: 500 }));
    notifier.connect(listener);
    await vi.advanceTimersByTimeAsync(180_000);
    expect(changes).toEqual([]);
    await vi.advanceTimersByTimeAsync(60_000);
    expect(changes).toEqual([{ version: 'v2' }]);
  });

  it('stops asking when it is disconnected', async () => {
    notifier.connect(listener);
    notifier.disconnect();
    await vi.advanceTimersByTimeAsync(120_000);
    expect(fetchSpy).not.toHaveBeenCalled();
  });
});
