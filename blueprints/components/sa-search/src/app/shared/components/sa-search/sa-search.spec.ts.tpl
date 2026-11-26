import { FormControl } from '@angular/forms';
import { ComponentFixture, TestBed } from '@angular/core/testing';
import { SaSearch } from './sa-search';

describe('SaSearch', () => {
  let fixture: ComponentFixture<SaSearch>;
  let component: SaSearch;

  beforeEach(async () => {
    await TestBed.configureTestingModule({
      imports: [SaSearch],
    }).compileComponents();

    fixture = TestBed.createComponent(SaSearch);
    component = fixture.componentInstance;
    fixture.componentRef.setInput('control', new FormControl<string | null>(''));
    fixture.detectChanges();
  });

  it('emits the collapsed search event when used in collapsed mode', () => {
    vi.useFakeTimers();

    fixture.componentRef.setInput('mode', 'collapsed');
    fixture.detectChanges();
    vi.advanceTimersByTime(400);
    fixture.detectChanges();

    const emitSpy = vi.spyOn(component.collapsedSearchClick, 'emit');
    const button = fixture.nativeElement.querySelector('button[aria-label="Buscar"]') as HTMLButtonElement;

    button.click();

    expect(emitSpy).toHaveBeenCalled();

    vi.useRealTimers();
  });

  describe('opening from the collapsed button', () => {
    const nextFrames = async (): Promise<void> => {
      for (let i = 0; i < 3; i++) await new Promise<void>((resolve) => requestAnimationFrame(() => resolve()));
      fixture.detectChanges();
    };
    const collapsedFixture = (): HTMLButtonElement => {
      fixture.destroy();
      fixture = TestBed.createComponent(SaSearch);
      component = fixture.componentInstance;
      document.body.append(fixture.nativeElement);
      fixture.componentRef.setInput('control', new FormControl<string | null>(''));
      fixture.componentRef.setInput('mode', 'collapsed');
      fixture.detectChanges();
      return fixture.nativeElement.querySelector('button[aria-label="Buscar"]') as HTMLButtonElement;
    };
    const field = (): HTMLInputElement => fixture.nativeElement.querySelector('input') as HTMLInputElement;

    afterEach(() => fixture.nativeElement.remove());

    it('puts the cursor in the field once the parent expands it after the click', async () => {
      collapsedFixture().click();
      fixture.componentRef.setInput('mode', 'input');
      fixture.detectChanges();
      await nextFrames();

      expect(field()).not.toBeNull();
      expect(document.activeElement).toBe(field());
    });

    it('does the same when it expands into chat mode', async () => {
      collapsedFixture().click();
      fixture.componentRef.setInput('mode', 'chat');
      fixture.detectChanges();
      await nextFrames();

      expect(document.activeElement).toBe(field());
    });

    it('forgets the request when the parent does not expand it in time, so a later change does not steal the focus', async () => {
      vi.useFakeTimers({ toFake: ['setTimeout', 'clearTimeout'] });
      collapsedFixture().click();
      vi.advanceTimersByTime(2000);
      vi.useRealTimers();
      fixture.componentRef.setInput('mode', 'input');
      fixture.detectChanges();
      await nextFrames();

      expect(field()).not.toBeNull();
      expect(document.activeElement).not.toBe(field());
    });

    it('does not steal focus when the parent changes the mode without a click on the collapsed button', async () => {
      collapsedFixture();
      fixture.componentRef.setInput('mode', 'input');
      fixture.detectChanges();
      await nextFrames();

      expect(field()).not.toBeNull();
      expect(document.activeElement).not.toBe(field());
    });
  });

  it('emits the search term when Enter is pressed', () => {
    const emitSpy = vi.spyOn(component.searchEnter, 'emit');
    component.control().setValue('  inbox  ');

    component.onKeyup(new KeyboardEvent('keyup', { key: 'Enter' }));

    expect(emitSpy).toHaveBeenCalledWith('inbox');
  });

  it('emits backClick in chat mode', () => {
    fixture.componentRef.setInput('mode', 'chat');
    fixture.detectChanges();

    const emitSpy = vi.spyOn(component.backClick, 'emit');
    const button = fixture.nativeElement.querySelector('button[aria-label="Cerrar búsqueda"]') as HTMLButtonElement;

    button.click();

    expect(emitSpy).toHaveBeenCalled();
  });

  it('delays the collapsed render when switching from input to collapsed mode', () => {
    vi.useFakeTimers();

    fixture.componentRef.setInput('mode', 'input');
    fixture.detectChanges();

    fixture.componentRef.setInput('mode', 'collapsed');
    fixture.detectChanges();

    expect(component.renderCollapsed()).toBe(false);

    vi.advanceTimersByTime(400);
    fixture.detectChanges();

    expect(component.renderCollapsed()).toBe(true);

    vi.useRealTimers();
  });
});
