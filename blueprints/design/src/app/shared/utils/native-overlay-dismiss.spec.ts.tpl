import { describe, expect, it, vi, beforeEach, afterEach } from 'vitest';
import { NativeOverlayRuntime, NativeOverlayScheduler, addNativeOverlayListeners, addNativeOverlayRepositionListeners, isEventInsideOverlay, removeNativeOverlayRepositionListeners, removeNativeOverlayListeners, resolveOverlayTriggerElement, type NativeOverlayHandlers } from './native-overlay-dismiss';

describe('NativeOverlayScheduler', () => {
  beforeEach(() => vi.useFakeTimers());
  afterEach(() => vi.useRealTimers());

  it('llama a onReposition en el siguiente frame tras schedule()', () => {
    const onReposition = vi.fn();
    const scheduler = new NativeOverlayScheduler(onReposition);

    scheduler.schedule();
    vi.runAllTimers();

    expect(onReposition).toHaveBeenCalledTimes(1);
  });

  it('cancela el frame anterior si se llama schedule() de nuevo antes de que corra', () => {
    const onReposition = vi.fn();
    const scheduler = new NativeOverlayScheduler(onReposition);

    scheduler.schedule();
    scheduler.schedule();
    vi.runAllTimers();

    expect(onReposition).toHaveBeenCalledTimes(1);
  });

  it('cancel() antes de que corra el frame evita la llamada', () => {
    const onReposition = vi.fn();
    const scheduler = new NativeOverlayScheduler(onReposition);

    scheduler.schedule();
    scheduler.cancel();
    vi.runAllTimers();

    expect(onReposition).not.toHaveBeenCalled();
  });
});

describe('addNativeOverlayListeners / removeNativeOverlayListeners', () => {
  it('engancha scroll (capture), resize y pointerdown/keydown (capture) en document', () => {
    const addSpy = vi.spyOn(document, 'addEventListener');
    const windowAddSpy = vi.spyOn(window, 'addEventListener');
    const handlers = { reposition: vi.fn(), onOutsidePointerDown: vi.fn(), onEscapeKeyDown: vi.fn() };

    addNativeOverlayListeners(document, handlers);

    expect(windowAddSpy).toHaveBeenCalledWith('scroll', handlers.reposition, true);
    expect(windowAddSpy).toHaveBeenCalledWith('resize', handlers.reposition);
    expect(addSpy).toHaveBeenCalledWith('pointerdown', handlers.onOutsidePointerDown, true);
    expect(addSpy).toHaveBeenCalledWith('keydown', handlers.onEscapeKeyDown, true);

    addSpy.mockRestore();
    windowAddSpy.mockRestore();
  });

  it('removeNativeOverlayListeners desengancha exactamente lo que agrego addNativeOverlayListeners', () => {
    const removeSpy = vi.spyOn(document, 'removeEventListener');
    const windowRemoveSpy = vi.spyOn(window, 'removeEventListener');
    const handlers = { reposition: vi.fn(), onOutsidePointerDown: vi.fn(), onEscapeKeyDown: vi.fn() };

    removeNativeOverlayListeners(document, handlers);

    expect(windowRemoveSpy).toHaveBeenCalledWith('scroll', handlers.reposition, true);
    expect(windowRemoveSpy).toHaveBeenCalledWith('resize', handlers.reposition);
    expect(removeSpy).toHaveBeenCalledWith('pointerdown', handlers.onOutsidePointerDown, true);
    expect(removeSpy).toHaveBeenCalledWith('keydown', handlers.onEscapeKeyDown, true);

    removeSpy.mockRestore();
    windowRemoveSpy.mockRestore();
  });
});

