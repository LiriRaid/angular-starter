import type { DestroyRef } from '@angular/core';
import { vi } from 'vitest';
import { createTimer, safeTimeout } from './safe-timeout';

/** A DestroyRef whose owner can be destroyed by the test. */
function fakeDestroyRef(): { ref: DestroyRef; destroy: () => void } {
  const callbacks: Array<() => void> = [];
  const ref = {
    onDestroy: (callback: () => void) => {
      callbacks.push(callback);
      return () => undefined;
    },
  } as unknown as DestroyRef;
  return { ref, destroy: () => callbacks.forEach((callback) => callback()) };
}

describe('safeTimeout', () => {
  beforeEach(() => vi.useFakeTimers());
  afterEach(() => vi.useRealTimers());

  it('runs the handler after the delay', () => {
    const handler = vi.fn();
    safeTimeout(handler, 100, fakeDestroyRef().ref);
    vi.advanceTimersByTime(99);
    expect(handler).not.toHaveBeenCalled();
    vi.advanceTimersByTime(1);
    expect(handler).toHaveBeenCalledOnce();
  });

  it('does not run after the owner is destroyed', () => {
    const handler = vi.fn();
    const owner = fakeDestroyRef();
    safeTimeout(handler, 100, owner.ref);
    owner.destroy();
    vi.advanceTimersByTime(200);
    expect(handler).not.toHaveBeenCalled();
  });

  it('can be cancelled', () => {
    const handler = vi.fn();
    const cancel = safeTimeout(handler, 100, fakeDestroyRef().ref);
    cancel();
    vi.advanceTimersByTime(200);
    expect(handler).not.toHaveBeenCalled();
  });
});

describe('createTimer', () => {
  beforeEach(() => vi.useFakeTimers());
  afterEach(() => vi.useRealTimers());

  it('replaces the pending call every time it is set', () => {
    const first = vi.fn();
    const second = vi.fn();
    const timer = createTimer(fakeDestroyRef().ref);
    timer.set(first, 100);
    timer.set(second, 100);
    vi.advanceTimersByTime(100);
    expect(first).not.toHaveBeenCalled();
    expect(second).toHaveBeenCalledOnce();
  });

  it('clears the pending call, also when the owner is destroyed', () => {
    const handler = vi.fn();
    const owner = fakeDestroyRef();
    const timer = createTimer(owner.ref);
    timer.set(handler, 100);
    timer.clear();
    vi.advanceTimersByTime(100);
    expect(handler).not.toHaveBeenCalled();

    timer.set(handler, 100);
    owner.destroy();
    vi.advanceTimersByTime(100);
    expect(handler).not.toHaveBeenCalled();
  });
});
