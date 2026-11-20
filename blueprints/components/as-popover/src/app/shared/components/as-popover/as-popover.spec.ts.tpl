import { ComponentFixture, TestBed } from '@angular/core/testing';

import { AsPopover, type AsPopoverActionItem } from './as-popover';
import { getOppositePopoverPosition } from './as-popover.config';

type AsPopoverInternals = {
  triggerClass: () => string;
  panelClass: () => string;
  onActionClick: (action: AsPopoverActionItem) => void;
  resolveTriggerElement: (event: MouseEvent) => HTMLElement | null;
};

const SAMPLE_ITEMS = [
  { id: 'edit', label: 'Editar', icon: 'Pencil' },
  { id: 'delete', label: 'Eliminar', icon: 'Trash', disabled: true },
];

describe('AsPopover', () => {
  let fixture: ComponentFixture<AsPopover>;
  let component: AsPopover;
  let internals: AsPopoverInternals;

  beforeEach(async () => {
    TestBed.overrideComponent(AsPopover, {
      set: {
        imports: [],
        template: '',
      },
    });

    await TestBed.configureTestingModule({
      imports: [AsPopover],
    }).compileComponents();

    fixture = TestBed.createComponent(AsPopover);
    component = fixture.componentInstance;
    internals = component as unknown as AsPopoverInternals;
    fixture.componentRef.setInput('items', SAMPLE_ITEMS);
    fixture.detectChanges();
  });

  it('creates the component', () => {
    expect(component).toBeTruthy();
  });

  it('builds trigger classes with the active state', () => {
    fixture.componentRef.setInput('triggerStyleClass', 'base-trigger');
    fixture.componentRef.setInput('triggerActiveClass', 'active-trigger');
    component.isOpen.set(true);

    expect(internals.triggerClass()).toBe('base-trigger active-trigger');
  });

  it('builds panel classes for actions mode', () => {
    fixture.componentRef.setInput('actions', true);
    fixture.componentRef.setInput('popoverStyleClass', 'custom-panel');

    expect(internals.panelClass()).toContain('as-popover');
    expect(internals.panelClass()).toContain('as-popover--actions');
    expect(internals.panelClass()).toContain('custom-panel');
  });

  it('emits the selected action id', () => {
    const emitSpy = vi.spyOn(component.actionSelected, 'emit');

    internals.onActionClick(SAMPLE_ITEMS[0]);

    expect(emitSpy).toHaveBeenCalledWith('edit');
  });

  it('ignores disabled actions', () => {
    const emitSpy = vi.spyOn(component.actionSelected, 'emit');

    internals.onActionClick(SAMPLE_ITEMS[1]);

    expect(emitSpy).not.toHaveBeenCalled();
  });

  it('resolves the trigger button from a wrapper element', () => {
    const wrapper = document.createElement('div');
    const button = document.createElement('button');
    button.classList.add('as-btn');
    wrapper.appendChild(button);

    const event = { currentTarget: wrapper } as unknown as MouseEvent;

    expect(internals.resolveTriggerElement(event)).toBe(button);
  });

  describe('anclado dentro de un contenedor con scroll', () => {
    let scroller: HTMLElement;
    let trigger: HTMLElement;
    let panel: HTMLElement;
    const setRect = (el: HTMLElement, top: number, height: number): void => {
      vi.spyOn(el, 'getBoundingClientRect').mockReturnValue({ top, bottom: top + height, left: 400, right: 600, width: 200, height, x: 400, y: top, toJSON: () => ({}) } as DOMRect);
    };
    const reposition = (): void => (component as unknown as { positionPopover: () => void }).positionPopover();

    beforeEach(() => {
      vi.spyOn(document.documentElement, 'clientWidth', 'get').mockReturnValue(1000);
      vi.spyOn(document.documentElement, 'clientHeight', 'get').mockReturnValue(800);
      scroller = document.createElement('div');
      scroller.style.overflowY = 'auto';
      setRect(scroller, 80, 600);
      trigger = document.createElement('button');
      scroller.appendChild(trigger);
      panel = document.createElement('div');
      document.body.append(scroller, panel);

      const target = component as unknown as { triggerElement: HTMLElement | null; getPanelElement: () => HTMLElement };
      target.triggerElement = trigger;
      vi.spyOn(target, 'getPanelElement').mockReturnValue(panel);
    });

    afterEach(() => {
      scroller.remove();
      panel.remove();
      vi.restoreAllMocks();
    });

    it('con el ancla visible posiciona el panel', () => {
      setRect(trigger, 300, 40);
      const hideSpy = vi.spyOn(component, 'hide');

      reposition();

      expect(panel.dataset['positioned']).toBe('true');
      expect(hideSpy).not.toHaveBeenCalled();
    });

    it('un ancla sin tamaño (oculta o desmontada) no cuenta como "fuera de vista": no cierra el popover al abrirse', () => {
      vi.spyOn(trigger, 'getBoundingClientRect').mockReturnValue({ top: 0, bottom: 0, left: 0, right: 0, width: 0, height: 0, x: 0, y: 0, toJSON: () => ({}) } as DOMRect);
      const hideSpy = vi.spyOn(component, 'hide');

      reposition();

      expect(hideSpy).not.toHaveBeenCalled();
      expect(panel.dataset['positioned']).toBe('true');
    });

    it('cuando el scroll deja el ancla fuera del contenedor, el popover se cierra en vez de quedar flotando sin ancla', () => {
      setRect(trigger, 20, 40);
      const hideSpy = vi.spyOn(component, 'hide').mockImplementation(() => undefined);

      reposition();

      expect(hideSpy).toHaveBeenCalled();
      expect(panel.dataset['positioned']).toBeUndefined();
    });
  });

  it('returns the opposite side for a position', () => {
    expect(getOppositePopoverPosition('top')).toBe('bottom');
    expect(getOppositePopoverPosition('left')).toBe('right');
  });
});
