import { AsRelativeTimePipe } from './relative-time.pipe';

describe('AsRelativeTimePipe', () => {
  const pipe = new AsRelativeTimePipe();

  it('says how long ago a moment was', () => {
    expect(pipe.transform(Date.now() - 3 * 3600 * 1000, 'en')).toBe('3 hours ago');
  });

  it('returns an empty string when there is no value', () => {
    expect(pipe.transform(null)).toBe('');
    expect(pipe.transform(undefined)).toBe('');
  });
});
