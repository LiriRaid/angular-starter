<div class="as-table-container">
  <table class="as-table" [style.min-width]="tableMinWidth()">
    <thead class="as-table-head">
      <tr>
        @if (selectable()) {
          <th class="as-table-checkbox-th" style="width: 3rem; min-width: 3rem">
            <as-checkbox ariaLabel="Seleccionar todos" [ngModel]="allPageSelected()" [indeterminate]="somePageSelected()" (ngModelChange)="toggleSelectAll()" />
          </th>
        }
        @for (column of columns(); track column.field) {
          <th [class]="headerClass(column)" [style.width]="column.width">{{ column.header }}</th>
        }
        @if (showExpandColumn()) {
          <th class="p-2" style="width: 3.5rem"></th>
        }
      </tr>
    </thead>

    <tbody class="as-table-body">
      @if (displayValue().length === 0) {
        <tr class="as-table-empty-row">
          <td [attr.colspan]="totalColspan()" class="px-4 py-12 text-center text-body-2-regular text-(--app-text-muted)">
            {{ emptyMessage() }}
          </td>
        </tr>
      }

      @for (row of displayValue(); track rowTrackByFn()($index, row)) {
        <tr class="transition-colors" [class.cursor-pointer]="!loading() && clickableRows()" [class.as-row--expanded]="expandable() && isExpanded(row)" [ngClass]="!loading() && rowClass() ? rowClass()!(row) : ''" (click)="onRowClick(row, $event)">
          @if (selectable()) {
            <td class="as-table-checkbox-td" style="width: 3rem; min-width: 3rem" (click)="$event.stopPropagation()">
              @if (loading()) {
                <div class="flex items-center justify-center">
                  <as-skeleton shape="circle" size="1.25rem" />
                </div>
              } @else {
                <as-checkbox ariaLabel="Seleccionar fila" [ngModel]="isRowSelected(row)" (ngModelChange)="toggleRowSelection(row)" />
              }
            </td>
          }
          @for (column of columns(); track column.field) {
            <td [class]="cellClass(column)" [style.width]="column.width">
              @if (loading()) {
                @if (skeletonTemplateFor(column.field); as skeletonTemplate) {
                  <ng-container *ngTemplateOutlet="skeletonTemplate" />
                } @else {
                  <as-skeleton width="70%" textClass="text-caption-1-regular" [align]="column.align ?? 'left'" />
                }
              } @else if (templateFor(column.field); as cellTemplate) {
                <ng-container *ngTemplateOutlet="cellTemplate; context: cellContext(row)" />
              } @else {
                {{ resolveField(row, column.field) }}
              }
            </td>
          }
          @if (showExpandColumn()) {
            <td class="as-table-expand-cell p-2 text-center align-middle" style="width: 3.5rem">
              @if (loading()) {
                <as-skeleton shape="circle" size="2rem" align="center" />
              } @else {
                <button type="button" class="as-table-chevron inline-flex h-8 w-8 items-center justify-center rounded-full" [attr.aria-expanded]="isExpanded(row)" (click)="toggleExpand(row); $event.stopPropagation()">
                  <as-icon name="ChevronDown" size="18" color="var(--app-text-subtle)" class="transition-transform duration-200" [class.rotate-180]="isExpanded(row)" />
                </button>
              }
            </td>
          }
        </tr>

        @if (expandable() && !loading()) {
          <tr class="as-table-expansion" [class.is-open]="isExpanded(row)">
            <td [attr.colspan]="totalColspan()">
              <div class="as-table-expansion-grid">
                <div class="as-table-expansion-clip">
                  <div class="p-4">
                    <ng-container *ngTemplateOutlet="rowExpansionTemplate() ?? null; context: cellContext(row)" />
                  </div>
                </div>
              </div>
            </td>
          </tr>
        }
      }
    </tbody>

    @if (footerTemplate(); as footerTpl) {
      <tfoot class="as-table-foot">
        <tr>
          <td [attr.colspan]="totalColspan()">
            <ng-container *ngTemplateOutlet="footerTpl; context: { colspan: totalColspan() }" />
          </td>
        </tr>
      </tfoot>
    }
  </table>
</div>

@if (showPaginator()) {
  <div class="as-paginator flex flex-wrap items-center justify-end gap-x-5 gap-y-3">
    <span class="as-paginator-current text-caption-1-regular"> Mostrando {{ rangeStart() }} - {{ rangeEnd() }} de {{ totalRecords() }} {{ itemLabel() }} </span>

    <div class="as-paginator-pages flex items-center gap-1">
      <button type="button" class="as-paginator-nav" [disabled]="safePage() === 0" (click)="firstPage()" aria-label="Primera pagina">
        <as-icon name="ChevronsLeft" size="16" color="currentColor" />
      </button>
      <button type="button" class="as-paginator-nav" [disabled]="safePage() === 0" (click)="prevPage()" aria-label="Pagina anterior">
        <as-icon name="ChevronLeft" size="16" color="currentColor" />
      </button>

      @for (item of pageItems(); track $index) {
        @if (item === 'ellipsis') {
          <span class="as-paginator-ellipsis">…</span>
        } @else {
          <button type="button" class="as-paginator-page" [class.is-active]="item === safePage() + 1" (click)="goToPage(item)">{{ item }}</button>
        }
      }

      <button type="button" class="as-paginator-nav" [disabled]="safePage() === totalPages() - 1" (click)="nextPage()" aria-label="Pagina siguiente">
        <as-icon name="ChevronRight" size="16" color="currentColor" />
      </button>
      <button type="button" class="as-paginator-nav" [disabled]="safePage() === totalPages() - 1" (click)="lastPage()" aria-label="Ultima pagina">
        <as-icon name="ChevronsRight" size="16" color="currentColor" />
      </button>
    </div>

    @if (rowsPerPageOptions().length > 1) {
      <as-select variant="compact" [options]="rowsPerPageOptions()" [ngModel]="pageSize()" (ngModelChange)="setPageSize($event)" class="as-paginator-rpp-dropdown" aria-label="Filas por pagina" />
    }
  </div>
}
