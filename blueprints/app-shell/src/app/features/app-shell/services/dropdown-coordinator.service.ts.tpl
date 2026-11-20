import { Injectable, computed, signal } from '@angular/core';

@Injectable({
  providedIn: 'root',
})
export class DropdownCoordinatorService {
  private readonly activeDropdownId = signal<string | null>(null);

  readonly activeId = computed(() => this.activeDropdownId());

  isOpen(id: string): boolean {
    return this.activeDropdownId() === id;
  }

  open(id: string): void {
    this.activeDropdownId.set(id);
  }

  close(id: string): void {
    if (this.activeDropdownId() === id) {
      this.activeDropdownId.set(null);
    }
  }

  toggle(id: string): void {
    this.activeDropdownId.update((current) => (current === id ? null : id));
  }

  closeAll(): void {
    this.activeDropdownId.set(null);
  }
}
