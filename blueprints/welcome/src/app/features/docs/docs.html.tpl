<div class="docs mx-auto flex w-full max-w-6xl flex-col gap-8 py-6 lg:flex-row">
  <nav class="flex shrink-0 flex-col gap-5 lg:w-60" aria-label="Documentation">
    @for (section of sections; track section.label) {
      <div class="flex flex-col gap-1">
        <h2 class="px-3 text-caption-2-semibold tracking-wide text-(--app-text-subtle) uppercase">{{ section.label }}</h2>
        @for (item of section.pages; track item.id) {
          <a class="docs-link text-caption-1-medium flex items-center gap-2 rounded-lg px-3 py-2 text-(--app-text-color)" [routerLink]="['/docs', item.id]" routerLinkActive="docs-link--active" [attr.data-link]="item.id">
            <sa-icon [name]="item.icon" size="16" />
            {{ item.title }}
          </a>
        }
      </div>
    }
  </nav>

  <article class="flex min-w-0 flex-1 flex-col gap-5" [attr.data-page]="page().id">
    <header class="flex flex-col gap-1">
      <h1 class="text-tittle-4-bold text-(--app-text-color)">{{ page().title }}</h1>
      <p class="text-body-2-regular text-(--app-text-subtle)">{{ page().summary }}</p>
    </header>

    @for (block of page().blocks; track $index) {
      @switch (block.kind) {
        @case ('heading') {
          <h2 class="pt-2 text-body-1-bold text-(--app-text-color)">{{ block.text }}</h2>
        }
        @case ('text') {
          <p class="text-body-2-regular text-(--app-text-color)">{{ block.text }}</p>
        }
        @case ('list') {
          <ul class="flex list-disc flex-col gap-1.5 pl-5 text-body-2-regular text-(--app-text-color)">
            @for (item of block.items; track item) {
              <li>{{ item }}</li>
            }
          </ul>
        }
        @case ('code') {
          <pre class="docs-code overflow-x-auto rounded-lg border border-(--app-border-color) p-3 text-caption-1-regular text-(--app-text-color)"><code [attr.data-language]="block.language">{{ block.code }}</code></pre>
        }
        @case ('note') {
          <p class="rounded-lg border border-(--app-border-color) bg-(--app-badge-soft-bg) p-3 text-caption-1-regular text-(--app-text-color)">{{ block.text }}</p>
        }
        @case ('steps') {
          <ol class="flex flex-col gap-3">
            @for (step of block.steps; track step.title; let number = $index) {
              <li class="flex gap-3 rounded-xl border border-(--app-border-color) p-4">
                <span class="flex size-7 shrink-0 items-center justify-center rounded-full bg-(--app-badge-soft-bg) text-caption-1-bold text-(--app-badge-soft-text)">{{ number + 1 }}</span>
                <div class="flex min-w-0 flex-1 flex-col gap-2">
                  <h3 class="text-body-2-bold text-(--app-text-color)">{{ step.title }}</h3>
                  <p class="text-caption-1-regular text-(--app-text-subtle)">{{ step.text }}</p>
                  @if (step.code) {
                    <pre class="docs-code overflow-x-auto rounded-lg border border-(--app-border-color) p-3 text-caption-1-regular text-(--app-text-color)"><code>{{ step.code }}</code></pre>
                  }
                </div>
              </li>
            }
          </ol>
        }
      }
    }

    <footer class="flex items-center justify-between gap-3 border-t border-(--app-border-color) pt-4">
      @if (previous(); as before) {
        <a class="docs-prev text-caption-1-semibold flex items-center gap-1 text-(--app-text-primary) hover:underline" [routerLink]="['/docs', before.id]">
          <sa-icon name="ArrowLeft" size="14" /> {{ before.title }}
        </a>
      } @else {
        <span></span>
      }
      @if (next(); as after) {
        <a class="docs-next text-caption-1-semibold flex items-center gap-1 text-(--app-text-primary) hover:underline" [routerLink]="['/docs', after.id]">
          {{ after.title }} <sa-icon name="ArrowRight" size="14" />
        </a>
      }
    </footer>
  </article>
</div>
