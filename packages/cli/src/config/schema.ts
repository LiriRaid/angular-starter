import { z } from 'zod';

export const CONFIG_SCHEMA_VERSION = 1;

/** Every value the project plans to support. Availability is decided in `capabilities.ts`. */
export const ARCHITECTURES = [
  'angular-default',
  'screaming',
  'modular',
  'hexagonal',
  'clean',
  'feature-sliced',
] as const;
export const ROUTING = ['angular', 'starter'] as const;
export const STYLES = ['css', 'scss', 'sass', 'less'] as const;
export const RENDERING = ['csr', 'ssr', 'starter-ssr'] as const;
/** What the Starter SSR is for; `none` for every other rendering (ADR-0010). */
export const SSR_PURPOSES = ['none', 'landing', 'ecommerce', 'backoffice'] as const;
export const COMPONENTS = ['none', 'recommended', 'all', 'custom'] as const;
export const ICONS = [
  'none',
  'lucide',
  'heroicons',
  'phosphor',
  'tabler',
  'bootstrap-icons',
] as const;
export const PACKAGE_MANAGERS = ['npm', 'pnpm', 'yarn'] as const;
export const APP_SHELLS = ['none', 'starter'] as const;
export const PRESENCES = ['none', 'starter'] as const;
/** The layout modes of the application shell; `none` when the project has no shell. */
export const LAYOUTS = [
  'none',
  'wide-joined',
  'compact-joined',
  'floating-wide',
  'floating-compact',
  'transparent-joined',
  'transparent-floating',
] as const;
export const UI_SYSTEMS = ['none', 'starter'] as const;

/** Prefix reserved for the components distributed by Starter Angular. */
export const RESERVED_PREFIX = 'sa';

const prefixSchema = z
  .string()
  .regex(
    /^[a-z][a-z0-9]*(-[a-z0-9]+)*$/,
    'Use lowercase letters, numbers and hyphens, starting with a letter.',
  )
  .refine((value) => value !== RESERVED_PREFIX, {
    message: `The prefix "${RESERVED_PREFIX}" is reserved for Starter Angular components.`,
  });

export const optionsSchema = z.strictObject({
  architecture: z.enum(ARCHITECTURES),
  routing: z.enum(ROUTING),
  style: z.enum(STYLES),
  tailwind: z.boolean(),
  rendering: z.enum(RENDERING),
  ssrPurpose: z.enum(SSR_PURPOSES),
  appShell: z.enum(APP_SHELLS),
  layout: z.enum(LAYOUTS),
  presence: z.enum(PRESENCES),
  components: z.enum(COMPONENTS),
  /** The ids of a `custom` selection of components (ADR-0011); absent for every other choice. */
  componentList: z.array(z.string()).optional(),
  uiSystem: z.enum(UI_SYSTEMS),
  icons: z.enum(ICONS),
  packageManager: z.enum(PACKAGE_MANAGERS),
  prefix: prefixSchema,
  git: z.boolean(),
  install: z.boolean(),
});

export type StarterOptions = z.infer<typeof optionsSchema>;

/** Shape of the file accepted by `--config` and written to `starter-angular.config.json`. */
export const configFileSchema = z.strictObject({
  $schema: z.string().optional(),
  schemaVersion: z.literal(CONFIG_SCHEMA_VERSION).optional(),
  generator: z.strictObject({ cli: z.string(), angularCli: z.string() }).optional(),
  options: optionsSchema.partial().optional(),
});
