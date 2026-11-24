import { asRef, inputsOf, snippet } from './ui-system.code';

describe('ui-system code', () => {
  it('writes text values as attributes and numbers and booleans as bindings', () => {
    expect(snippet('sa-button', { label: 'Guardar', size: 'xsmall' })).toBe('<sa-button label="Guardar" size="xsmall" />');
    expect(snippet('sa-avatar', { label: 'AB', size: 40 })).toBe('<sa-avatar label="AB" [size]="40" />');
    expect(snippet('sa-toggle', { checked: true, disabled: false })).toBe('<sa-toggle checked [disabled]="false" />');
  });

  it('writes a reference as a binding to the name it carries', () => {
    expect(snippet('sa-select', { label: 'Plan', options: asRef('plans', [{ label: 'Pro', value: 'pro' }]) })).toBe('<sa-select label="Plan" [options]="plans" />');
  });

  it('puts the content between the tags', () => {
    expect(snippet('sa-modal', { title: 'Título' }, 'Contenido')).toBe('<sa-modal title="Título">Contenido</sa-modal>');
  });

  it('indents a content of several lines between the tags', () => {
    expect(snippet('sa-drawer', { position: 'right' }, '<h3 drawer-header>Título</h3>\nContenido')).toBe('<sa-drawer position="right">\n  <h3 drawer-header>Título</h3>\n  Contenido\n</sa-drawer>');
  });

  it('breaks a long tag into one attribute per line', () => {
    const code = snippet('sa-input', { label: 'Un campo con una etiqueta bastante larga', placeholder: 'Y un texto de ayuda igual de largo', type: 'number' });
    expect(code.split('\n')).toEqual(['<sa-input', '  label="Un campo con una etiqueta bastante larga"', '  placeholder="Y un texto de ayuda igual de largo"', '  type="number"', '/>']);
  });

  it('turns the references into the plain values the component receives', () => {
    const plans = [{ label: 'Pro', value: 'pro' }];
    expect(inputsOf({ label: 'Plan', options: asRef('plans', plans), size: 3 })).toEqual({ label: 'Plan', options: plans, size: 3 });
  });
});
