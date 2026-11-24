import { ChangeDetectionStrategy, Component, ViewEncapsulation, input, linkedSignal, output } from '@angular/core';

@Component({
  selector: 'sa-toggle',
  standalone: true,
  templateUrl: './sa-toggle.html',
  styleUrl: './sa-toggle.css',
  changeDetection: ChangeDetectionStrategy.OnPush,
  encapsulation: ViewEncapsulation.None,
})
export class SaToggle {
  readonly checked = input<boolean>(false);
  readonly disabled = input<boolean>(false);
  readonly ariaLabel = input<string | undefined>(undefined);
  readonly changed = output<boolean>();

  protected readonly localChecked = linkedSignal(() => this.checked());

  onToggle(): void {
    const next = !this.localChecked();
    this.localChecked.set(next);
    this.changed.emit(next);
  }
}
