import { formatFileSize } from './format-file-size';

describe('formatFileSize', () => {
  it('devuelve string vacío para null/undefined/0/negativos', () => {
    expect(formatFileSize(null)).toBe('');
    expect(formatFileSize(undefined)).toBe('');
    expect(formatFileSize(0)).toBe('');
    expect(formatFileSize(-5)).toBe('');
  });

  it('formatea bytes sin decimales', () => {
    expect(formatFileSize(512)).toBe('512 B');
  });

  it('formatea en el límite exacto de 1024 como KB', () => {
    expect(formatFileSize(1024)).toBe('1.0 KB');
  });

  it('formatea justo antes del límite como B', () => {
    expect(formatFileSize(1023)).toBe('1023 B');
  });

  it('formatea MB con un decimal', () => {
    expect(formatFileSize(3 * 1024 * 1024)).toBe('3.0 MB');
  });

  it('formatea GB con un decimal', () => {
    expect(formatFileSize(2 * 1024 * 1024 * 1024)).toBe('2.0 GB');
  });

  it('no pasa de GB (queda ahí como unidad máxima)', () => {
    expect(formatFileSize(5 * 1024 * 1024 * 1024 * 1024)).toBe('5120.0 GB');
  });
});
