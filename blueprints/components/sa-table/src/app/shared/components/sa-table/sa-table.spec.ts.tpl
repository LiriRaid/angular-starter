import { ComponentFixture, TestBed } from '@angular/core/testing';
import { describe, expect, it, vi, beforeEach } from 'vitest';
import { ComponentRef } from '@angular/core';
import { SaTable } from './sa-table';

type TestRow = { id: number; name: string };

describe('SaTable', () => {
  let fixture: ComponentFixture<SaTable<TestRow>>;
  let component: SaTable<TestRow>;
  let ref: ComponentRef<SaTable<TestRow>>;

  const ITEMS = Array.from({ length: 25 }, (_, i) => ({ id: i + 1, name: `Item ${i + 1}` }));

  beforeEach(async () => {
    TestBed.overrideComponent(SaTable, { set: { imports: [], template: '' } });

    await TestBed.configureTestingModule({
      imports: [SaTable],
    }).compileComponents();

    fixture = TestBed.createComponent<SaTable<TestRow>>(SaTable);
    component = fixture.componentInstance;
    ref = fixture.componentRef;
    ref.setInput('value', ITEMS);
    ref.setInput('rows', 10);
    fixture.detectChanges();
  });

  it('creates the component', () => {
    expect(component).toBeTruthy();
  });

  it('first page shows first 10 items', () => {
    expect(component.displayValue().length).toBe(10);
    expect((component.displayValue()[0] as TestRow).id).toBe(1);
  });

  it('nextPage advances to the second page', () => {
    component.nextPage();
    fixture.detectChanges();
    expect((component.displayValue()[0] as TestRow).id).toBe(11);
  });

  it('lastPage navigates to the last page', () => {
    component.lastPage();
    fixture.detectChanges();
    expect((component.displayValue()[0] as TestRow).id).toBe(21);
  });

  it('firstPage returns to page 1 from last', () => {
    component.lastPage();
    component.firstPage();
    fixture.detectChanges();
    expect((component.displayValue()[0] as TestRow).id).toBe(1);
  });

  it('totalPages is calculated from totalRecords and rows', () => {
    expect(component.totalPages()).toBe(3);
  });

  it('resolveField returns the correct field value from a row', () => {
    const row = { id: 42, name: 'Test' };
    expect(component.resolveField(row, 'name')).toBe('Test');
  });

  it('skeletonItems returns an array of the skeletonRows length', () => {
    ref.setInput('skeletonRows', 6);
    fixture.detectChanges();
    expect(component.skeletonItems().length).toBe(6);
  });

  it('displayValue returns skeleton items when loading', () => {
    ref.setInput('loading', true);
    ref.setInput('skeletonRows', 4);
    fixture.detectChanges();
    expect(component.displayValue().length).toBe(4);
  });

  it('toggleExpand expands then collapses a row', () => {
    const row = ITEMS[0];
    expect(component.isExpanded(row)).toBe(false);
    component.toggleExpand(row);
    expect(component.isExpanded(row)).toBe(true);
    component.toggleExpand(row);
    expect(component.isExpanded(row)).toBe(false);
  });

  it('headerClass contains the alignment class for right-aligned column', () => {
    const cls = component.headerClass({ field: 'id', header: 'ID', align: 'right' });
    expect(cls).toContain('text-right');
  });

  it('cellClass contains the alignment class for center-aligned column', () => {
    const cls = component.cellClass({ field: 'id', header: 'ID', align: 'center' });
    expect(cls).toContain('text-center');
  });

  it('goToPage navigates to the correct page', () => {
    component.goToPage(2);
    fixture.detectChanges();
    expect((component.displayValue()[0] as TestRow).id).toBe(11);
  });

  it('onRowClick does not emit when loading', () => {
    const spy = vi.spyOn(component.rowClick, 'emit');
    ref.setInput('loading', true);
    ref.setInput('clickableRows', true);
    fixture.detectChanges();
    component.onRowClick(ITEMS[0], new MouseEvent('click'));
    expect(spy).not.toHaveBeenCalled();
  });
});
