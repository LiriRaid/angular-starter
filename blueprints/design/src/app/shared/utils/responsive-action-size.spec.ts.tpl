import { Component } from '@angular/core';
import { ComponentFixture, TestBed } from '@angular/core/testing';
import { afterEach, beforeEach, describe, expect, it } from 'vitest';
import { responsiveActionSize } from './responsive-action-size';

let capturedCallback: ((entries: Partial<ResizeObserverEntry>[]) => void) | null = null;

class FakeResizeObserver {
  constructor(callback: (entries: Partial<ResizeObserverEntry>[]) => void) {
    capturedCallback = callback;
  }
  observe(): void {}
  unobserve(): void {}
  disconnect(): void {}
}

@Component({ selector: 'app-test-host', template: '', standalone: true })
class TestHostComponent {
  readonly size = responsiveActionSize();
}

describe('responsiveActionSize', () => {
  let fixture: ComponentFixture<TestHostComponent>;
  let originalResizeObserver: typeof ResizeObserver;

  beforeEach(() => {
    originalResizeObserver = globalThis.ResizeObserver;
    globalThis.ResizeObserver = FakeResizeObserver as unknown as typeof ResizeObserver;
    capturedCallback = null;

    TestBed.configureTestingModule({ imports: [TestHostComponent] });
    fixture = TestBed.createComponent(TestHostComponent);
    fixture.detectChanges();
  });

  afterEach(() => {
    globalThis.ResizeObserver = originalResizeObserver;
  });

  it('cae a "medium" cuando el ancho no es medible (0 en jsdom)', () => {
    expect(fixture.componentInstance.size()).toBe('medium');
  });

  it('cambia a "small" cuando el ResizeObserver reporta un ancho menor a 768px', () => {
    capturedCallback?.([{ contentRect: { width: 500 } as DOMRectReadOnly }]);
    fixture.detectChanges();

    expect(fixture.componentInstance.size()).toBe('small');
  });

  it('vuelve a "medium" cuando el ancho reportado es 768px o más', () => {
    capturedCallback?.([{ contentRect: { width: 500 } as DOMRectReadOnly }]);
    fixture.detectChanges();

    capturedCallback?.([{ contentRect: { width: 900 } as DOMRectReadOnly }]);
    fixture.detectChanges();

    expect(fixture.componentInstance.size()).toBe('medium');
  });
});
