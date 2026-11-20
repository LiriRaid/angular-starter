import { vi } from 'vitest';
import { downloadFile } from './download-file';

describe('downloadFile', () => {
  beforeEach(() => {
    vi.useFakeTimers();
    URL.createObjectURL = vi.fn(() => 'blob:test');
    URL.revokeObjectURL = vi.fn();
  });

  afterEach(() => vi.useRealTimers());

  it('clicks a link to the file with the name asked for', () => {
    const click = vi.spyOn(HTMLAnchorElement.prototype, 'click').mockImplementation(() => undefined);
    downloadFile('a,b', 'text/csv', 'data.csv');

    expect(URL.createObjectURL).toHaveBeenCalledOnce();
    expect(click).toHaveBeenCalledOnce();
    expect(document.querySelector('a[download]')).toBeNull();
    click.mockRestore();
  });

  it('releases the URL after a moment, not at once', () => {
    vi.spyOn(HTMLAnchorElement.prototype, 'click').mockImplementation(() => undefined);
    downloadFile('x', 'text/plain', 'x.txt');

    expect(URL.revokeObjectURL).not.toHaveBeenCalled();
    vi.advanceTimersByTime(1000);
    expect(URL.revokeObjectURL).toHaveBeenCalledWith('blob:test');
  });
});
