import { TestBed } from '@angular/core/testing';
import { provideAsIcons } from '@core/icons/icons.provider';
import { vi } from 'vitest';
import { AsToast } from './as-toast';
import { AsToastService } from './as-toast.service';

describe('AsToastService', () => {
  beforeEach(() => vi.useFakeTimers());
  afterEach(() => vi.useRealTimers());

  it('adds the messages in order, with their severity', () => {
    const service = TestBed.inject(AsToastService);
    service.success('Saved');
    service.error('Failed', { title: 'Oops' });
    expect(service.toasts().map((toast) => [toast.severity, toast.message, toast.title])).toEqual([
      ['success', 'Saved', ''],
      ['error', 'Failed', 'Oops'],
    ]);
  });

  it('removes a message after its duration', () => {
    const service = TestBed.inject(AsToastService);
    service.info('Hello', { duration: 1000 });
    vi.advanceTimersByTime(999);
    expect(service.toasts()).toHaveLength(1);
    vi.advanceTimersByTime(1);
    expect(service.toasts()).toHaveLength(0);
  });

  it('keeps a message with no duration until it is dismissed', () => {
    const service = TestBed.inject(AsToastService);
    const id = service.warn('Stay', { duration: 0 });
    vi.advanceTimersByTime(60_000);
    expect(service.toasts()).toHaveLength(1);
    service.dismiss(id);
    expect(service.toasts()).toHaveLength(0);
  });

  it('clears every message', () => {
    const service = TestBed.inject(AsToastService);
    service.info('a', { duration: 0 });
    service.info('b', { duration: 0 });
    service.clear();
    expect(service.toasts()).toEqual([]);
  });
});

describe('AsToast', () => {
  it('shows the messages and lets the user dismiss them', () => {
    TestBed.configureTestingModule({ imports: [AsToast], providers: [provideAsIcons()] });
    const service = TestBed.inject(AsToastService);
    const fixture = TestBed.createComponent(AsToast);
    service.error('The server did not answer', { title: 'Could not save', duration: 0 });
    fixture.detectChanges();

    const element = fixture.nativeElement as HTMLElement;
    const toast = element.querySelector('.as-toast');
    expect(toast?.getAttribute('role')).toBe('alert');
    expect(toast?.textContent).toContain('Could not save');
    expect(toast?.textContent).toContain('The server did not answer');

    (element.querySelector('.as-toast__close') as HTMLButtonElement).click();
    fixture.detectChanges();
    expect(element.querySelector('.as-toast')).toBeNull();
  });
});
