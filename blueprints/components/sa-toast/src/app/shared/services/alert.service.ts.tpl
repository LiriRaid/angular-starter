import { Injectable, signal } from '@angular/core';

import { EAsToastType, type IAsToastAction, type ToastItem, type ToastPosition } from '@shared/components/sa-toast/sa-toast.types';

@Injectable({
  providedIn: 'root',
})
export class AlertService {
  readonly toastPosition = signal<ToastPosition>('top-center');
  readonly toastActive = signal(false);
  readonly messages = signal<ToastItem[]>([]);
  readonly leavingIds = signal<Set<string>>(new Set());

  private toastReady = false;
  private readonly pending: ToastItem[] = [];
  private readonly timers = new Map<string, ReturnType<typeof setTimeout>>();
  private destroyTimer: ReturnType<typeof setTimeout> | null = null;

  markToastReady(): void {
    this.toastReady = true;
    for (const item of this.pending) {
      this.commit(item);
    }
    this.pending.length = 0;
  }

  removeMessage(id: string): void {
    const t = this.timers.get(id);
    if (t) {
      clearTimeout(t);
      this.timers.delete(id);
    }

    // Mark as leaving so the component plays the exit transition (transform + opacity).
    // After the longest transition (transform 0.42s) we commit the removal.
    this.leavingIds.update((s) => new Set([...s, id]));

    setTimeout(() => {
      this.leavingIds.update((s) => {
        const n = new Set(s);
        n.delete(id);
        return n;
      });
      this.messages.update((msgs) => msgs.filter((m) => m.id !== id));
      if (this.messages().length === 0) this.scheduleDestroy();
    }, 450);
  }

  clear(): void {
    this.timers.forEach((t) => clearTimeout(t));
    this.timers.clear();
    this.messages.set([]);
    this.scheduleDestroy();
  }

  showSuccess(title: string, message: string, action?: IAsToastAction, duration?: number, position: ToastPosition = 'top-center'): void {
    this.show(title, message, EAsToastType.Success, action, duration, undefined, false, position);
  }

  showInfo(title: string, message: string, action?: IAsToastAction, duration?: number, position: ToastPosition = 'top-center'): void {
    this.show(title, message, EAsToastType.Info, action, duration, undefined, false, position);
  }

  showWarning(title: string, message: string, action?: IAsToastAction, duration?: number, persistent = false, position: ToastPosition = 'top-center'): void {
    this.show(title, message, EAsToastType.Warning, action, duration, undefined, persistent, position);
  }

  showError(title: string, message: string, action?: IAsToastAction, duration?: number, position: ToastPosition = 'top-center'): void {
    this.show(title, message, EAsToastType.Error, action, duration, undefined, false, position);
  }

  showSecondary(title: string, message: string, action?: IAsToastAction, duration?: number, position: ToastPosition = 'top-center'): void {
    this.show(title, message, EAsToastType.Secondary, action, duration, undefined, false, position);
  }

  showContrast(title: string, message: string, action?: IAsToastAction, duration?: number, position: ToastPosition = 'top-center'): void {
    this.show(title, message, EAsToastType.Contrast, action, duration, undefined, false, position);
  }

  showLoading(title: string, message: string, action?: IAsToastAction, duration?: number, position: ToastPosition = 'top-center'): void {
    this.show(title, message, EAsToastType.Loading, action, duration, undefined, true, position);
  }

  showBasic(title: string, message: string, action?: IAsToastAction, duration?: number, context?: 'view' | 'edit' | 'create', position: ToastPosition = 'top-center'): void {
    this.show(title, message, EAsToastType.Info, action, duration, context, false, position);
  }

  private show(title: string, message: string, type: EAsToastType, action?: IAsToastAction, duration?: number, context?: 'view' | 'edit' | 'create', persistent = false, position: ToastPosition = 'top-center'): void {
    this.toastPosition.set(position);

    const item: ToastItem = {
      id: crypto.randomUUID(),
      type,
      title,
      message,
      action,
      duration: duration ?? this.defaultDuration(type),
      persistent,
      position,
      context,
    };

    if (this.destroyTimer !== null) {
      clearTimeout(this.destroyTimer);
      this.destroyTimer = null;
    }

    this.toastActive.set(true);

    if (this.toastReady) {
      this.commit(item);
    } else {
      this.pending.push(item);
    }
  }

  private commit(item: ToastItem): void {
    this.messages.update((msgs) => [item, ...msgs]);

    if (!item.persistent) {
      const t = setTimeout(() => this.removeMessage(item.id), item.duration);
      this.timers.set(item.id, t);
    }
  }

  private scheduleDestroy(): void {
    this.destroyTimer = setTimeout(() => {
      this.toastActive.set(false);
      this.destroyTimer = null;
    }, 300);
  }

  private defaultDuration(type: EAsToastType): number {
    switch (type) {
      case EAsToastType.Error:
        return 6000;
      case EAsToastType.Warning:
        return 5000;
      default:
        return 4000;
    }
  }
}