describe('resolveOverlayTriggerElement', () => {
  it('devuelve el propio elemento si ya tiene la clase sa-btn', () => {
    const el = document.createElement('button');
    el.className = 'sa-btn';
    const event = { currentTarget: el } as unknown as MouseEvent;

    expect(resolveOverlayTriggerElement(event)).toBe(el);
  });

  it('busca un descendiente .sa-btn si el propio elemento no la tiene', () => {
    const wrapper = document.createElement('sa-button');
    const inner = document.createElement('button');
    inner.className = 'sa-btn';
    wrapper.appendChild(inner);
    const event = { currentTarget: wrapper } as unknown as MouseEvent;

    expect(resolveOverlayTriggerElement(event)).toBe(inner);
  });

  it('devuelve el propio elemento si no hay .sa-btn en ningun lado', () => {
    const wrapper = document.createElement('div');
    const event = { currentTarget: wrapper } as unknown as MouseEvent;

    expect(resolveOverlayTriggerElement(event)).toBe(wrapper);
  });

  it('devuelve null si currentTarget no es un elemento', () => {
    const event = { currentTarget: null } as unknown as MouseEvent;

    expect(resolveOverlayTriggerElement(event)).toBeNull();
  });
});

describe('isEventInsideOverlay', () => {
  it('es true si el target esta dentro del panel', () => {
    const panel = document.createElement('div');
    const child = document.createElement('span');
    panel.appendChild(child);
    const event = { target: child } as unknown as Event;

    expect(isEventInsideOverlay(event, panel, null)).toBe(true);
  });

  it('es true si el target esta dentro del trigger', () => {
    const trigger = document.createElement('button');
    const event = { target: trigger } as unknown as Event;

    expect(isEventInsideOverlay(event, null, trigger)).toBe(true);
  });

  it('es false si el target no esta ni en el panel ni en el trigger', () => {
    const panel = document.createElement('div');
    const trigger = document.createElement('button');
    const outside = document.createElement('span');
    const event = { target: outside } as unknown as Event;

    expect(isEventInsideOverlay(event, panel, trigger)).toBe(false);
  });
});

