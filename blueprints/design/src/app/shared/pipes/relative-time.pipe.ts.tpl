import { Pipe, type PipeTransform } from '@angular/core';
import { formatRelativeTime } from '../utils/relative-time';

/** `{{ createdAt | asRelativeTime }}` becomes "3 hours ago"; pass a language tag as the argument to force one. */
@Pipe({ name: 'asRelativeTime' })
export class AsRelativeTimePipe implements PipeTransform {
  transform(value: Date | string | number | null | undefined, locale?: string): string {
    return value === null || value === undefined ? '' : formatRelativeTime(value, { locale });
  }
}
