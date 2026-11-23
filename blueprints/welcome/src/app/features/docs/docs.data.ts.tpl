/** A piece of a documentation page. */
export type DocBlock =
  | { readonly kind: 'text'; readonly text: string }
  | { readonly kind: 'heading'; readonly text: string }
  | { readonly kind: 'list'; readonly items: readonly string[] }
  | { readonly kind: 'code'; readonly language: string; readonly code: string }
  | { readonly kind: 'note'; readonly text: string }
  | { readonly kind: 'steps'; readonly steps: readonly DocStep[] };

export interface DocStep {
  readonly title: string;
  readonly text: string;
  readonly code?: string;
}

export interface DocPage {
  readonly id: string;
  readonly title: string;
  /** Name of an icon registered in core/common/icons. */
  readonly icon: string;
  readonly summary: string;
  readonly blocks: readonly DocBlock[];
}

export interface DocSection {
  readonly label: string;
  readonly pages: readonly DocPage[];
}

const GETTING_STARTED: DocPage = {
  id: 'getting-started',
  title: 'Getting started',
  icon: 'Play',
  summary: 'What AS Starter generated for __PROJECT_NAME__ and how to work with it.',
  blocks: [
    {
      kind: 'text',
      text: 'This is a regular Angular application. AS Starter generated it and is not a dependency of it: nothing here talks to the CLI at runtime, and the official Angular CLI keeps working as usual.',
    },
    { kind: 'heading', text: 'Run it' },
    {
      kind: 'code',
      language: 'bash',
      code: 'ng serve   # the development server, with live reload\nng test    # the unit tests\nng build   # the production build',
    },
    { kind: 'heading', text: 'The structure' },
    {
      kind: 'text',
      text: 'The code follows the Screaming Architecture: the folders tell what the product does, not which Angular pieces it uses.',
    },
    {
      kind: 'list',
      items: [
        'src/app/core: what the whole application needs once (theme, icons, design preferences).',
        'src/app/shared: what several features reuse (the as- components, services, utilities).',
        'src/app/features: one folder per business capability, each with its own routes. The app shell, the home and the example pages live here.',
      ],
    },
    {
      kind: 'note',
      text: 'A feature imports from core and shared, never from another feature. Anything two features need moves to shared.',
    },
    { kind: 'heading', text: 'Keep going' },
    {
      kind: 'list',
      items: [
        'Follow the tutorials to add a page, use a component and change the theme.',
        'Every piece has a README next to it: src/app/core/theme/README.md, src/app/shared/components/README.md and src/app/features/app-shell/README.md.',
        'The decisions behind AS Starter are in its repository: github.com/LiriRaid/as-starter/tree/main/docs.',
      ],
    },
  ],
};

const DESIGN_BASE: DocPage = {
  id: 'design-base',
  title: 'Design base',
  icon: 'Palette',
  summary: 'Tokens, light and dark theme, colours and the design preferences page.',
  blocks: [
    {
      kind: 'text',
      text: 'The look of the application comes from CSS variables (tokens) written once in src/styles/theme/theme-styles.css. Components read the tokens and never hard-code a colour, so the light and dark themes and the primary colour change everything at once.',
    },
    { kind: 'heading', text: 'Use a token' },
    {
      kind: 'code',
      language: 'html',
      code: '<p class="text-(--app-text-subtle)">Secondary text</p>\n<div class="border border-(--app-border-color) bg-(--app-panel-bg)">A panel</div>',
    },
    { kind: 'heading', text: 'Try it' },
    {
      kind: 'list',
      items: [
        'The switch in the header toggles light and dark; the colour picker changes the primary colour.',
        'The user menu opens Preferencias de Diseño (/preference-design): layout, colours, radius, button size, density, font size and animations apply in real time and are kept with Guardar cambios.',
        'With the UI System option, the UI tab of that page lists every installed component with its variants and code.',
      ],
    },
    {
      kind: 'note',
      text: 'The ThemeService in src/app/core/theme keeps the theme and the palette. Read src/app/core/theme/README.md before adding a token.',
    },
  ],
};