describe('NativeOverlayRuntime', () => {
  function createHandlers(overrides: Partial<NativeOverlayHandlers> = {}): NativeOverlayHandlers {
    return {
      getPanelElement: () => null,
      getTriggerElement: () => null,
      isVisible: () => true,
      onDismiss: vi.fn(),
      onReposition: vi.fn(),
      ...overrides,
    };
  }

  beforeEach(() => vi.useFakeTimers());
  afterEach(() => vi.useRealTimers());

  it('scheduleReposition no hace nada si el overlay no esta visible', () => {
    const handlers = createHandlers({ isVisible: () => false });
    const runtime = new NativeOverlayRuntime(document, handlers);

    runtime.scheduleReposition();
    vi.runAllTimers();

    expect(handlers.onReposition).not.toHaveBeenCalled();
  });

  it('scheduleReposition llama a onReposition en el siguiente frame cuando esta visible (ej. tras scroll/resize)', () => {
    const handlers = createHandlers();
    const runtime = new NativeOverlayRuntime(document, handlers);

    runtime.scheduleReposition();
    vi.runAllTimers();

    expect(handlers.onReposition).toHaveBeenCalledTimes(1);
  });

  it('addListeners + scroll en window reagenda el reposicionamiento', () => {
    const handlers = createHandlers();
    const runtime = new NativeOverlayRuntime(document, handlers);

    runtime.addListeners();
    window.dispatchEvent(new Event('scroll'));
    vi.runAllTimers();

    expect(handlers.onReposition).toHaveBeenCalledTimes(1);
    runtime.removeListeners();
  });

  it('removeListeners hace que un scroll posterior ya no reagende nada', () => {
    const handlers = createHandlers();
    const runtime = new NativeOverlayRuntime(document, handlers);

    runtime.addListeners();
    runtime.removeListeners();
    window.dispatchEvent(new Event('scroll'));
    vi.runAllTimers();

    expect(handlers.onReposition).not.toHaveBeenCalled();
  });

  it('un pointerdown afuera del panel/trigger dispara onDismiss', () => {
    const panel = document.createElement('div');
    document.body.appendChild(panel);
    const handlers = createHandlers({ getPanelElement: () => panel });
    const runtime = new NativeOverlayRuntime(document, handlers);

    runtime.addListeners();
    const outside = document.createElement('div');
    document.body.appendChild(outside);
    outside.dispatchEvent(new PointerEvent('pointerdown', { bubbles: true }));

    expect(handlers.onDismiss).toHaveBeenCalledTimes(1);

    runtime.removeListeners();
    panel.remove();
    outside.remove();
  });

  it('un pointerdown dentro del panel NO dispara onDismiss', () => {
    const panel = document.createElement('div');
    document.body.appendChild(panel);
    const handlers = createHandlers({ getPanelElement: () => panel });
    const runtime = new NativeOverlayRuntime(document, handlers);

    runtime.addListeners();
    panel.dispatchEvent(new PointerEvent('pointerdown', { bubbles: true }));

    expect(handlers.onDismiss).not.toHaveBeenCalled();

    runtime.removeListeners();
    panel.remove();
  });

  it('un pointerdown dentro de un sub-panel marcado data-popover-sub-panel NO dispara onDismiss', () => {
    const panel = document.createElement('div');
    document.body.appendChild(panel);
    const subPanel = document.createElement('div');
    subPanel.setAttribute('data-popover-sub-panel', '');
    document.body.appendChild(subPanel);
    const handlers = createHandlers({ getPanelElement: () => panel });
    const runtime = new NativeOverlayRuntime(document, handlers);

    runtime.addListeners();
    subPanel.dispatchEvent(new PointerEvent('pointerdown', { bubbles: true }));

    expect(handlers.onDismiss).not.toHaveBeenCalled();

    runtime.removeListeners();
    panel.remove();
    subPanel.remove();
  });

  it('Escape con el overlay visible dispara onDismiss', () => {
    const handlers = createHandlers();
    const runtime = new NativeOverlayRuntime(document, handlers);

    runtime.addListeners();
    document.dispatchEvent(new KeyboardEvent('keydown', { key: 'Escape' }));

    expect(handlers.onDismiss).toHaveBeenCalledTimes(1);
    runtime.removeListeners();
  });

  it('Escape con el overlay ya cerrado no dispara onDismiss', () => {
    const handlers = createHandlers({ isVisible: () => false });
    const runtime = new NativeOverlayRuntime(document, handlers);

    runtime.addListeners();
    document.dispatchEvent(new KeyboardEvent('keydown', { key: 'Escape' }));

    expect(handlers.onDismiss).not.toHaveBeenCalled();
    runtime.removeListeners();
  });

  it('cleanup() cancela el reposicionamiento agendado y remueve los listeners', () => {
    const handlers = createHandlers();
    const runtime = new NativeOverlayRuntime(document, handlers);

    runtime.addListeners();
    runtime.scheduleReposition();
    runtime.cleanup();
    vi.runAllTimers();
    window.dispatchEvent(new Event('scroll'));
    vi.runAllTimers();

    expect(handlers.onReposition).not.toHaveBeenCalled();
  });
});

describe('addNativeOverlayRepositionListeners / removeNativeOverlayRepositionListeners', () => {
  it('engancha solo scroll (capture) y resize: sin cierre por click afuera ni Escape', () => {
    const documentAddSpy = vi.spyOn(document, 'addEventListener');
    const windowAddSpy = vi.spyOn(window, 'addEventListener');
    const reposition = vi.fn();

    addNativeOverlayRepositionListeners(reposition);

    expect(windowAddSpy).toHaveBeenCalledWith('scroll', reposition, true);
    expect(windowAddSpy).toHaveBeenCalledWith('resize', reposition);
    expect(documentAddSpy).not.toHaveBeenCalledWith('pointerdown', expect.anything(), expect.anything());
    expect(documentAddSpy).not.toHaveBeenCalledWith('keydown', expect.anything(), expect.anything());

    removeNativeOverlayRepositionListeners(reposition);
    documentAddSpy.mockRestore();
    windowAddSpy.mockRestore();
  });

  it('un scroll de cualquier contenedor llama a reposition y, tras desenganchar, ya no', () => {
    const reposition = vi.fn();
    const scroller = document.createElement('div');
    document.body.append(scroller);

    addNativeOverlayRepositionListeners(reposition);
    scroller.dispatchEvent(new Event('scroll'));
    expect(reposition).toHaveBeenCalledTimes(1);

    removeNativeOverlayRepositionListeners(reposition);
    scroller.dispatchEvent(new Event('scroll'));
    expect(reposition).toHaveBeenCalledTimes(1);

    scroller.remove();
  });
});
