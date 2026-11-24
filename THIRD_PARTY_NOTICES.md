# Third-Party Notices

This repository does not yet redistribute any third-party source code.

When dependencies are bundled, vendored or copied into generated output, their copyright notices and license texts will be listed here. The licenses of every planned dependency (for example Angular, Angular CLI and DevKit, Tailwind CSS, Sass and the supported icon libraries) are to be verified against their official sources before any public release.

No code, assets or configuration from private or employer projects is included in this repository.

## Runtime dependencies of the CLI

Installed from npm, not vendored. Each keeps its own license:

- `ts-morph` (MIT), which bundles the TypeScript compiler (Apache-2.0)
- `jsonc-parser` (MIT)
- `commander`, `@inquirer/prompts`, `execa` and `zod` (MIT)

## Vendored assets in generated projects

- `public/assets/flags-sprite.svg`, written with the `sa-input` component: the country flags of
  [flag-icons](https://github.com/lipis/flag-icons) (MIT, Copyright (c) 2013 Panayiotis Lipiridis)
  as one SVG sprite. The phone country picker of the input draws them.
