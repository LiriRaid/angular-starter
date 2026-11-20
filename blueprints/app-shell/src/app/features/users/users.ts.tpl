import { ChangeDetectionStrategy, Component } from '@angular/core';
import { AsAvatar } from '@shared/components';

interface SampleUser {
  readonly name: string;
  readonly email: string;
  readonly role: string;
  readonly active: boolean;
}

/** Página de ejemplo con datos de muestra: reemplázala por la gestión real de usuarios. */
@Component({
  selector: '__PREFIX__-users',
  imports: [AsAvatar],
  templateUrl: './users.html',
  styleUrl: './users.css',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class Users {
  readonly users: readonly SampleUser[] = [
    { name: 'Maria Lopez', email: 'maria.lopez@example.com', role: 'Administrator', active: true },
    { name: 'John Smith', email: 'john.smith@example.com', role: 'Editor', active: true },
    { name: 'Ana Torres', email: 'ana.torres@example.com', role: 'Viewer', active: false },
    { name: 'Luis Ramirez', email: 'luis.ramirez@example.com', role: 'Editor', active: true },
  ];

  initials(name: string): string {
    return name
      .split(/\s+/)
      .map((part) => part.charAt(0))
      .join('')
      .slice(0, 2)
      .toUpperCase();
  }
}
