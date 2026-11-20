import { TestBed } from '@angular/core/testing';
import { provideRouter } from '@angular/router';
import { Settings } from './settings';

describe('Settings', () => {
  beforeEach(async () => {
    await TestBed.configureTestingModule({
      imports: [Settings],
      providers: [provideRouter([])],
    }).compileComponents();
  });

  it('shows the title and a place for its sections', async () => {
    const fixture = TestBed.createComponent(Settings);
    await fixture.whenStable();
    const compiled = fixture.nativeElement as HTMLElement;
    expect(compiled.querySelector('h1')?.textContent).toContain('Settings');
    expect(compiled.querySelector('router-outlet')).not.toBeNull();
  });
});
