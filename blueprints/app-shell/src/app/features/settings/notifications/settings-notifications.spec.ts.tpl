import { TestBed } from '@angular/core/testing';
import { SettingsNotifications } from './settings-notifications';

describe('SettingsNotifications', () => {
  beforeEach(async () => {
    await TestBed.configureTestingModule({
      imports: [SettingsNotifications],
    }).compileComponents();
  });

  it('shows one switch per option and keeps what is toggled', async () => {
    const fixture = TestBed.createComponent(SettingsNotifications);
    await fixture.whenStable();
    const compiled = fixture.nativeElement as HTMLElement;
    expect(compiled.querySelectorAll('li')).toHaveLength(2);

    fixture.componentInstance.weeklySummary.set(true);
    expect(fixture.componentInstance.weeklySummary()).toBe(true);
  });
});
