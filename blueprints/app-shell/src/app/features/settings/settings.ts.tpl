import { ChangeDetectionStrategy, Component } from '@angular/core';
import { RouterOutlet } from '@angular/router';

/** Página de ejemplo: agrupa las secciones de configuración (`general`, `notifications`). */
@Component({
  selector: '__PREFIX__-settings',
  imports: [RouterOutlet],
  templateUrl: './settings.html',
  styleUrl: './settings.css',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class Settings {}
