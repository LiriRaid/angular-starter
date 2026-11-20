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
export const COMPONENTS = ['none', 'recommended', 'all'] as const;
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

/** Prefix reserved for the components distributed by Angular Starter. */
export const RESERVED_PREFIX = 'as';

const prefixSchema = z
  .string()
  .regex(
    /^[a-z][a-z0-9]*(-[a-z0-9]+)*$/,
    'Use lowercase letters, numbers and hyphens, starting with a letter.',
  )
  .refine((value) => value !== RESERVED_PREFIX, {
    message: `The prefix "${RESERVED_PREFIX}" is reserved for Angular Starter components.`,
  });

export const optionsSchema = z.strictObject({
  architecture: z.enum(ARCHITECTURES),
  routing: z.enum(ROUTING),
  style: z.enum(STYLES),
  tailwind: z.boolean(),
  rendering: z.enum(RENDERING),
  appShell: z.enum(APP_SHELLS),
  components: z.enum(COMPONENTS),
  icons: z.enum(ICONS),
  packageManager: z.enum(PACKAGE_MANAGERS),
  prefix: prefixSchema,
  git: z.boolean(),
  install: z.boolean(),
});

export type StarterOptions = z.infer<typeof optionsSchema>;

/** Shape of the file accepted by `--config` and written to `angular-starter.config.json`. */
export const configFileSchema = z.strictObject({
  $schema: z.string().optional(),
  schemaVersion: z.literal(CONFIG_SCHEMA_VERSION).optional(),
  generator: z.strictObject({ cli: z.string(), angularCli: z.string() }).optional(),
  options: optionsSchema.partial().optional(),
});
