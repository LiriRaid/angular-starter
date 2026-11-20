import { ComponentFixture, TestBed } from '@angular/core/testing';
import { NAV_APP_NAME_TOKEN } from '@core/navigation/navigation.tokens';

import { UserMenu } from './user-menu';

describe('UserMenu', () => {
  let fixture: ComponentFixture<UserMenu>;
  let component: UserMenu;

  beforeEach(async () => {
    TestBed.overrideComponent(UserMenu, {
      set: {
        imports: [],
        template: '',
      },
    });

    await TestBed.configureTestingModule({
      imports: [UserMenu],
      providers: [{ provide: NAV_APP_NAME_TOKEN, useValue: 'inventory' }],
    }).compileComponents();

    fixture = TestBed.createComponent(UserMenu);
    component = fixture.componentInstance;
    fixture.detectChanges();
  });

  it('creates the component', () => {
    expect(component).toBeTruthy();
  });

  it('builds the initials from the first and last word of the name', () => {
    component.userName.set('Ana María López');
    expect(component.userInitials()).toBe('AL');

    component.userName.set('ana');
    expect(component.userInitials()).toBe('AN');

    component.userName.set('  ');
    expect(component.userInitials()).toBe('?');
  });

  it('emits preferencesClick when the preferences are opened, even without a rendered popover', () => {
    const preferencesSpy = vi.spyOn(component.preferencesClick, 'emit');

    component.openPreferences();

    expect(preferencesSpy).toHaveBeenCalled();
  });

  it('shows the name of the project in the menu', () => {
    expect(component.appName).toBe('inventory');
  });
});
