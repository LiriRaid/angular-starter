import { asRef, inputsOf, snippet } from './ui-system.code';

describe('ui-system code', () => {
  it('writes text values as attributes and numbers and booleans as bindings', () => {
    expect(snippet('as-button', { label: 'Guardar', size: 'xsmall' })).toBe('<as-button label="Guardar" size="xsmall" />');
    expect(snippet('as-avatar', { label: 'AB', size: 40 })).toBe('<as-avatar label="AB" [size]="40" />');
    expect(snippet('as-toggle', { checked: true, disabled: false })).toBe('<as-toggle checked [disabled]="false" />');
  });

  it('writes a reference as a binding to the name it carries', () => {
    expect(snippet('as-select', { label: 'Plan', options: asRef('plans', [{ label: 'Pro', value: 'pro' }]) })).toBe('<as-select label="Plan" [options]="plans" />');
  });

  it('puts the content between the tags', () => {
    expect(snippet('as-modal', { title: 'Título' }, 'Contenido')).toBe('<as-modal title="Título">Contenido</as-modal>');
  });

  it('indents a content of several lines between the tags', () => {
    expect(snippet('as-drawer', { position: 'right' }, '<h3 drawer-header>Título</h3>\nContenido')).toBe('<as-drawer position="right">\n  <h3 drawer-header>Título</h3>\n  Contenido\n</as-drawer>');
  });

  it('breaks a long tag into one attribute per line', () => {
    const code = snippet('as-input', { label: 'Un campo con una etiqueta bastante larga', placeholder: 'Y un texto de ayuda igual de largo', type: 'number' });
    expect(code.split('\n')).toEqual(['<as-input', '  label="Un campo con una etiqueta bastante larga"', '  placeholder="Y un texto de ayuda igual de largo"', '  type="number"', '/>']);
  });

  it('turns the references into the plain values the component receives', () => {
    const plans = [{ label: 'Pro', value: 'pro' }];
    expect(inputsOf({ label: 'Plan', options: asRef('plans', plans), size: 3 })).toEqual({ label: 'Plan', options: plans, size: 3 });
  });
});
