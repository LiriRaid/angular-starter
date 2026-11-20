import { ComponentFixture, TestBed } from '@angular/core/testing';
import { signal } from '@angular/core';
import { provideRouter, Router } from '@angular/router';
import { BreadcrumbComponent } from './breadcrumb';
import { LayoutService } from '../../services/layout.service';
import { SidebarStatus } from '../../layout/enums/sidebar-status.enum';
import { DropdownCoordinatorService } from '../../services/dropdown-coordinator.service';

class LayoutServiceMock {
  readonly state = signal(SidebarStatus.EXPANDED);
  readonly isMobile = signal(false);
}

describe('BreadcrumbComponent', () => {
  let fixture: ComponentFixture<BreadcrumbComponent>;
  let component: BreadcrumbComponent;
  let router: Router;
  let dropdownCoordinator: DropdownCoordinatorService;

  beforeEach(async () => {
    TestBed.overrideComponent(BreadcrumbComponent, {
      set: {
        imports: [],
        template: '',
      },
    });

    await TestBed.configureTestingModule({
      imports: [BreadcrumbComponent],
      providers: [provideRouter([]), DropdownCoordinatorService, { provide: LayoutService, useClass: LayoutServiceMock }],
    }).compileComponents();

    fixture = TestBed.createComponent(BreadcrumbComponent);
    component = fixture.componentInstance;
    router = TestBed.inject(Router);
    dropdownCoordinator = TestBed.inject(DropdownCoordinatorService);
    fixture.detectChanges();
  });

  it('only allows navigation for non-current breadcrumbs with links', () => {
    expect(component.isCrumbClickable({ label: 'Dashboard', link: '/dashboard', isLast: false })).toBe(true);
    expect(component.isCrumbClickable({ label: 'Actual', link: '/actual', isLast: true })).toBe(false);
    expect(component.isCrumbClickable({ label: 'Grupo', isLast: false })).toBe(false);
  });

  it('closes open dropdowns before navigating to a breadcrumb link', () => {
    const navigateSpy = vi.spyOn(router, 'navigate').mockResolvedValue(true);
    const closeAllSpy = vi.spyOn(dropdownCoordinator, 'closeAll');

    component.navigateTo('/dashboard/overview');

    expect(closeAllSpy).toHaveBeenCalled();
    expect(navigateSpy).toHaveBeenCalledWith(['/dashboard/overview']);
  });
});
