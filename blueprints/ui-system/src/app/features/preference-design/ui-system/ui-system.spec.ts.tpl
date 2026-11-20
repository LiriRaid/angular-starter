import { TestBed } from '@angular/core/testing';
import { AlertService } from '@shared/services';
import { UI_COMPONENTS } from './ui-system.catalog';
import { UiSystem } from './ui-system';

describe('UiSystem', () => {
  const render = async () => {
    await TestBed.configureTestingModule({ imports: [UiSystem] }).compileComponents();
    const fixture = TestBed.createComponent(UiSystem);
    await fixture.whenStable();
    return fixture;
  };

  it('lists every component with its selector and a preview', async () => {
    const fixture = await render();
    const cards = (fixture.nativeElement as HTMLElement).querySelectorAll('article[data-component]');
    expect(cards).toHaveLength(UI_COMPONENTS.length);
    expect((fixture.nativeElement as HTMLElement).textContent).toContain('as-button');
    expect(Array.from(cards).every((card) => card.querySelector('.border-dashed') !== null)).toBe(true);
  });

  it('says which tokens change a component', async () => {
    const fixture = await render();
    const button = (fixture.nativeElement as HTMLElement).querySelector('[data-component="button"]');
    expect(button?.textContent).toContain('Tamaño de botones');
    expect((fixture.nativeElement as HTMLElement).querySelector('[data-component="divider"]')?.textContent).toContain('ningún token');
  });

  it('filters the catalog by what is typed', async () => {
    const fixture = await render();
    fixture.componentInstance.query.set('modal');
    await fixture.whenStable();
    const cards = (fixture.nativeElement as HTMLElement).querySelectorAll('article[data-component]');
    expect(Array.from(cards).map((card) => card.getAttribute('data-component'))).toEqual(['modal']);
  });

  it('hides and shows the preview of a component', async () => {
    const fixture = await render();
    const component = fixture.componentInstance;
    component.setShown('button', false);
    await fixture.whenStable();
    expect((fixture.nativeElement as HTMLElement).querySelector('[data-component="button"] .border-dashed')).toBeNull();
    component.setShown('button', true);
    await fixture.whenStable();
    expect((fixture.nativeElement as HTMLElement).querySelector('[data-component="button"] .border-dashed')).not.toBeNull();
  });

  it('shows a toast through the alert service', async () => {
    const fixture = await render();
    const alerts = TestBed.inject(AlertService);
    const success = vi.spyOn(alerts, 'showSuccess');
    fixture.componentInstance.showToast();
    expect(success).toHaveBeenCalled();
  });
});
