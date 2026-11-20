import { ComponentFixture, TestBed } from '@angular/core/testing';
import { signal } from '@angular/core';
import { Main } from './main';
import { LayoutService } from '../../services/layout.service';
import { SidebarStatus } from '../enums/sidebar-status.enum';

class LayoutServiceMock {
  readonly state = signal(SidebarStatus.EXPANDED);
}

describe('Main', () => {
  let fixture: ComponentFixture<Main>;

  beforeEach(async () => {
    TestBed.overrideComponent(Main, {
      set: {
        imports: [],
        template: '',
      },
    });

    await TestBed.configureTestingModule({
      imports: [Main],
      providers: [
        { provide: LayoutService, useClass: LayoutServiceMock },
      ],
    }).compileComponents();

    fixture = TestBed.createComponent(Main);
    fixture.detectChanges();
  });

  it('exposes the sidebar status enum to the template', () => {
    expect(fixture.componentInstance.SidebarStatus.COLLAPSED).toBe(SidebarStatus.COLLAPSED);
  });
});
