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
