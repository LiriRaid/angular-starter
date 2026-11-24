import { ComponentFixture, TestBed } from '@angular/core/testing';
import { describe, expect, it, beforeEach, vi } from 'vitest';
import { ComponentRef, TemplateRef } from '@angular/core';
import type { CdkDragDrop } from '@angular/cdk/drag-drop';
import { SaReorderList } from './sa-reorder-list';

describe('SaReorderList', () => {
  let fixture: ComponentFixture<SaReorderList<string>>;
  let component: SaReorderList<string>;
  let ref: ComponentRef<SaReorderList<string>>;

  function dragEvent(previousIndex: number, currentIndex: number): CdkDragDrop<string[]> {
    return { previousIndex, currentIndex } as CdkDragDrop<string[]>;
  }

  beforeEach(async () => {
    TestBed.overrideComponent(SaReorderList, {
      set: { template: '' },
    });

    await TestBed.configureTestingModule({
      imports: [SaReorderList],
    }).compileComponents();

    fixture = TestBed.createComponent(SaReorderList<string>);
    component = fixture.componentInstance;
    ref = fixture.componentRef;
    ref.setInput('items', ['a', 'b', 'c']);
    ref.setInput('itemTemplate', {} as TemplateRef<unknown>);
    ref.setInput('trackBy', (item: string) => item);
    fixture.detectChanges();
  });

  it('creates the component', () => {
    expect(component).toBeTruthy();
  });

  it('reordena hacia adelante y emite el array resultante', () => {
    const emitSpy = vi.spyOn(component.reordered, 'emit');

    component.onDrop(dragEvent(0, 2));

    expect(emitSpy).toHaveBeenCalledWith(['b', 'c', 'a']);
  });

  it('reordena hacia atras y emite el array resultante', () => {
    const emitSpy = vi.spyOn(component.reordered, 'emit');

    component.onDrop(dragEvent(2, 0));

    expect(emitSpy).toHaveBeenCalledWith(['c', 'a', 'b']);
  });

  it('no emite cuando previousIndex y currentIndex son iguales', () => {
    const emitSpy = vi.spyOn(component.reordered, 'emit');

    component.onDrop(dragEvent(1, 1));

    expect(emitSpy).not.toHaveBeenCalled();
  });

  it('no muta el array original al reordenar', () => {
    const original = component.items();

    component.onDrop(dragEvent(0, 1));

    expect(component.items()).toBe(original);
    expect(original).toEqual(['a', 'b', 'c']);
  });

  it('usa la clave estable provista por el consumidor', () => {
    ref.setInput('trackBy', (item: string) => `field-${item}`);
    fixture.detectChanges();

    expect(component.trackItem('b')).toBe('field-b');
  });
});
