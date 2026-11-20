import { describe, expect, it, vi, beforeEach, afterEach } from 'vitest';
import { DestroyRef } from '@angular/core';
import { safeTimeout, createTimer } from './safe-timeout';

/** Minimal DestroyRef mock: stores all registered callbacks so tests can trigger destroy. */
function makeDestroyRef(): { ref: DestroyRef; triggerDestroy: () => void } {
  const callbacks: (() => void)[] = [];
  const ref = {
    onDestroy(fn: () => void) {
      callbacks.push(fn);
      return () => {};
    },
  } as unknown as DestroyRef;
  return {
    ref,
    triggerDestroy: () => callbacks.forEach((fn) => fn()),
  };
}

describe('safeTimeout', () => {
  beforeEach(() => vi.useFakeTimers());
  afterEach(() => vi.useRealTimers());

  it('fires the handler after the specified delay', () => {
    const handler = vi.fn();
    const { ref } = makeDestroyRef();

    safeTimeout(handler, 300, ref);
    expect(handler).not.toHaveBeenCalled();

    vi.advanceTimersByTime(300);
    expect(handler).toHaveBeenCalledTimes(1);
  });

  it('does not fire the handler before the delay elapses', () => {
    const handler = vi.fn();
    const { ref } = makeDestroyRef();

    safeTimeout(handler, 500, ref);
    vi.advanceTimersByTime(499);
    expect(handler).not.toHaveBeenCalled();
  });

  it('returned cancel function prevents the handler from firing', () => {
    const handler = vi.fn();
    const { ref } = makeDestroyRef();

    const cancel = safeTimeout(handler, 300, ref);
    cancel();

    vi.advanceTimersByTime(300);
    expect(handler).not.toHaveBeenCalled();
  });

  it('auto-cancels when destroyRef.onDestroy fires before the timer', () => {
    const handler = vi.fn();
    const { ref, triggerDestroy } = makeDestroyRef();

    safeTimeout(handler, 300, ref);
    triggerDestroy();

    vi.advanceTimersByTime(300);
    expect(handler).not.toHaveBeenCalled();
  });

  it('registers a cleanup callback with destroyRef', () => {
    const onDestroySpy = vi.fn().mockReturnValue(() => {});
    const ref = { onDestroy: onDestroySpy } as unknown as DestroyRef;

    safeTimeout(() => {}, 100, ref);
    expect(onDestroySpy).toHaveBeenCalledTimes(1);
    expect(typeof onDestroySpy.mock.calls[0][0]).toBe('function');
  });
});

describe('createTimer', () => {
  beforeEach(() => vi.useFakeTimers());
  afterEach(() => vi.useRealTimers());

  it('set fires the handler after the specified delay', () => {
    const handler = vi.fn();
    const { ref } = makeDestroyRef();

    const timer = createTimer(ref);
    timer.set(handler, 200);

    vi.advanceTimersByTime(200);
    expect(handler).toHaveBeenCalledTimes(1);
  });

  it('set cancels a previous pending handler before scheduling the new one', () => {
    const first = vi.fn();
    const second = vi.fn();
    const { ref } = makeDestroyRef();

    const timer = createTimer(ref);
    timer.set(first, 300);
    timer.set(second, 300); // replaces the first

    vi.advanceTimersByTime(300);
    expect(first).not.toHaveBeenCalled();
    expect(second).toHaveBeenCalledTimes(1);
  });

  it('clear prevents a pending handler from firing', () => {
    const handler = vi.fn();
    const { ref } = makeDestroyRef();

    const timer = createTimer(ref);
    timer.set(handler, 200);
    timer.clear();

    vi.advanceTimersByTime(200);
    expect(handler).not.toHaveBeenCalled();
  });

  it('clear is a no-op when no timer is pending', () => {
    const { ref } = makeDestroyRef();
    const timer = createTimer(ref);
    // should not throw
    expect(() => timer.clear()).not.toThrow();
  });

  it('auto-cancels on destroyRef.onDestroy', () => {
    const handler = vi.fn();
    const { ref, triggerDestroy } = makeDestroyRef();

    const timer = createTimer(ref);
    timer.set(handler, 300);
    triggerDestroy();

    vi.advanceTimersByTime(300);
    expect(handler).not.toHaveBeenCalled();
  });

  it('registers an onDestroy cleanup when created', () => {
    const onDestroySpy = vi.fn().mockReturnValue(() => {});
    const ref = { onDestroy: onDestroySpy } as unknown as DestroyRef;

    createTimer(ref);
    expect(onDestroySpy).toHaveBeenCalledTimes(1);
  });
});
