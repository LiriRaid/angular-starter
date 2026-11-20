import { NgTemplateOutlet } from '@angular/common';
import {
  ChangeDetectionStrategy,
  Component,
  Directive,
  TemplateRef,
  computed,
  contentChildren,
  inject,
  input,
  model,
  output,
} from '@angular/core';
import { AsIcon } from '../as-icon/as-icon';

export interface AsTableColumn {
  /** The property of each row to show, and the id of the column. */
  key: string;
  label: string;
  align?: 'start' | 'center' | 'end';
  /** Any CSS width (`8rem`, `20%`). */
  width?: string;
  sortable?: boolean;
}

export interface AsTableSort {
  key: string;
  direction: 'asc' | 'desc';
}

export interface AsTablePage {
  /** The page, starting at 1. */
  page: number;
  pageSize: number;
}

/** `<ng-template asCell="status" let-row>...</ng-template>` draws the cells of that column. */
@Directive({ selector: 'ng-template[asCell]' })
export class AsTableCell {
  readonly column = input.required<string>({ alias: 'asCell' });
  readonly template = inject<TemplateRef<{ $implicit: Record<string, unknown> }>>(TemplateRef);
}

/**
 * A data table with sortable columns, custom cells, an empty state, loading rows and pagination.
 * It does not sort or page your data: it tells you what the user asked for and you answer with the
 * rows to show (from a server, or sorted and sliced in the page).
 *
 * ```html
 * <as-table [columns]="columns" [rows]="customers()" [total]="total()" [(sort)]="sort" [(page)]="page">
 *   <ng-template asCell="status" let-row><span>{{ row.status }}</span></ng-template>
 * </as-table>
 * ```
 */
@Component({
  selector: 'as-table',
  imports: [AsIcon, NgTemplateOutlet],
  templateUrl: './as-table.html',
  styleUrl: './as-table.css',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class AsTable {
  readonly columns = input<readonly AsTableColumn[]>([]);
  readonly rows = input<readonly Record<string, unknown>[]>([]);
  /** The property that identifies a row; it keeps rows stable while they change. */
  readonly rowKey = input<string>('id');
  readonly loading = input(false);
  readonly emptyText = input<string>('Nothing to show');
  /** The number of rows there are in total, for the pagination. Without it there is no pagination. */
  readonly total = input<number | null>(null);
  readonly caption = input<string>('');

  /** The sorted column. Two-way: `[(sort)]="sort"`. */
  readonly sort = model<AsTableSort | null>(null);
  /** The page shown. Two-way: `[(page)]="page"`. */
  readonly page = model<AsTablePage>({ page: 1, pageSize: 10 });
  readonly rowClick = output<Record<string, unknown>>();

  private readonly cells = contentChildren(AsTableCell);

  protected readonly pageCount = computed(() => {
    const total = this.total();
    return total === null ? 1 : Math.max(1, Math.ceil(total / this.page().pageSize));
  });
  protected readonly range = computed(() => {
    const { page, pageSize } = this.page();
    const total = this.total() ?? this.rows().length;
    return total === 0 ? '0' : `${(page - 1) * pageSize + 1}-${Math.min(page * pageSize, total)} of ${total}`;
  });
  protected readonly skeletons = [0, 1, 2, 3, 4];

  protected cellFor(key: string): TemplateRef<{ $implicit: Record<string, unknown> }> | null {
    return this.cells().find((cell) => cell.column() === key)?.template ?? null;
  }

  protected valueOf(row: Record<string, unknown>, key: string): string {
    const value = row[key];
    return value === null || value === undefined ? '' : String(value);
  }

  protected identify(row: Record<string, unknown>, index: number): unknown {
    return row[this.rowKey()] ?? index;
  }

  protected ariaSort(column: AsTableColumn): 'ascending' | 'descending' | 'none' | null {
    if (!column.sortable) return null;
    const sort = this.sort();
    if (sort?.key !== column.key) return 'none';
    return sort.direction === 'asc' ? 'ascending' : 'descending';
  }

  /** Ascending, then descending, then back to the order the data comes in. */
  protected toggleSort(column: AsTableColumn): void {
    if (!column.sortable) return;
    const sort = this.sort();
    if (sort?.key !== column.key) this.sort.set({ key: column.key, direction: 'asc' });
    else if (sort.direction === 'asc') this.sort.set({ key: column.key, direction: 'desc' });
    else this.sort.set(null);
  }

  protected goTo(page: number): void {
    const target = Math.min(Math.max(1, page), this.pageCount());
    if (target !== this.page().page) this.page.set({ ...this.page(), page: target });
  }
}
