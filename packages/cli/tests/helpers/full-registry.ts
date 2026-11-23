import {
  CAPABILITIES,
  type CapabilityOption,
  type Registry,
} from '../../src/config/capabilities.js';

/** Options that are listed but cannot be generated yet. */
const PLANNED = new Set([
  'modular',
  'hexagonal',
  'clean',
  'feature-sliced',
  'heroicons',
  'phosphor',
  'tabler',
  'bootstrap-icons',
  'landing',
  'ecommerce',
  'wide-joined',
  'compact-joined',
  'floating-compact',
  'transparent-joined',
  'transparent-floating',
]);

/** Every option the project plans to generate today and in the near future, whatever `available` says. */
export const FULL: Registry = Object.fromEntries(
  Object.entries(CAPABILITIES).map(([category, options]) => [
    category,
    options.map((option: CapabilityOption) => ({ ...option, available: !PLANNED.has(option.id) })),
  ]),
) as unknown as Registry;
