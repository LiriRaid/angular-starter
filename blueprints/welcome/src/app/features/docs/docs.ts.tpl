import { ChangeDetectionStrategy, Component, computed, inject } from '@angular/core';
import { toSignal } from '@angular/core/rxjs-interop';
import { ActivatedRoute, RouterLink, RouterLinkActive } from '@angular/router';
import { AsIcon } from '@shared/components';
import { DOC_PAGES, DOC_SECTIONS } from './docs.data';

/** The documentation of AS Starter inside the application: a side menu and the page that the route names. */
@Component({
  selector: '__PREFIX__-docs',
  imports: [AsIcon, RouterLink, RouterLinkActive],
  templateUrl: './docs.html',
  styleUrl: './docs.css',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class Docs {
  private readonly data = toSignal(inject(ActivatedRoute).data, { requireSync: true });

  protected readonly sections = DOC_SECTIONS;
  protected readonly page = computed(() => DOC_PAGES.find((candidate) => candidate.id === this.data()['page']) ?? DOC_PAGES[0]);
  private readonly index = computed(() => DOC_PAGES.indexOf(this.page()));
  protected readonly previous = computed(() => DOC_PAGES[this.index() - 1]);
  protected readonly next = computed(() => DOC_PAGES[this.index() + 1]);
}
