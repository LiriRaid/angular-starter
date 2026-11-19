import type { CliIo } from '../../src/io.js';

export interface FakeIo {
  io: CliIo;
  out(): string;
  err(): string;
}

export function createFakeIo(overrides: Partial<CliIo> = {}): FakeIo {
  let out = '';
  let err = '';
  const io: CliIo = {
    stdout: (text) => {
      out += text;
    },
    stderr: (text) => {
      err += text;
    },
    cwd: process.cwd(),
    env: {},
    interactive: false,
    color: false,
    ...overrides,
  };
  return { io, out: () => out, err: () => err };
}
