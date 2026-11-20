<div class="as-table__scroll">
  <table class="as-table">
    @if (caption()) {
      <caption class="as-table__caption">{{ caption() }}</caption>
    }
    <thead>
      <tr>
        @for (column of columns(); track column.key) {
          <th
            scope="col"
            class="as-table__head"
            [class]="'as-table__cell--' + (column.align ?? 'start')"
            [style.width]="column.width"
            [attr.aria-sort]="ariaSort(column)"
          >
            @if (column.sortable) {
              <button type="button" class="as-table__sort" (click)="toggleSort(column)">
                {{ column.label }}
                <as-icon
                  [name]="sort()?.key === column.key ? (sort()?.direction === 'asc' ? 'arrow-up' : 'arrow-down') : 'arrow-up-down'"
                  [size]="14"
                />
              </button>
            } @else {
              {{ column.label }}
            }
          </th>
        }
      </tr>
    </thead>
    <tbody>
      @if (loading()) {
        @for (row of skeletons; track row) {
          <tr class="as-table__row">
            @for (column of columns(); track column.key) {
              <td class="as-table__cell"><span class="as-table__skeleton"></span></td>
            }
          </tr>
        }
      } @else {
        @for (row of rows(); track identify(row, $index)) {
          <tr class="as-table__row as-table__row--data" (click)="rowClick.emit(row)">
            @for (column of columns(); track column.key) {
              <td class="as-table__cell" [class]="'as-table__cell--' + (column.align ?? 'start')">
                @if (cellFor(column.key); as template) {
                  <ng-container [ngTemplateOutlet]="template" [ngTemplateOutletContext]="{ $implicit: row }" />
                } @else {
                  {{ valueOf(row, column.key) }}
                }
              </td>
            }
          </tr>
        } @empty {
          <tr>
            <td class="as-table__empty" [attr.colspan]="columns().length">{{ emptyText() }}</td>
          </tr>
        }
      }
    </tbody>
  </table>
</div>

@if (total() !== null) {
  <nav class="as-table__pager" aria-label="Pagination">
    <span class="as-table__range">{{ range() }}</span>
    <button type="button" class="as-table__page" aria-label="Previous page" [disabled]="page().page <= 1" (click)="goTo(page().page - 1)">
      <as-icon name="chevron-left" [size]="16" />
    </button>
    <span class="as-table__current">{{ page().page }} / {{ pageCount() }}</span>
    <button type="button" class="as-table__page" aria-label="Next page" [disabled]="page().page >= pageCount()" (click)="goTo(page().page + 1)">
      <as-icon name="chevron-right" [size]="16" />
    </button>
  </nav>
}
