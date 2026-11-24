export type AsTableAlign = 'left' | 'center' | 'right';

export interface AsTableColumn {
  field: string;
  header: string;
  width?: string;
  align?: AsTableAlign;
  headerClass?: string;
  cellClass?: string;
}

export interface AsTablePageEvent {
  page: number;
  perPage: number;
}

/** Construye la lista de botones de paginación con elipsis: siempre muestra las 2 primeras
 *  y 2 últimas páginas, más un rango de 1 alrededor de la página actual — colapsando el resto
 *  en un `'ellipsis'`. Con 7 páginas o menos no hace falta elipsis, se listan todas. */
export function buildPageItems(current: number, total: number): (number | 'ellipsis')[] {
  if (total <= 7) return Array.from({ length: total }, (_, i) => i + 1);

  const pages = new Set<number>([1, 2, total - 1, total]);
  for (let page = current - 1; page <= current + 1; page++) {
    if (page >= 1 && page <= total) pages.add(page);
  }

  const sorted = [...pages].sort((a, b) => a - b);
  const items: (number | 'ellipsis')[] = [];
  let previous = 0;
  for (const page of sorted) {
    if (previous) {
      if (page - previous === 2) items.push(previous + 1);
      else if (page - previous > 2) items.push('ellipsis');
    }
    items.push(page);
    previous = page;
  }
  return items;
}

export function alignClass(align: AsTableAlign | undefined): string {
  if (align === 'center') return 'text-center';
  if (align === 'right') return 'text-right';
  return 'text-left';
}

export function headerClass(column: AsTableColumn): string {
  return ['whitespace-nowrap px-4 py-3 text-caption-1-bold uppercase tracking-wider text-(--app-text-subtle)', alignClass(column.align), column.headerClass ?? ''].join(' ');
}

export function cellClass(column: AsTableColumn): string {
  return ['px-4 py-3 text-caption-1-regular text-(--app-text-color)', alignClass(column.align), column.cellClass ?? ''].join(' ');
}
