import { Pipe, type PipeTransform } from '@angular/core';
import { deriveInitials } from '../utils/derive-initials';

/** `{{ user.name | asInitials }}` becomes "AL" for "Ada Lovelace". */
@Pipe({ name: 'asInitials' })
export class AsInitialsPipe implements PipeTransform {
  transform(name: string | null | undefined): string {
    return name ? deriveInitials(name) : '';
  }
}
