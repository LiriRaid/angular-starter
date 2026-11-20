import type { DestroyRef } from '@angular/core';

/** Runs `handler` once after `ms`; the timer is cleared if the owner is destroyed first. Returns a cancel function. */
export function safeTimeout(handler: () => void, ms: number, destroyRef: DestroyRef): () => void {
  const id = setTimeout(handler, ms);
  const cancel = (): void => clearTimeout(id);
  destroyRef.onDestroy(cancel);
  return cancel;
}

/** A timer you can set again: every `set` replaces the pending call, and destroying the owner clears it. */
export function createTimer(destroyRef: DestroyRef): {
  set: (handler: () => void, ms: number) => void;
  clear: () => void;
} {
  let id: ReturnType<typeof setTimeout> | undefined;

  const clear = (): void => {
    clearTimeout(id);
    id = undefined;
  };
  destroyRef.onDestroy(clear);

  return {
    set: (handler, ms) => {
      clear();
      id = setTimeout(handler, ms);
    },
    clear,
  };
}
