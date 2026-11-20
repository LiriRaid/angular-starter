import { AsFileSizePipe } from './file-size.pipe';

describe('AsFileSizePipe', () => {
  const pipe = new AsFileSizePipe();

  it('formats a size in bytes', () => {
    expect(pipe.transform(1536)).toBe('1.5 KB');
  });

  it('returns an empty string when there is no size', () => {
    expect(pipe.transform(null)).toBe('');
    expect(pipe.transform(0)).toBe('');
  });
});
