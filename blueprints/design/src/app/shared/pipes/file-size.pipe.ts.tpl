import { Pipe, type PipeTransform } from '@angular/core';
import { formatFileSize } from '../utils/format-file-size';

/** `{{ file.size | asFileSize }}` becomes "1.5 MB". */
@Pipe({ name: 'asFileSize' })
export class AsFileSizePipe implements PipeTransform {
  transform(bytes: number | null | undefined): string {
    return formatFileSize(bytes);
  }
}
