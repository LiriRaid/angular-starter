import { DestroyRef } from '@angular/core';

/** One-shot timeout auto-cleared on component destroy. Returns a cancel function. */
export function safeTimeout(handler: () => void, ms: number, destroyRef: DestroyRef): () => void {
  const id = setTimeout(handler, ms);
  const cancel = () => clearTimeout(id);
  destroyRef.onDestroy(cancel);
  return cancel;
}

/** Re-settable timer that auto-clears its previous pending call and cancels on destroy. */
export function createTimer(destroyRef: DestroyRef): {
  set: (handler: () => void, ms: number) => void;
  clear: () => void;
} {
  let id: ReturnType<typeof setTimeout> | null = null;

  const clear = () => {
    if (id !== null) {
      clearTimeout(id);
      id = null;
    }
  };

  destroyRef.onDestroy(clear);

  return {
    set: (handler: () => void, ms: number) => {
      clear();
      id = setTimeout(handler, ms);
    },
    clear,
  };
}
