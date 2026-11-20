import { Component, signal } from '@angular/core';
import { TestBed } from '@angular/core/testing';
import { provideAsIcons } from '@core/icons/icons.provider';
import { AsTable, AsTableCell, type AsTableColumn, type AsTablePage, type AsTableSort } from './as-table';

const COLUMNS: AsTableColumn[] = [
  { key: 'name', label: 'Name', sortable: true },
  { key: 'status', label: 'Status', align: 'center' },
];

@Component({
  imports: [AsTable, AsTableCell],
  template: `
    <as-table
      [columns]="columns"
      [rows]="rows()"
      [total]="total"
      [loading]="loading()"
      emptyText="No customers"
      [(sort)]="sort"
      [(page)]="page"
      (rowClick)="clicked = $event"
    >
      <ng-template asCell="status" let-row><b class="status">{{ row['status'] }}</b></ng-template>
    </as-table>
  `,
})
class Host {
  columns = COLUMNS;
  rows = signal<Record<string, unknown>[]>([
    { id: 1, name: 'Ada', status: 'active' },
    { id: 2, name: 'Grace', status: 'paused' },
  ]);
  loading = signal(false);
  total = 25;
  sort = signal<AsTableSort | null>(null);
  page = signal<AsTablePage>({ page: 1, pageSize: 10 });
  clicked: Record<string, unknown> | null = null;
}

describe('AsTable', () => {
  function render() {
    TestBed.configureTestingModule({ imports: [Host], providers: [provideAsIcons()] });
    const fixture = TestBed.createComponent(Host);
    fixture.detectChanges();
    const element = fixture.nativeElement as HTMLElement;
    const text = (selector: string) => Array.from(element.querySelectorAll(selector)).map((node) => node.textContent?.trim());
    return { fixture, host: fixture.componentInstance, element, text };
  }

  it('shows the headers and one row per item', () => {
    const { text } = render();
    expect(text('th')).toEqual(['Name', 'Status']);
    expect(text('tbody tr td:first-child')).toEqual(['Ada', 'Grace']);
  });

  it('draws the cells of a column with the template given', () => {
    const { text } = render();
    expect(text('.status')).toEqual(['active', 'paused']);
  });

  it('sorts ascending, then descending, then not at all', () => {
    const { fixture, host, element } = render();
    const button = element.querySelector('.as-table__sort') as HTMLButtonElement;
    button.click();
    fixture.detectChanges();
    expect(host.sort()).toEqual({ key: 'name', direction: 'asc' });
    expect(element.querySelector('th')?.getAttribute('aria-sort')).toBe('ascending');

    button.click();
    expect(host.sort()).toEqual({ key: 'name', direction: 'desc' });
    button.click();
    expect(host.sort()).toBeNull();
  });

  it('reports the row that is clicked', () => {
    const { host, element } = render();
    (element.querySelectorAll('.as-table__row--data')[1] as HTMLElement).click();
    expect(host.clicked).toEqual({ id: 2, name: 'Grace', status: 'paused' });
  });

  it('pages with the buttons and shows the range', () => {
    const { fixture, host, element } = render();
    expect(element.querySelector('.as-table__range')?.textContent).toBe('1-10 of 25');
    expect(element.querySelector('.as-table__current')?.textContent).toBe('1 / 3');
    expect((element.querySelector('[aria-label="Previous page"]') as HTMLButtonElement).disabled).toBe(true);

    (element.querySelector('[aria-label="Next page"]') as HTMLButtonElement).click();
    fixture.detectChanges();
    expect(host.page().page).toBe(2);
    expect(element.querySelector('.as-table__range')?.textContent).toBe('11-20 of 25');
  });

  it('shows the empty message when there are no rows', () => {
    const { fixture, host, element } = render();
    host.rows.set([]);
    fixture.detectChanges();
    expect(element.querySelector('.as-table__empty')?.textContent).toBe('No customers');
  });

  it('shows placeholder rows while it is loading', () => {
    const { fixture, host, element } = render();
    host.loading.set(true);
    fixture.detectChanges();
    expect(element.querySelectorAll('.as-table__skeleton').length).toBeGreaterThan(0);
    expect(element.querySelector('.as-table__row--data')).toBeNull();
  });
});
