import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest';
import { downloadFile } from './download-file';

describe('downloadFile', () => {
  let createObjectURL: ReturnType<typeof vi.fn>;
  let revokeObjectURL: ReturnType<typeof vi.fn>;
  let click: ReturnType<typeof vi.spyOn>;

  beforeEach(() => {
    vi.useFakeTimers();
    createObjectURL = vi.fn(() => 'blob:archivo');
    revokeObjectURL = vi.fn();
    Object.assign(URL, { createObjectURL, revokeObjectURL });
    click = vi.spyOn(HTMLAnchorElement.prototype, 'click').mockImplementation(() => undefined);
  });

  afterEach(() => {
    vi.useRealTimers();
    vi.restoreAllMocks();
  });

  it('descarga el contenido con el nombre y el tipo indicados', () => {
    let seen: { href: string; download: string; inDom: boolean } | null = null;
    click.mockImplementation(function (this: HTMLAnchorElement) {
      seen = { href: this.href, download: this.download, inDom: document.body.contains(this) };
    });

    downloadFile('a,b', 'text/csv;charset=utf-8', 'cierres.csv');

    const blob = createObjectURL.mock.calls[0][0] as Blob;
    expect(blob.type).toBe('text/csv;charset=utf-8');
    expect(seen).toEqual({ href: 'blob:archivo', download: 'cierres.csv', inDom: true });
  });

  it('suelta el enlace del documento y no libera la URL antes de que empiece la descarga', () => {
    downloadFile('x', 'text/plain', 'x.txt');

    expect(document.querySelector('a[download="x.txt"]')).toBeNull();
    expect(revokeObjectURL).not.toHaveBeenCalled();

    vi.runAllTimers();

    expect(revokeObjectURL).toHaveBeenCalledWith('blob:archivo');
  });
});
