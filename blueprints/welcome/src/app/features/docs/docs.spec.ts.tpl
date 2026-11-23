import { TestBed } from '@angular/core/testing';
import { provideRouter, Router } from '@angular/router';
import { RouterTestingHarness } from '@angular/router/testing';
import { DOC_PAGES, DOC_SECTIONS } from './docs.data';
import { DOCS_ROUTES } from './docs.routes';

describe('Docs', () => {
  /** A router with the documentation, and a way to open one of its pages and get what is drawn. */
  const setup = async () => {
    TestBed.configureTestingModule({ providers: [provideRouter([{ path: 'docs', children: DOCS_ROUTES }])] });
    const harness = await RouterTestingHarness.create();
    const open = async (url: string): Promise<HTMLElement> => {
      await harness.navigateByUrl(url);
      harness.detectChanges();
      return harness.routeNativeElement as HTMLElement;
    };
    return { open };
  };

  it('opens the first page at /docs', async () => {
    const { open } = await setup();
    const page = await open('/docs');
    expect(TestBed.inject(Router).url).toBe('/docs/getting-started');
    expect(page.querySelector('h1')?.textContent).toContain('Getting started');
  });

  it('draws the page that the route names, for every page', async () => {
    const { open } = await setup();
    for (const doc of DOC_PAGES) {
      const page = await open(`/docs/${doc.id}`);
      expect(page.querySelector('h1')?.textContent, doc.id).toContain(doc.title);
      expect(page.querySelector(`[data-page="${doc.id}"]`), doc.id).not.toBeNull();
    }
  });

  it('lists every page in the side menu and marks the one that is open', async () => {
    const { open } = await setup();
    const page = await open('/docs/components');
    const links = Array.from(page.querySelectorAll('nav [data-link]'));
    expect(links.map((link) => link.getAttribute('data-link'))).toEqual(DOC_PAGES.map((doc) => doc.id));
    expect(links.filter((link) => link.classList.contains('docs-link--active')).map((link) => link.getAttribute('data-link'))).toEqual(['components']);
    expect(Array.from(page.querySelectorAll('nav h2')).map((heading) => heading.textContent?.trim())).toEqual(DOC_SECTIONS.map((section) => section.label));
  });

  it('shows the tutorials as numbered steps with their code', async () => {
    const { open } = await setup();
    const page = await open('/docs/tutorials');
    const steps = page.querySelectorAll('ol > li');
    expect(steps.length).toBeGreaterThan(3);
    expect(steps[0].textContent).toContain('1');
    expect(page.textContent).toContain('as generate feature products');
    expect(page.querySelectorAll('pre code').length).toBeGreaterThan(0);
  });

  it('goes to the previous and the next page from the foot of the page', async () => {
    const { open } = await setup();
    const middle = await open('/docs/design-base');
    expect(middle.querySelector('.docs-prev')?.textContent).toContain('Getting started');
    expect(middle.querySelector('.docs-next')?.textContent).toContain('Native components');

    const first = await open('/docs/getting-started');
    expect(first.querySelector('.docs-prev')).toBeNull();
  });

  it('talks about AS Starter and this project, not about Angular links', async () => {
    const { open } = await setup();
    const page = await open('/docs/getting-started');
    expect(page.textContent).toContain('AS Starter');
    expect(page.textContent).toContain('__PROJECT_NAME__');
    const hrefs = Array.from(page.querySelectorAll('a')).map((link) => link.getAttribute('href') ?? '');
    expect(hrefs.some((href) => href.includes('angular.dev'))).toBe(false);
  });
});
