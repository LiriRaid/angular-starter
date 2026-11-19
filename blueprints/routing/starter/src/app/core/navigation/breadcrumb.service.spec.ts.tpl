import { Component } from '@angular/core';
import { TestBed } from '@angular/core/testing';
import { Router, provideRouter } from '@angular/router';
import { BreadcrumbService } from './breadcrumb.service';
import { NAV_TREE_TOKEN } from './navigation.tokens';
import type { NavigationGroup } from './navigation.types';

@Component({ template: '' })
class Page {}

const TREE: NavigationGroup[] = [
  { label: 'Admin', items: [{ id: 'users', title: 'Users', link: '/admin/users' }] },
];

describe('BreadcrumbService', () => {
  let service: BreadcrumbService;
  let router: Router;

  beforeEach(() => {
    TestBed.configureTestingModule({
      providers: [
        provideRouter([{ path: '**', component: Page }]),
        { provide: NAV_TREE_TOKEN, useValue: TREE },
        BreadcrumbService,
      ],
    });
    service = TestBed.inject(BreadcrumbService);
    router = TestBed.inject(Router);
  });

  const labels = () => service.breadcrumbs().map((crumb) => crumb.label);

  it('follows the navigation', async () => {
    await router.navigateByUrl('/admin/users');
    expect(labels()).toEqual(['Admin', 'Users']);
    await router.navigateByUrl('/reports');
    expect(labels()).toEqual(['Reports']);
  });

  it('adds a dynamic crumb and clears it on the next navigation', async () => {
    await router.navigateByUrl('/admin/users/42');
    service.setDynamicLabel('Ada');
    expect(labels()).toEqual(['Admin', 'Users', 'Ada']);

    await router.navigateByUrl('/admin/users');
    expect(labels()).toEqual(['Admin', 'Users']);
  });

  it('can clear the dynamic crumb by hand', async () => {
    await router.navigateByUrl('/admin/users/42');
    service.setDynamicCrumb({ label: 'Ada', icon: 'user' });
    service.clearDynamicLabel();
    expect(labels()).toEqual(['Admin', 'Users']);
  });
});
