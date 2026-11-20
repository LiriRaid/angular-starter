import { AsInitialsPipe } from './initials.pipe';

describe('AsInitialsPipe', () => {
  const pipe = new AsInitialsPipe();

  it('turns a name into its initials', () => {
    expect(pipe.transform('Ada Lovelace')).toBe('AL');
  });

  it('returns an empty string when there is no name', () => {
    expect(pipe.transform('')).toBe('');
    expect(pipe.transform(null)).toBe('');
  });
});
