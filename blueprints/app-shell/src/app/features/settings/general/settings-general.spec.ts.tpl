import { TestBed } from '@angular/core/testing';
import { SettingsGeneral } from './settings-general';

describe('SettingsGeneral', () => {
  beforeEach(async () => {
    await TestBed.configureTestingModule({
      imports: [SettingsGeneral],
    }).compileComponents();
  });

  it('shows the general settings', async () => {
    const fixture = TestBed.createComponent(SettingsGeneral);
    await fixture.whenStable();
    const compiled = fixture.nativeElement as HTMLElement;
    expect(compiled.querySelector('h2')?.textContent).toContain('General');
    expect(compiled.querySelectorAll('dt')).toHaveLength(3);
  });
});
