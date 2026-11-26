import { describe, expect, it } from 'vitest';
import { getSelectPanelLayout } from './sa-select.config';

const rect = (top: number, left: number, width = 240, height = 40) => ({ top, left, bottom: top + height, right: left + width, width, height }) as DOMRect;

describe('getSelectPanelLayout', () => {
  it('sin bounds mide contra la ventana: abajo si cabe, con el ancho del campo', () => {
    expect(getSelectPanelLayout(rect(100, 200), 260, 1000, 800)).toEqual({ top: 142, left: 200, width: 240, placement: 'bottom' });
  });

  it('sin bounds abre arriba cuando abajo no cabe en la ventana', () => {
    expect(getSelectPanelLayout(rect(600, 200), 260, 1000, 800)).toMatchObject({ placement: 'top', top: 338 });
  });

  it('con bounds mide contra el área visible del campo: si el contenedor no deja lugar abajo, abre arriba aunque la ventana sí tenga', () => {
    const bounds = { top: 0, left: 0, right: 1000, bottom: 400 };
    expect(getSelectPanelLayout(rect(300, 200), 260, 1000, 800, 2, 8, bounds)).toMatchObject({ placement: 'top' });
  });

  it('con bounds y lugar en ambos lados prefiere abajo', () => {
    const bounds = { top: 0, left: 0, right: 1000, bottom: 800 };
    expect(getSelectPanelLayout(rect(100, 200), 260, 1000, 800, 2, 8, bounds).placement).toBe('bottom');
  });
});
