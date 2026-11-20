import { Component, signal } from '@angular/core';
import { TestBed, type ComponentFixture } from '@angular/core/testing';
import { beforeEach, describe, expect, it } from 'vitest';

import { AsTable } from './as-table';

@Component({
  selector: 'as-table-footer-spec-host',
  imports: [AsTable],
  template: `
    <as-table [value]="rows" [columns]="columns" [paginator]="false" [selectable]="selectable()" [footerTemplate]="withFooter() ? footer : null" />
    <ng-template #footer let-colspan="colspan"><button class="add-row" [attr.data-colspan]="colspan">Agregar</button></ng-template>
  `,
})
class TableHost {
  readonly rows = [{ id: 1, name: 'Ana' }];
  readonly columns = [
    { field: 'id', header: 'ID' },
    { field: 'name', header: 'Nombre' },
  ];
  readonly selectable = signal(false);
  readonly withFooter = signal(true);
}

describe('AsTable · footerTemplate', () => {
  let fixture: ComponentFixture<TableHost>;
  const footerCell = (): HTMLTableCellElement | null => fixture.nativeElement.querySelector('tfoot td');

  beforeEach(async () => {
    await TestBed.configureTestingModule({ imports: [TableHost] }).compileComponents();
    fixture = TestBed.createComponent(TableHost);
    fixture.detectChanges();
  });

  it('pinta el pie en un <tfoot> que abarca todas las columnas y le pasa el colspan a la plantilla', () => {
    expect(footerCell()?.getAttribute('colspan')).toBe('2');
    expect(footerCell()?.querySelector('.add-row')?.getAttribute('data-colspan')).toBe('2');
  });

  it('el colspan suma la columna de selección', () => {
    fixture.componentInstance.selectable.set(true);
    fixture.detectChanges();

    expect(footerCell()?.getAttribute('colspan')).toBe('3');
  });

  it('sin plantilla no hay <tfoot>', () => {
    fixture.componentInstance.withFooter.set(false);
    fixture.detectChanges();

    expect(fixture.nativeElement.querySelector('tfoot')).toBeNull();
  });
});
