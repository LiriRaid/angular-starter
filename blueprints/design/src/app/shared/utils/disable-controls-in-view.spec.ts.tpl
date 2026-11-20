import { TestBed } from '@angular/core/testing';
import { signal } from '@angular/core';
import { FormControl } from '@angular/forms';
import { describe, expect, it, vi } from 'vitest';
import { disableControlsInView } from './disable-controls-in-view';

describe('disableControlsInView', () => {
  it('deshabilita los controles cuando isView es true y los habilita cuando es false', async () => {
    const isView = signal(false);
    const control = new FormControl('x');

    TestBed.runInInjectionContext(() => disableControlsInView(isView, [control]));
    await vi.waitFor(() => expect(control.disabled).toBe(false));

    isView.set(true);
    await vi.waitFor(() => expect(control.disabled).toBe(true));

    isView.set(false);
    await vi.waitFor(() => expect(control.disabled).toBe(false));
  });

  it('aplica el estado inicial de isView sin esperar un cambio posterior', async () => {
    const isView = signal(true);
    const control = new FormControl('x');

    TestBed.runInInjectionContext(() => disableControlsInView(isView, [control]));

    await vi.waitFor(() => expect(control.disabled).toBe(true));
  });
});
