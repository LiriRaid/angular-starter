import { ComponentFixture, TestBed } from '@angular/core/testing';
import { NAV_APP_NAME_TOKEN } from '@core/navigation/navigation.tokens';

import { UserPreferences } from './user-preferences';

describe('UserPreferences', () => {
  let fixture: ComponentFixture<UserPreferences>;
  let component: UserPreferences;

  beforeEach(async () => {
    TestBed.overrideComponent(UserPreferences, {
      set: {
        imports: [],
        template: '',
      },
    });

    await TestBed.configureTestingModule({
      imports: [UserPreferences],
      providers: [{ provide: NAV_APP_NAME_TOKEN, useValue: 'inventory' }],
    }).compileComponents();

    fixture = TestBed.createComponent(UserPreferences);
    component = fixture.componentInstance;
    fixture.detectChanges();
  });

  it('creates the component', () => {
    expect(component).toBeTruthy();
  });

  it('toggles drawer visibility through open and close', () => {
    expect(component.visible()).toBe(false);

    component.open();
    expect(component.visible()).toBe(true);

    component.close();
    expect(component.visible()).toBe(false);
  });

  it('starts on the info tab with the expected tabs', () => {
    expect(component.activeTab()).toBe('info');
    expect(component.tabs.map((tab) => tab.id)).toEqual(['info', 'prefs', 'activity']);
  });

  it('exposes the expected profile info items', () => {
    expect(component.infoItems).toHaveLength(4);
    expect(component.infoItems[0]).toEqual({ label: 'Nombre', value: 'Usuario' });
    expect(component.infoItems[3]).toEqual({ label: 'Organización', value: 'inventory' });
  });

  it('updates preferences through the section config', () => {
    const notifications = component.preferenceSections[0]?.items[0];
    const newsletter = component.preferenceSections[1]?.items[1];

    notifications?.setValue(false);
    newsletter?.setValue(true);

    expect(component.prefNotifications()).toBe(false);
    expect(component.prefNewsletter()).toBe(true);
  });
});