const COMPONENTS: DocPage = {
  id: 'components',
  title: 'Native components',
  icon: 'Sparkles',
  summary: 'The as- components: buttons, fields, tabs, popovers, tooltips and more.',
  blocks: [
    {
      kind: 'text',
      text: 'The components are plain Angular code that lives in your project (src/app/shared/components), so you can read and change them. Import them from @shared/components.',
    },
    {
      kind: 'code',
      language: 'ts',
      code: "import { AsButton, AsInput } from '@shared/components';\n\n@Component({\n  imports: [AsButton, AsInput],\n  template: `\n    <as-input label=\"Name\" [formControl]=\"name\" />\n    <as-button label=\"Save\" icon=\"Check\" (onClick)=\"save()\" />\n  `,\n})\nexport class Profile {}",
    },
    { kind: 'heading', text: 'The three modes of a field' },
    {
      kind: 'text',
      text: 'as-input, as-textarea and as-select take variant="on" (the label sits on the border), "in" (inside, above the text) or "over" (above the field).',
    },
    { kind: 'heading', text: 'Add more' },
    {
      kind: 'code',
      language: 'bash',
      code: 'as add components',
    },
    {
      kind: 'note',
      text: 'src/app/shared/components/README.md lists the components this project has.',
    },
  ],
};

const APP_SHELL: DocPage = {
  id: 'app-shell',
  title: 'App shell',
  icon: 'LayoutGrid',
  summary: 'The sidebar, the header and the breadcrumb, all reading one navigation tree.',
  blocks: [
    {
      kind: 'text',
      text: 'The layout that frames every page lives in src/app/features/app-shell. The sidebar, the header and the breadcrumb read one tree, src/app/features/app-shell/navigation/navigation.data.ts: add a page there and it shows up with its title and its breadcrumb.',
    },
    {
      kind: 'code',
      language: 'ts',
      code: "{ id: 'products', title: 'Products', icon: 'Table', type: 'basic', link: '/products' },",
    },
    {
      kind: 'list',
      items: [
        'app.routes.ts loads every page inside the Main layout route. A page without the shell goes outside of it and loads Empty.',
        'An item can be hidden: it keeps its title and breadcrumb but the sidebar does not list it (the design preferences page is reached from the user menu this way).',
        'The user menu shows an example identity: replace it with the user of your session.',
      ],
    },
    {
      kind: 'note',
      text: 'The dashboard, users, reports and settings pages are examples to try the navigation. Replace them with your product.',
    },
  ],
};

const TUTORIALS: DocPage = {
  id: 'tutorials',
  title: 'Tutorials',
  icon: 'Lightbulb',
  summary: 'Three small tasks, step by step, with what this project already has.',
  blocks: [
    { kind: 'heading', text: 'Add a page' },
    {
      kind: 'steps',
      steps: [
        {
          title: 'Generate the feature',
          text: 'It creates the folder with its routes and adds the page to the navigation tree.',
          code: 'as generate feature products',
        },
        {
          title: 'Open it',
          text: 'Run the development server and click Products in the sidebar: the title and the breadcrumb are already there.',
          code: 'ng serve',
        },
        {
          title: 'Build the page',
          text: 'Edit src/app/features/products/products.html. Use the as- components and the tokens so the page follows the theme.',
        },
      ],
    },
    { kind: 'heading', text: 'Use a component' },
    {
      kind: 'steps',
      steps: [
        {
          title: 'Import it',
          text: 'Add it to the imports of your component.',
          code: "import { AsButton } from '@shared/components';",
        },
        {
          title: 'Use it in the template',
          text: 'Change variant, size or icon and watch the result.',
          code: '<as-button label="Create" icon="Plus" variant="outlined" />',
        },
        {
          title: 'See every variant',
          text: 'With the UI System option, open Preferencias de Diseño, tab UI: each component shows its variants and the code of the one you pick.',
        },
      ],
    },
    { kind: 'heading', text: 'Change the theme' },
    {
      kind: 'steps',
      steps: [
        {
          title: 'Try it live',
          text: 'Use the colour picker and the light and dark switch in the header, or open Preferencias de Diseño from the user menu.',
        },
        {
          title: 'Make it yours',
          text: 'Edit the tokens in src/styles/theme/theme-styles.css. Every component reads them, so there is nothing else to change.',
        },
      ],
    },
  ],
};

/** The pages of the documentation, in the order of the side menu. */
export const DOC_SECTIONS: readonly DocSection[] = [
  { label: 'Documentation', pages: [GETTING_STARTED, DESIGN_BASE, COMPONENTS, APP_SHELL] },
  { label: 'Learn', pages: [TUTORIALS] },
];

export const DOC_PAGES: readonly DocPage[] = DOC_SECTIONS.flatMap((section) => section.pages);
