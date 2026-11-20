import { TestBed } from '@angular/core/testing';
import { beforeEach } from 'vitest';
import { LUCIDE_ICONS } from '@lucide/angular';
import { AS_LUCIDE_ICONS } from '@core/common/icons/lucide-icons.provider';

// jsdom does not implement ResizeObserver; several components observe their host with it.
if (typeof globalThis.ResizeObserver === 'undefined') {
  globalThis.ResizeObserver = class {
    observe(): void {}
    unobserve(): void {}
    disconnect(): void {}
  };
}

if (typeof document.elementFromPoint !== 'function') {
  document.elementFromPoint = () => document.body;
}

Object.defineProperty(HTMLCanvasElement.prototype, 'getContext', {
  configurable: true,
  value: () => null,
});

// The icons the application registers at startup (app.config.ts), available to every spec.
beforeEach(() => {
  TestBed.configureTestingModule({
    providers: [{ provide: LUCIDE_ICONS, useExisting: AS_LUCIDE_ICONS }],
  });
});
