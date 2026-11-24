import { TestBed } from '@angular/core/testing';
import { provideRouter } from '@angular/router';
import { Home } from './home';
import { SOCIAL_LINKS, WELCOME_CARDS } from './home.data';

describe('Home', () => {
  let compiled: HTMLElement;

  beforeEach(async () => {
    await TestBed.configureTestingModule({
      imports: [Home],
      providers: [provideRouter([])],
    }).compileComponents();

    const fixture = TestBed.createComponent(Home);
    await fixture.whenStable();
    compiled = fixture.nativeElement as HTMLElement;
  });

  it('should show the project name', () => {
    expect(compiled.querySelector('h1')?.textContent).toContain('__PROJECT_NAME__');
  });

  it('shows a card for each entry of the list', () => {
    expect(compiled.querySelectorAll('article').length).toBe(WELCOME_CARDS.length);
    expect(WELCOME_CARDS.map((card) => card.id)).toContain('starter-docs');
  });

  it('opens the pages of the application with the router and the others in a new tab', () => {
    const internal = compiled.querySelector('[data-card="examples"] a');
    expect(internal?.getAttribute('href')).toBe('/dashboard');
    const external = compiled.querySelector('footer a[aria-label="GitHub"]');
    expect(external?.getAttribute('target')).toBe('_blank');
    expect(external?.getAttribute('rel')).toContain('noopener');
  });

  it('sends the documentation and the tutorials to the pages of Angular Starter, not to Angular', () => {
    expect(compiled.querySelector('[data-card="starter-docs"] a')?.getAttribute('href')).toBe('/docs');
    expect(compiled.querySelector('[data-card="starter-tutorials"] a')?.getAttribute('href')).toBe('/docs/tutorials');
    const hrefs = Array.from(compiled.querySelectorAll('a')).map((link) => link.getAttribute('href') ?? '');
    expect(hrefs.some((href) => href.includes('angular.dev'))).toBe(false);
  });

  it('links to Angular Starter and to its GitHub repository', () => {
    const hrefs = Array.from(compiled.querySelectorAll('a')).map((link) => link.getAttribute('href'));
    expect(hrefs).toContain('https://github.com/LiriRaid/angular-starter');
    expect(SOCIAL_LINKS.map((link) => link.id)).toEqual(['github']);
    expect(compiled.querySelector('footer a[aria-label="GitHub"]')).not.toBeNull();
  });
});
