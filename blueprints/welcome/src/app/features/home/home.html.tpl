<div class="home mx-auto flex w-full max-w-5xl flex-col gap-10 py-6">
  <header class="flex flex-col items-center gap-4 text-center">
    <svg class="size-16" viewBox="0 0 64 64" role="img" aria-label="Angular Starter">
      <rect width="64" height="64" rx="16" fill="var(--as-primary-color)" />
      <text x="32" y="42" text-anchor="middle" font-size="26" font-weight="700" font-family="Inter, sans-serif" fill="var(--as-primary-contrast-color)">AS</text>
    </svg>
    <div class="flex flex-col gap-1">
      <h1 class="text-tittle-4-bold text-(--app-text-color)">{{ projectName() }}</h1>
      <p class="text-body-2-regular text-(--app-text-subtle)">Your application is up and running, built with Angular Starter.</p>
    </div>
  </header>

  <section class="flex flex-col gap-4" aria-labelledby="home-explore">
    <h2 id="home-explore" class="text-body-1-bold text-(--app-text-color)">Explore</h2>
    <div class="grid gap-4 sm:grid-cols-2 xl:grid-cols-3">
      @for (card of cards; track card.id) {
        <article class="home-card flex flex-col gap-3 rounded-xl border border-(--app-border-color) p-4" [attr.data-card]="card.id">
          <span class="flex size-11 shrink-0 items-center justify-center rounded-lg bg-(--app-badge-soft-bg) text-(--app-badge-soft-text)">
            <as-icon [name]="card.icon" size="22" />
          </span>
          <div class="flex flex-1 flex-col gap-1">
            <h3 class="text-body-2-bold text-(--app-text-color)">{{ card.title }}</h3>
            <p class="text-caption-1-regular text-(--app-text-subtle)">{{ card.description }}</p>
          </div>
          @if (card.route) {
            <a class="home-link text-caption-1-semibold flex items-center gap-1 text-(--app-text-primary)" [routerLink]="card.route">
              Open <as-icon name="ArrowRight" size="14" />
            </a>
          } @else if (card.href) {
            <a class="home-link text-caption-1-semibold flex items-center gap-1 text-(--app-text-primary)" [href]="card.href" target="_blank" rel="noopener noreferrer">
              Open <as-icon name="ArrowUpRight" size="14" />
            </a>
          } @else if (card.docs) {
            <p class="text-caption-2-regular text-(--app-text-subtle)">Read <code>{{ card.docs }}</code></p>
          }
        </article>
      }
    </div>
  </section>

  <section class="flex flex-col gap-4 rounded-xl border border-(--app-border-color) p-4 sm:flex-row sm:items-center sm:justify-between" aria-labelledby="home-starter">
    <div class="flex flex-col gap-1">
      <h2 id="home-starter" class="text-body-2-bold text-(--app-text-color)">Angular Starter</h2>
      <p class="text-caption-1-regular text-(--app-text-subtle)">The CLI that generated this project: documentation, architecture decisions and source code.</p>
    </div>
    <nav class="flex flex-wrap gap-4" aria-label="Angular Starter">
      @for (link of starterLinks; track link.id) {
        <a class="home-link text-caption-1-semibold flex items-center gap-1 text-(--app-text-primary)" [href]="link.href" target="_blank" rel="noopener noreferrer">
          {{ link.label }} <as-icon name="ArrowUpRight" size="14" />
        </a>
      }
    </nav>
  </section>

  <footer class="flex items-center justify-center gap-3 border-t border-(--app-border-color) pt-6">
    @for (link of socialLinks; track link.id) {
      <a class="home-social flex size-10 items-center justify-center rounded-full text-(--app-text-subtle)" [href]="link.href" target="_blank" rel="noopener noreferrer" [attr.aria-label]="link.label">
        <svg class="size-5 fill-current" viewBox="0 0 24 24" aria-hidden="true">
          <path d="M12 .297c-6.63 0-12 5.373-12 12 0 5.303 3.438 9.8 8.205 11.385.6.113.82-.258.82-.577 0-.285-.01-1.04-.015-2.04-3.338.724-4.042-1.61-4.042-1.61C4.422 18.07 3.633 17.7 3.633 17.7c-1.087-.744.084-.729.084-.729 1.205.084 1.838 1.236 1.838 1.236 1.07 1.835 2.809 1.305 3.495.998.108-.776.417-1.305.76-1.605-2.665-.3-5.466-1.332-5.466-5.93 0-1.31.465-2.38 1.235-3.22-.135-.303-.54-1.523.105-3.176 0 0 1.005-.322 3.3 1.23.96-.267 1.98-.399 3-.405 1.02.006 2.04.138 3 .405 2.28-1.552 3.285-1.23 3.285-1.23.645 1.653.24 2.873.12 3.176.765.84 1.23 1.91 1.23 3.22 0 4.61-2.805 5.625-5.475 5.92.42.36.81 1.096.81 2.22 0 1.606-.015 2.896-.015 3.286 0 .315.21.69.825.57C20.565 22.092 24 17.592 24 12.297c0-6.627-5.373-12-12-12" />
        </svg>
      </a>
    }
  </footer>
</div>
