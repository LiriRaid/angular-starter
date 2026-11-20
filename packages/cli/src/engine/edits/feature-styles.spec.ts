import { describe, expect, it } from 'vitest';
import { addComponentStyles, addDesignStyles, addFeatureStyles } from './styles.js';

const NG_NEW = `/* You can add global styles to this file, and also import other style files */
@import 'tailwindcss';
`;

const FEATURES = ['sidebar-styles', 'breadcrumb-styles', 'user-menu-styles'];

describe('addFeatureStyles', () => {
  it('imports the stylesheets of features from styles/features, in the order given', () => {
    const result = addFeatureStyles(addDesignStyles(NG_NEW), FEATURES);
    const lines = result.split('\n');
    const at = (name: string): number => lines.indexOf(`@import './styles/features/${name}.css';`);
    expect(at('sidebar-styles')).toBeGreaterThan(-1);
    expect(at('sidebar-styles')).toBeLessThan(at('breadcrumb-styles'));
    expect(at('breadcrumb-styles')).toBeLessThan(at('user-menu-styles'));
  });

  it('puts them after the component styles and before the shared animations', () => {
    const base = addComponentStyles(addDesignStyles(NG_NEW), ['button-styles']);
    const result = addFeatureStyles(base, FEATURES);
    expect(result.indexOf('button-styles.css')).toBeLessThan(result.indexOf('sidebar-styles.css'));
    expect(result.indexOf('user-menu-styles.css')).toBeLessThan(result.indexOf('animations.css'));
  });

  it('keeps the feature styles after the components added later', () => {
    const withFeatures = addFeatureStyles(addDesignStyles(NG_NEW), FEATURES);
    const result = addComponentStyles(withFeatures, ['button-styles']);
    expect(result.indexOf('button-styles.css')).toBeLessThan(result.indexOf('sidebar-styles.css'));
  });

  it('is idempotent', () => {
    const once = addFeatureStyles(addDesignStyles(NG_NEW), FEATURES);
    expect(addFeatureStyles(once, FEATURES)).toBe(once);
  });

  it('keeps the CRLF line endings of a Windows stylesheet', () => {
    const crlf = addDesignStyles(NG_NEW.split('\n').join('\r\n'));
    const result = addFeatureStyles(crlf, FEATURES);
    expect(result.replaceAll('\r\n', '')).not.toContain('\n');
  });

  it('asks for the design base first', () => {
    expect(() => addFeatureStyles(NG_NEW, FEATURES)).toThrow(/design/);
  });
});
