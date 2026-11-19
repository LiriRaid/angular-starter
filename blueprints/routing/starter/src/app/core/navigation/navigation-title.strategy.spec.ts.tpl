import { Component } from '@angular/core';
import { TestBed } from '@angular/core/testing';
import { Meta, Title } from '@angular/platform-browser';
import { Router, provideRouter } from '@angular/router';
import { provideNavigation } from './navigation.providers';
import type { NavigationGroup } from './navigation.types';

@Component({ template: '' })
class Page {}

const TREE: NavigationGroup[] = [
  {
    label: 'General',
    items: [{ id: 'home', title: 'Home', link: '/home', description: 'The start page' }],
  },
];

describe('NavigationTitleStrategy', () => {
  beforeEach(() => {
    TestBed.configureTestingModule({
      providers: [
        provideRouter([
          { path: 'home', component: Page, title: 'Route title' },
          { path: 'other', component: Page, title: 'Other page' },
          { path: 'untitled', component: Page },
        ]),
        provideNavigation(TREE, { appName: 'Demo' }),
      ],
    });
  });

  async function visit(url: string): Promise<{ title: string; description: string | undefined }> {
    await TestBed.inject(Router).navigateByUrl(url);
    return {
      title: TestBed.inject(Title).getTitle(),
      description: TestBed.inject(Meta).getTag('name=description')?.content,
    };
  }

  it('uses the title and the description of the navigation item first', async () => {
    expect(await visit('/home')).toEqual({ title: 'Home | Demo', description: 'The start page' });
  });

  it('falls back to the title of the route', async () => {
    expect(await visit('/other')).toEqual({
      title: 'Other page | Demo',
      description: 'Demo - Other page',
    });
  });

  it('falls back to the app name', async () => {
    expect(await visit('/untitled')).toEqual({ title: 'Demo', description: 'Demo' });
  });
});
