import { NgClass, NgTemplateOutlet } from '@angular/common';
import { ChangeDetectionStrategy, Component, TemplateRef, ViewEncapsulation, computed, input, linkedSignal, model, output, signal } from '@angular/core';
import { FormsModule } from '@angular/forms';

import { SaCheckbox } from '../sa-checkbox/sa-checkbox';
import { SaIcon } from '../sa-icon/sa-icon';
import { SaSelect } from '../sa-select/sa-select';
import { SaSkeleton } from '../sa-skeleton/sa-skeleton';
import { buildPageItems, cellClass as buildCellClass, headerClass as buildHeaderClass, type SaTableAlign, type SaTableColumn, type SaTablePageEvent } from './sa-table.config';

export type { SaTableAlign, SaTableColumn, SaTablePageEvent };

@Component({
  selector: 'sa-table',
  standalone: true,
  imports: [NgClass, NgTemplateOutlet, FormsModule, SaCheckbox, SaSelect, SaSkeleton, SaIcon],
  templateUrl: './sa-table.html',
  styleUrl: './sa-table.css',
  encapsulation: ViewEncapsulation.None,
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class SaTable<T = Record<string, unknown>> {
  readonly value = input<T[]>([]);
  readonly columns = input<readonly SaTableColumn[]>([]);
  readonly dataKey = input<string | undefined>(undefined);

  readonly cellTemplates = input<Record<string, TemplateRef<unknown>>>({});

  readonly loading = input<boolean>(false);
  /** Override manual. Si no se define, la cantidad de filas skeleton se adapta al total real conocido (ver effectiveSkeletonRows). */
  readonly skeletonRows = input<number | null>(null);
  readonly skeletonCellTemplates = input<Record<string, TemplateRef<unknown>>>({});

  readonly paginator = input<boolean>(true);
  readonly rows = input<number>(10);
  readonly rowsPerPageOptions = input<number[]>([10, 25, 50]);

  /** Modo server-side: la tabla no pagina el array, usa totalRecords del API */
  readonly lazy = input<boolean>(false);
  readonly lazyTotalRecords = input<number | null>(null);
  readonly pageChange = output<SaTablePageEvent>();

  readonly itemLabel = input<string>('registros');
  readonly tableMinWidth = input<string>('60rem');

  readonly clickableRows = input<boolean>(false);
  readonly rowClass = input<((row: T) => string) | undefined>(undefined);
  readonly emptyMessage = input<string>('No se encontraron resultados.');

  readonly expandable = input<boolean>(false);
  /**
   * 'column' (default) agrega la columna final con chevron para expandir cada fila.
   * 'external' no agrega esa columna: el consumidor dispara el expand desde su propio
   * template (ej. un botón "N campos" en la celda de acciones) llamando a `toggleExpand(row)`.
   */
  readonly expandTrigger = input<'column' | 'external'>('column');
  readonly showExpandColumn = computed(() => this.expandable() && this.expandTrigger() === 'column');
  readonly rowExpansionTemplate = input<TemplateRef<unknown> | null>(null);
  /** Pie de la tabla (ej. una fila "Agregar"): se pinta en un `<tfoot>` con una celda que abarca todas las columnas y recibe `colspan` en su contexto. */
  readonly footerTemplate = input<TemplateRef<{ colspan: number }> | null>(null);
  /** Columnas reales de la tabla: las de datos más la de selección y la de expandir cuando existen. */
  readonly totalColspan = computed(() => this.columns().length + (this.selectable() ? 1 : 0) + (this.showExpandColumn() ? 1 : 0));

  readonly rowClick = output<T>();

  readonly selectable = input<boolean>(false);
  readonly selection = model<unknown[]>([]);

  isRowSelected(row: T): boolean {
    const key = this.rowKey(row);
    return this.selection().some((selected) => this.rowKey(selected as T) === key);
  }

  toggleRowSelection(row: T): void {
    const key = this.rowKey(row);
    const current = this.selection();
    const isSelected = current.some((selected) => this.rowKey(selected as T) === key);

    this.selection.set(isSelected ? current.filter((selected) => this.rowKey(selected as T) !== key) : [...current, row]);
  }

  readonly allPageSelected = computed(() => {
    const rows = this.pagedValue();
    return rows.length > 0 && rows.every((row) => this.isRowSelected(row));
  });

  readonly somePageSelected = computed(() => this.pagedValue().some((row) => this.isRowSelected(row)) && !this.allPageSelected());

  toggleSelectAll(): void {
    const rows = this.pagedValue();
    const current = this.selection();

    if (this.allPageSelected()) {
      const pageKeys = new Set(rows.map((row) => this.rowKey(row)));
      this.selection.set(current.filter((selected) => !pageKeys.has(this.rowKey(selected as T))));
      return;
    }

    const currentKeys = new Set(current.map((selected) => this.rowKey(selected as T)));
    this.selection.set([...current, ...rows.filter((row) => !currentKeys.has(this.rowKey(row)))]);
  }

  private readonly expandedKeys = signal<Set<unknown>>(new Set());

  private rowKey(row: T): unknown {
    const key = this.dataKey();
    return key ? this.resolveField(row, key) : row;
  }

  isExpanded(row: T): boolean {
    return this.expandedKeys().has(this.rowKey(row));
  }

  toggleExpand(row: T): void {
    const key = this.rowKey(row);
    this.expandedKeys.update((current) => {
      const next = new Set(current);
      if (next.has(key)) next.delete(key);
      else next.add(key);
      return next;
    });
  }

  readonly safeDataKey = computed(() => (this.loading() ? '__sk' : (this.dataKey() ?? undefined)));

  readonly pageReset = input<number>(0);

  readonly pageSize = linkedSignal(() => this.rows());
  private readonly currentPage = linkedSignal<number>(() => {
    this.pageReset();
    return 0;
  });

  readonly totalRecords = computed(() => (this.lazy() && this.lazyTotalRecords() !== null ? this.lazyTotalRecords()! : this.value().length));
  readonly totalPages = computed(() => Math.max(1, Math.ceil(this.totalRecords() / this.pageSize())));
  readonly safePage = computed(() => Math.min(this.currentPage(), this.totalPages() - 1));
  readonly first = computed(() => this.safePage() * this.pageSize());

  /** Cuántas filas skeleton mostrar mientras carga: el total real ya conocido (de una carga previa) acotado a lo que cabe en la página actual, o el tamaño de página completo si todavía no se conoce ningún total (primera carga). */
  readonly effectiveSkeletonRows = computed(() => {
    const explicit = this.skeletonRows();
    if (explicit != null) return explicit;

    const size = this.pageSize();
    const total = this.lazy() ? this.lazyTotalRecords() : this.value().length || null;
    if (total == null) return size;

    const remaining = total - this.first();
    return remaining > 0 ? Math.min(size, remaining) : size;
  });

  readonly skeletonItems = computed(() => Array.from({ length: Math.max(1, this.effectiveSkeletonRows()) }, (_, index) => ({ __sk: index })));

  readonly rangeStart = computed(() => (this.totalRecords() === 0 ? 0 : this.first() + 1));
  readonly rangeEnd = computed(() => {
    if (this.lazy()) return this.first() + this.value().length;
    return Math.min(this.first() + this.pageSize(), this.totalRecords());
  });

  private readonly pagedValue = computed<T[]>(() => {
    if (this.lazy()) return this.value();
    return this.paginator() ? this.value().slice(this.first(), this.first() + this.pageSize()) : this.value();
  });

  readonly displayValue = computed<T[]>(() => (this.loading() ? (this.skeletonItems() as unknown as T[]) : this.pagedValue()));

  readonly showPaginator = computed(() => this.paginator() && !this.loading() && this.totalRecords() > 0);

  readonly pageItems = computed<(number | 'ellipsis')[]>(() => buildPageItems(this.safePage() + 1, this.totalPages()));

  goToPage(page: number): void {
    const next = Math.min(Math.max(page - 1, 0), this.totalPages() - 1);
    this.currentPage.set(next);
    if (this.lazy()) this.pageChange.emit({ page: next + 1, perPage: this.pageSize() });
  }

  firstPage(): void {
    this.currentPage.set(0);
    if (this.lazy()) this.pageChange.emit({ page: 1, perPage: this.pageSize() });
  }
  prevPage(): void {
    const next = Math.max(this.safePage() - 1, 0);
    this.currentPage.set(next);
    if (this.lazy()) this.pageChange.emit({ page: next + 1, perPage: this.pageSize() });
  }
  nextPage(): void {
    const next = Math.min(this.safePage() + 1, this.totalPages() - 1);
    this.currentPage.set(next);
    if (this.lazy()) this.pageChange.emit({ page: next + 1, perPage: this.pageSize() });
  }
  lastPage(): void {
    const next = this.totalPages() - 1;
    this.currentPage.set(next);
    if (this.lazy()) this.pageChange.emit({ page: next + 1, perPage: this.pageSize() });
  }

  setPageSize(value: number): void {
    if (value > 0) {
      this.pageSize.set(value);
      this.currentPage.set(0);
      if (this.lazy()) this.pageChange.emit({ page: 1, perPage: value });
    }
  }

  readonly rowTrackByFn = computed(() => {
    const key = this.safeDataKey();
    if (!key) return (_index: number, row: T) => row;
    return (_index: number, row: T) => (row as Record<string, unknown>)[key];
  });

  templateFor(field: string): TemplateRef<unknown> | undefined {
    return this.cellTemplates()[field];
  }

  skeletonTemplateFor(field: string): TemplateRef<unknown> | undefined {
    return this.skeletonCellTemplates()[field];
  }

  cellContext(row: T): { $implicit: T } {
    return { $implicit: row };
  }

  resolveField(row: T, field: string): unknown {
    return (row as Record<string, unknown>)[field];
  }

  headerClass(column: SaTableColumn): string {
    return buildHeaderClass(column);
  }

  cellClass(column: SaTableColumn): string {
    return buildCellClass(column);
  }

  onRowClick(row: T, event: MouseEvent): void {
    if (this.loading()) return;
    if (!this.clickableRows()) return;
    if ((event.target as HTMLElement).closest('[data-no-row-click]')) return;
    this.rowClick.emit(row);
  }
}
