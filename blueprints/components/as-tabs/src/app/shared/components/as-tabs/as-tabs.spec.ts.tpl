import { ComponentFixture, TestBed } from '@angular/core/testing';

import { AsTabs, type AsTab } from './as-tabs';

const TABS: readonly AsTab[] = [
  { id: 'info', label: 'Información' },
  { id: 'prefs', label: 'Preferencias', icon: 'Settings' },
  { id: 'activity', label: 'Actividad' },
];

type AsTabsInternals = {
  selectTab: (tab: AsTab, event: Event) => void;
  scrollTabIntoView: (tab: HTMLElement) => void;
  syncActiveBar: (tab?: HTMLElement | null) => void;
};

function defineLayout(el: HTMLElement, props: Partial<Record<'offsetLeft' | 'offsetWidth' | 'clientWidth' | 'scrollWidth', number>>): void {
  for (const [key, value] of Object.entries(props)) {
    Object.defineProperty(el, key, { value, configurable: true });
  }
}

describe('AsTabs', () => {
  let fixture: ComponentFixture<AsTabs>;
  let component: AsTabs;
  let internals: AsTabsInternals;

  beforeEach(async () => {
    TestBed.overrideComponent(AsTabs, {
      set: {
        imports: [],
        template: '',
      },
    });

    await TestBed.configureTestingModule({
      imports: [AsTabs],
    }).compileComponents();

    fixture = TestBed.createComponent(AsTabs);
    component = fixture.componentInstance;
    internals = component as unknown as AsTabsInternals;
    fixture.componentRef.setInput('tabs', TABS);
    component.active.set('info');
    fixture.detectChanges();
  });

  it('creates the component', () => {
    expect(component).toBeTruthy();
  });

  it('updates the active tab when selecting another option', () => {
    component.active.set('activity');

    expect(component.active()).toBe('activity');
  });

  it('keeps the same active tab when selecting the current one', () => {
    component.active.set('info');

    expect(component.active()).toBe('info');
  });

  describe('scrollTabIntoView', () => {
    function buildContent(): HTMLElement {
      const content = document.createElement('div');
      content.className = 'as-tablist-content';
      content.scrollTo = vi.fn();
      defineLayout(content, { clientWidth: 200 });
      fixture.nativeElement.appendChild(content);
      return content;
    }

    it('sin carril de tabs (.as-tablist-content ausente) no hace nada', () => {
      const tab = document.createElement('div');
      expect(() => internals.scrollTabIntoView(tab)).not.toThrow();
    });

    it('desplaza hacia la izquierda cuando el tab queda antes del área visible', () => {
      const content = buildContent();
      content.scrollLeft = 100;
      const tab = document.createElement('div');
      defineLayout(tab, { offsetLeft: 10, offsetWidth: 50 });

      internals.scrollTabIntoView(tab);

      expect(content.scrollTo).toHaveBeenCalledWith({ left: 0, behavior: 'smooth' });
    });

    it('desplaza hacia la derecha cuando el tab queda después del área visible', () => {
      const content = buildContent();
      content.scrollLeft = 0;
      const tab = document.createElement('div');
      defineLayout(tab, { offsetLeft: 300, offsetWidth: 50 });

      internals.scrollTabIntoView(tab);

      expect(content.scrollTo).toHaveBeenCalledWith({ left: 300 + 50 + 52 - 200, behavior: 'smooth' });
    });

    it('no desplaza cuando el tab ya está visible', () => {
      const content = buildContent();
      content.scrollLeft = 0;
      const tab = document.createElement('div');
      defineLayout(tab, { offsetLeft: 60, offsetWidth: 40 });

      internals.scrollTabIntoView(tab);

      expect(content.scrollTo).not.toHaveBeenCalled();
    });
  });

  describe('syncActiveBar', () => {
    function buildBar(): HTMLElement {
      const bar = document.createElement('div');
      bar.className = 'as-tablist-active-bar';
      fixture.nativeElement.appendChild(bar);
      return bar;
    }

    it('sin barra activa (.as-tablist-active-bar ausente) no hace nada', () => {
      const tab = document.createElement('div');
      expect(() => internals.syncActiveBar(tab)).not.toThrow();
    });

    it('ajusta el ancho y la posición de la barra al tab recibido', () => {
      const bar = buildBar();
      const tab = document.createElement('div');
      defineLayout(tab, { offsetLeft: 24, offsetWidth: 80 });

      internals.syncActiveBar(tab);

      expect(bar.style.width).toBe('80px');
      expect(bar.style.left).toBe('24px');
    });

    it('sin tab explícito, usa .as-tab--active como referencia', () => {
      const bar = buildBar();
      const active = document.createElement('div');
      active.className = 'as-tab--active';
      defineLayout(active, { offsetLeft: 5, offsetWidth: 30 });
      fixture.nativeElement.appendChild(active);

      internals.syncActiveBar();

      expect(bar.style.width).toBe('30px');
      expect(bar.style.left).toBe('5px');
    });

    it('en variant pills, toma el color del tab desde --as-tab-color', () => {
      fixture.componentRef.setInput('variant', 'pills');
      const bar = buildBar();
      const tab = document.createElement('div');
      defineLayout(tab, { offsetLeft: 0, offsetWidth: 10 });
      tab.style.setProperty('--as-tab-color', '#ff0000');

      internals.syncActiveBar(tab);

      expect(bar.style.background).toBe('rgb(255, 0, 0)');
    });
  });

  describe('selectTab', () => {
    it('actualiza el tab activo aunque no haya currentTarget', () => {
      expect(() => internals.selectTab(TABS[2], { currentTarget: null } as unknown as Event)).not.toThrow();
      expect(component.active()).toBe('activity');
    });

    it('llama a scrollTabIntoView y syncActiveBar con el tab clickeado', () => {
      const scrollSpy = vi.spyOn(internals, 'scrollTabIntoView');
      const syncSpy = vi.spyOn(internals, 'syncActiveBar');
      const tab = document.createElement('div');

      internals.selectTab(TABS[1], { currentTarget: tab } as unknown as Event);

      expect(component.active()).toBe('prefs');
      expect(scrollSpy).toHaveBeenCalledWith(tab);
      expect(syncSpy).toHaveBeenCalledWith(tab);
    });
  });
});

describe('AsTabs · contador (template real)', () => {
  let fixture: ComponentFixture<AsTabs>;

  const counters = (): HTMLElement[] => Array.from(fixture.nativeElement.querySelectorAll('.as-tab-count'));

  beforeEach(async () => {
    await TestBed.configureTestingModule({ imports: [AsTabs] }).compileComponents();
    fixture = TestBed.createComponent(AsTabs);
    fixture.componentRef.setInput('tabs', [
      { id: 'a', label: 'Abiertas', count: 3 },
      { id: 'b', label: 'Pendientes', count: 5, countTone: 'danger' },
      { id: 'c', label: 'Cerradas' },
    ] satisfies readonly AsTab[]);
    fixture.detectChanges();
  });

  it('solo pinta contador en las tabs que traen count, con el tono primario por defecto', () => {
    const [first, second] = counters();

    expect(counters()).toHaveLength(2);
    expect(first.textContent?.trim()).toBe('3');
    expect(first.classList.contains('bg-(--color-primary-500)')).toBe(true);
    expect(second.textContent?.trim()).toBe('5');
    expect(second.classList.contains('bg-(--app-status-busy)')).toBe(true);
    expect(second.classList.contains('bg-(--color-primary-500)')).toBe(false);
  });
});
