import { Component } from '@angular/core';
import { TestBed } from '@angular/core/testing';
import { provideAsIcons } from '@core/icons/icons.provider';
import { AsReorderList } from './as-reorder-list';

interface Step {
  id: number;
  name: string;
}

@Component({
  imports: [AsReorderList],
  template: `
    <as-reorder-list [items]="steps" [itemTemplate]="step" [trackBy]="byId" (reordered)="received = $event" />
    <ng-template #step let-item let-index="index">{{ index + 1 }}. {{ item.name }}</ng-template>
  `,
})
class Host {
  steps: Step[] = [
    { id: 1, name: 'Plan' },
    { id: 2, name: 'Build' },
    { id: 3, name: 'Ship' },
  ];
  received: Step[] = [];
  byId = (item: Step) => item.id;
}

describe('AsReorderList', () => {
  function render() {
    TestBed.configureTestingModule({ imports: [Host], providers: [provideAsIcons()] });
    const fixture = TestBed.createComponent(Host);
    fixture.detectChanges();
    const element = fixture.nativeElement as HTMLElement;
    const names = (list: Step[]) => list.map((step) => step.name);
    const rows = () => Array.from(element.querySelectorAll<HTMLElement>('.as-reorder__row'));
    return { fixture, host: fixture.componentInstance, element, names, rows };
  }

  it('draws each item with the template and its position', () => {
    const { rows } = render();
    expect(rows().map((row) => row.querySelector('.as-reorder__content')?.textContent?.trim())).toEqual([
      '1. Plan',
      '2. Build',
      '3. Ship',
    ]);
  });

  it('moves an item with the buttons', () => {
    const { host, element, names } = render();
    (element.querySelectorAll('[aria-label="Move down"]')[0] as HTMLButtonElement).click();
    expect(names(host.received)).toEqual(['Build', 'Plan', 'Ship']);
  });

  it('cannot move the first item up or the last one down', () => {
    const { element } = render();
    expect((element.querySelectorAll('[aria-label="Move up"]')[0] as HTMLButtonElement).disabled).toBe(true);
    expect((element.querySelectorAll('[aria-label="Move down"]')[2] as HTMLButtonElement).disabled).toBe(true);
  });

  it('moves an item with Alt and the arrow keys', () => {
    const { host, element, names } = render();
    const handle = element.querySelectorAll('.as-reorder__handle')[2] as HTMLElement;
    handle.dispatchEvent(new KeyboardEvent('keydown', { key: 'ArrowUp', altKey: true, bubbles: true }));
    expect(names(host.received)).toEqual(['Plan', 'Ship', 'Build']);
  });

  it('reorders by dragging one row onto another', () => {
    const { host, rows, names } = render();
    const drag = (type: string, row: HTMLElement) => row.dispatchEvent(new Event(type, { bubbles: true, cancelable: true }));
    drag('dragstart', rows()[0]!);
    drag('dragover', rows()[2]!);
    drag('drop', rows()[2]!);
    expect(names(host.received)).toEqual(['Build', 'Ship', 'Plan']);
  });
});
