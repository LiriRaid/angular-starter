import { Injectable, signal } from '@angular/core';

export type AsToastSeverity = 'success' | 'info' | 'warn' | 'error';

export interface AsToastItem {
  readonly id: number;
  readonly severity: AsToastSeverity;
  readonly title: string;
  readonly message: string;
}

export interface AsToastOptions {
  severity?: AsToastSeverity;
  title?: string;
  message: string;
  /** Milliseconds before it goes away; 0 keeps it until the user closes it. */
  duration?: number;
}

const DEFAULT_DURATION_MS = 5000;

/**
 * Shows short messages in the `<as-toast />` that the application places once, usually in the root
 * component.
 *
 * ```ts
 * private readonly toast = inject(AsToastService);
 * this.toast.success('Customer saved');
 * this.toast.error('The server did not answer', { title: 'Could not save' });
 * ```
 */
@Injectable({ providedIn: 'root' })
export class AsToastService {
  private readonly items = signal<readonly AsToastItem[]>([]);
  private nextId = 1;

  /** What is on screen now, oldest first. */
  readonly toasts = this.items.asReadonly();

  show({ severity = 'info', title = '', message, duration = DEFAULT_DURATION_MS }: AsToastOptions): number {
    const id = this.nextId++;
    this.items.update((current) => [...current, { id, severity, title, message }]);
    if (duration > 0 && typeof setTimeout === 'function') setTimeout(() => this.dismiss(id), duration);
    return id;
  }

  success(message: string, options: Omit<AsToastOptions, 'message' | 'severity'> = {}): number {
    return this.show({ ...options, message, severity: 'success' });
  }

  info(message: string, options: Omit<AsToastOptions, 'message' | 'severity'> = {}): number {
    return this.show({ ...options, message, severity: 'info' });
  }

  warn(message: string, options: Omit<AsToastOptions, 'message' | 'severity'> = {}): number {
    return this.show({ ...options, message, severity: 'warn' });
  }

  error(message: string, options: Omit<AsToastOptions, 'message' | 'severity'> = {}): number {
    return this.show({ ...options, message, severity: 'error' });
  }

  dismiss(id: number): void {
    this.items.update((current) => current.filter((toast) => toast.id !== id));
  }

  clear(): void {
    this.items.set([]);
  }
}
