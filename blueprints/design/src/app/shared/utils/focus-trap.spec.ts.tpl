import { focusableElements, trapTabKey } from './focus-trap';

describe('focus trap', () => {
  let container: HTMLElement;

  beforeEach(() => {
    container = document.createElement('div');
    container.tabIndex = -1;
    container.innerHTML = `
      <button id="first">First</button>
      <button disabled>Disabled</button>
      <input id="middle" />
      <a href="#x" hidden>Hidden</a>
      <button id="last">Last</button>`;
    document.body.appendChild(container);
  });

  afterEach(() => container.remove());

  const press = (shiftKey = false): KeyboardEvent => {
    const event = new KeyboardEvent('keydown', { key: 'Tab', shiftKey, cancelable: true });
    trapTabKey(event, container);
    return event;
  };

  it('lists what the Tab key can reach, skipping disabled and hidden elements', () => {
    expect(focusableElements(container).map((element) => element.id)).toEqual(['first', 'middle', 'last']);
  });

  it('wraps from the last element to the first', () => {
    (container.querySelector('#last') as HTMLElement).focus();
    expect(press().defaultPrevented).toBe(true);
    expect(document.activeElement?.id).toBe('first');
  });

  it('wraps from the first element to the last with Shift+Tab', () => {
    (container.querySelector('#first') as HTMLElement).focus();
    expect(press(true).defaultPrevented).toBe(true);
    expect(document.activeElement?.id).toBe('last');
  });

  it('leaves Tab alone in the middle of the container', () => {
    (container.querySelector('#middle') as HTMLElement).focus();
    expect(press().defaultPrevented).toBe(false);
  });

  it('ignores other keys', () => {
    const event = new KeyboardEvent('keydown', { key: 'a', cancelable: true });
    trapTabKey(event, container);
    expect(event.defaultPrevented).toBe(false);
  });

  it('keeps focus on the container when it has nothing to focus', () => {
    const empty = document.createElement('div');
    empty.tabIndex = -1;
    document.body.appendChild(empty);
    const event = new KeyboardEvent('keydown', { key: 'Tab', cancelable: true });
    trapTabKey(event, empty);
    expect(event.defaultPrevented).toBe(true);
    expect(document.activeElement).toBe(empty);
    empty.remove();
  });
});
