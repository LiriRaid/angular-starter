import { describe, expect, it } from 'vitest';
import {
  UI_SYSTEM_MARKER,
  addUiSystemToUiTabClass,
  addUiSystemToUiTabTemplate,
} from './ui-system.js';

const HTML = `<div>\n  <section></section>\n\n  ${UI_SYSTEM_MARKER}\n</div>\n`;
const CLASS = `import { Component } from '@angular/core';

@Component({ selector: 'app-ui-tab', imports: [], template: '' })
export class UiTab {}
`;

describe('UI System edits of the UI tab', () => {
  it('replaces the marker with the catalog', () => {
    const edited = addUiSystemToUiTabTemplate(HTML, 'shop');
    expect(edited).toContain('<shop-ui-system />');
    expect(edited).not.toContain(UI_SYSTEM_MARKER);
    expect(edited).toContain('<section></section>');
  });

  it('is idempotent', () => {
    const once = addUiSystemToUiTabTemplate(HTML, 'app');
    expect(addUiSystemToUiTabTemplate(once, 'app')).toBe(once);
  });

  it('names the marker it expects', () => {
    expect(() => addUiSystemToUiTabTemplate('<p>mine</p>', 'app')).toThrow(/as:ui-system/);
  });

  it('imports the catalog in the class, once', () => {
    const edited = addUiSystemToUiTabClass(CLASS);
    expect(edited).toContain("import { UiSystem } from '../ui-system/ui-system';");
    expect(edited).toContain('imports: [UiSystem]');
    expect(addUiSystemToUiTabClass(edited)).toBe(edited);
  });

  it('names the class it expects', () => {
    expect(() => addUiSystemToUiTabClass('export class Other {}')).toThrow(/UiTab/);
  });
});
