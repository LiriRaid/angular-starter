import { describe, expect, it } from 'vitest';
import { alignClass, buildPageItems, cellClass, headerClass, type SaTableColumn } from './sa-table.config';

describe('buildPageItems', () => {
  it('lista todas las paginas si son 7 o menos, sin elipsis', () => {
    expect(buildPageItems(1, 7)).toEqual([1, 2, 3, 4, 5, 6, 7]);
    expect(buildPageItems(3, 5)).toEqual([1, 2, 3, 4, 5]);
  });

  it('agrega elipsis en el medio si el rango alrededor de la pagina actual no llega a solapar con el extremo opuesto', () => {
    expect(buildPageItems(2, 8)).toEqual([1, 2, 3, 'ellipsis', 7, 8]);
  });

  it('agrega elipsis en el medio cuando la pagina actual esta lejos de ambos extremos', () => {
    expect(buildPageItems(10, 20)).toEqual([1, 2, 'ellipsis', 9, 10, 11, 'ellipsis', 19, 20]);
  });

  it('rellena el hueco con el numero exacto en vez de elipsis cuando la distancia es de 2', () => {
    // pages = {1,2, 3(current-1),4(current),5(current+1), 9,10} -> el hueco entre 5 y 9 es de 4, va elipsis
    // pero el hueco entre 2 y 3 es de 1, se listan seguidos sin elipsis
    expect(buildPageItems(4, 10)).toEqual([1, 2, 3, 4, 5, 'ellipsis', 9, 10]);
  });

  it('elipsis solo al final cuando la pagina actual esta al inicio', () => {
    expect(buildPageItems(1, 20)).toEqual([1, 2, 'ellipsis', 19, 20]);
  });

  it('elipsis solo al inicio cuando la pagina actual esta al final', () => {
    expect(buildPageItems(20, 20)).toEqual([1, 2, 'ellipsis', 19, 20]);
  });
});

describe('alignClass', () => {
  it('devuelve text-left por defecto', () => {
    expect(alignClass(undefined)).toBe('text-left');
  });

  it('devuelve text-center para align center', () => {
    expect(alignClass('center')).toBe('text-center');
  });

  it('devuelve text-right para align right', () => {
    expect(alignClass('right')).toBe('text-right');
  });
});

describe('headerClass / cellClass', () => {
  const column: SaTableColumn = { field: 'name', header: 'Nombre', align: 'center', headerClass: 'extra-header', cellClass: 'extra-cell' };

  it('headerClass combina las clases base, de alineacion y la custom de la columna', () => {
    expect(headerClass(column)).toBe('whitespace-nowrap px-4 py-3 text-caption-1-bold uppercase tracking-wider text-(--app-text-subtle) text-center extra-header');
  });

  it('cellClass combina las clases base, de alineacion y la custom de la columna', () => {
    expect(cellClass(column)).toBe('px-4 py-3 text-caption-1-regular text-(--app-text-color) text-center extra-cell');
  });

  it('headerClass/cellClass no rompen si la columna no define headerClass/cellClass', () => {
    const minimal: SaTableColumn = { field: 'id', header: 'ID' };
    expect(headerClass(minimal)).toBe('whitespace-nowrap px-4 py-3 text-caption-1-bold uppercase tracking-wider text-(--app-text-subtle) text-left ');
    expect(cellClass(minimal)).toBe('px-4 py-3 text-caption-1-regular text-(--app-text-color) text-left ');
  });
});
