import { DEFAULT_LAYOUT_MODE, ENABLED_LAYOUT_MODES, LAYOUT_MODES, layoutTraits } from './layout-modes';

describe('layout modes', () => {
  it('lists the six modes of the design page', () => {
    expect(LAYOUT_MODES.map((mode) => mode.id)).toEqual(['wide-joined', 'compact-joined', 'floating-wide', 'floating-compact', 'transparent-joined', 'transparent-floating']);
  });

  it('describes every mode with the three traits of the demo', () => {
    const traitsOf = (id: string) => LAYOUT_MODES.find((mode) => mode.id === id);
    expect(traitsOf('wide-joined')).toMatchObject({ compact: false, floating: false, transparent: false });
    expect(traitsOf('compact-joined')).toMatchObject({ compact: true, floating: false, transparent: false });
    expect(traitsOf('floating-wide')).toMatchObject({ compact: false, floating: true, transparent: false });
    expect(traitsOf('floating-compact')).toMatchObject({ compact: true, floating: true, transparent: false });
    expect(traitsOf('transparent-joined')).toMatchObject({ compact: false, floating: false, transparent: true });
    expect(traitsOf('transparent-floating')).toMatchObject({ compact: false, floating: true, transparent: true });
  });

  it('gives the traits of a mode as the names the stylesheets read', () => {
    expect(layoutTraits('floating-wide')).toEqual({ compact: false, floating: true, transparent: false });
    expect(layoutTraits('floating-compact')).toEqual({ compact: true, floating: true, transparent: false });
  });

  it('has a default mode that is built and enabled', () => {
    expect(DEFAULT_LAYOUT_MODE).toBe('floating-wide');
    expect(ENABLED_LAYOUT_MODES).toContain(DEFAULT_LAYOUT_MODE);
    expect(LAYOUT_MODES.find((mode) => mode.id === DEFAULT_LAYOUT_MODE)?.built).toBe(true);
  });

  it('enables only built modes of the catalog, without repeating any', () => {
    for (const id of ENABLED_LAYOUT_MODES) {
      expect(LAYOUT_MODES.find((mode) => mode.id === id)?.built, id).toBe(true);
    }
    expect(new Set(ENABLED_LAYOUT_MODES).size).toBe(ENABLED_LAYOUT_MODES.length);
  });
});
