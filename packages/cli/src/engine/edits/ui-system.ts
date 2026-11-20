import { addComponentImport } from './typescript.js';

/** Where the UI tab of the design preferences page (ADR-0010) takes the catalog of the UI System. */
export const UI_SYSTEM_MARKER = '<!-- as:ui-system -->';

/**
 * Replaces the marker of the UI tab with the catalog. A tab that already has it is left as it is; a
 * tab the developer rewrote (no marker, no catalog) stops the stage naming what is missing.
 */
export function addUiSystemToUiTabTemplate(html: string, prefix: string): string {
  const selector = `<${prefix}-ui-system />`;
  if (html.includes(selector)) return html;
  if (!html.includes(UI_SYSTEM_MARKER)) {
    throw new Error(`it has no ${UI_SYSTEM_MARKER} marker to put the catalog in.`);
  }
  return html.replace(UI_SYSTEM_MARKER, selector);
}

/** Imports the `UiSystem` component in the class of the UI tab. */
export function addUiSystemToUiTabClass(source: string): string {
  return addComponentImport(source, 'UiTab', 'UiSystem', '../ui-system/ui-system');
}
