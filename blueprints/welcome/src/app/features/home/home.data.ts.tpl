/** A card of the welcome page: `route` opens a page of this application, `href` an external page. */
export interface WelcomeCard {
  readonly id: string;
  readonly title: string;
  readonly description: string;
  /** Name of an icon registered in core/common/icons. */
  readonly icon: string;
  readonly route?: string;
  readonly href?: string;
  /** A file of this project that explains the piece, shown when the card has no link. */
  readonly docs?: string;
}

export interface WelcomeLink {
  readonly id: string;
  readonly label: string;
  readonly href: string;
}

/** The website of Starter Angular; until it exists, the repository is its home. */
export const STARTER_ANGULAR_URL = 'https://github.com/LiriRaid/starter-angular';

/** What to explore: the documentation of Starter Angular, and what this project brings. Edit it, or delete the page. */
export const WELCOME_CARDS: readonly WelcomeCard[] = [
  {
    id: 'starter-docs',
    title: 'Starter Angular documentation',
    description: 'Guides for this project: the structure, the design base, the components and the app shell.',
    icon: 'FileText',
    route: '/docs',
  },
  {
    id: 'starter-tutorials',
    title: 'Learn with tutorials',
    description: 'Add a page, use a component and change the theme, step by step, in this project.',
    icon: 'Lightbulb',
    route: '/docs/tutorials',
  },
  {
    id: 'design',
    title: 'Design base',
    description:
      'Tokens, light and dark theme, primary and surface colours and the animations. Try the colour picker and the theme switch in the header.',
    icon: 'Palette',
    docs: 'src/app/core/theme/README.md',
  },
  {
    id: 'components',
    title: 'Native components',
    description:
      'The sa- components of the reference application: buttons, inputs, tabs, popovers, tooltips and more, ready to import from @shared/components.',
    icon: 'Sparkles',
    docs: 'src/app/shared/components/README.md',
  },
  {
    id: 'app-shell',
    title: 'App shell',
    description:
      'A floating sidebar, the header and the breadcrumb, all reading one navigation tree. Add a page to navigation.data.ts and it shows up.',
    icon: 'LayoutGrid',
    docs: 'src/app/features/app-shell/README.md',
  },
  {
    id: 'examples',
    title: 'Example pages',
    description:
      'A dashboard, users, reports and settings to try the sidebar, the nested items and the breadcrumb before you replace them with your product.',
    icon: 'Table',
    route: '/dashboard',
  },
];

/** The links to Starter Angular. */
export const STARTER_LINKS: readonly WelcomeLink[] = [
  { id: 'docs', label: 'Documentation', href: `${STARTER_ANGULAR_URL}/tree/main/docs` },
  { id: 'adr', label: 'Architecture decisions', href: `${STARTER_ANGULAR_URL}/tree/main/docs/adr` },
  { id: 'source', label: 'Source code', href: STARTER_ANGULAR_URL },
];

export const SOCIAL_LINKS: readonly WelcomeLink[] = [
  { id: 'github', label: 'GitHub', href: STARTER_ANGULAR_URL },
];
