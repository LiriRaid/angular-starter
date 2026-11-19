import { mkdtemp, rm, writeFile } from 'node:fs/promises';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { afterEach, beforeEach, describe, expect, it } from 'vitest';
import { UsageError } from '../errors.js';
import { readConfigFile } from './file.js';
import { createProjectConfig, serializeProjectConfig } from './project-config.js';
import { DEFAULT_OPTIONS } from './resolve.js';

let dir: string;

beforeEach(async () => {
  dir = await mkdtemp(join(tmpdir(), 'as-config-'));
});

afterEach(async () => {
  await rm(dir, { recursive: true, force: true });
});

async function write(name: string, content: string): Promise<string> {
  const path = join(dir, name);
  await writeFile(path, content);
  return path;
}

describe('readConfigFile', () => {
  it('reads partial options', async () => {
    const path = await write(
      'a.json',
      JSON.stringify({ schemaVersion: 1, options: { style: 'less' } }),
    );
    expect(await readConfigFile(path, dir)).toEqual({ style: 'less' });
  });

  it('resolves relative paths against the given directory', async () => {
    await write('b.json', JSON.stringify({ options: { prefix: 'acme' } }));
    expect(await readConfigFile('b.json', dir)).toEqual({ prefix: 'acme' });
  });

  it('returns no options when the file has none', async () => {
    const path = await write('c.json', '{}');
    expect(await readConfigFile(path, dir)).toEqual({});
  });

  it('fails clearly when the file does not exist', async () => {
    await expect(readConfigFile(join(dir, 'missing.json'), dir)).rejects.toThrow(UsageError);
  });

  it('fails clearly on invalid JSON', async () => {
    const path = await write('d.json', '{ nope');
    await expect(readConfigFile(path, dir)).rejects.toThrow(/not valid JSON/);
  });

  it('rejects unknown keys', async () => {
    const path = await write('e.json', JSON.stringify({ options: { color: 'red' } }));
    await expect(readConfigFile(path, dir)).rejects.toThrow(UsageError);
  });

  it('rejects an unsupported schema version', async () => {
    const path = await write('f.json', JSON.stringify({ schemaVersion: 2 }));
    await expect(readConfigFile(path, dir)).rejects.toThrow(/schemaVersion/);
  });
});

describe('project config', () => {
  const generator = { cli: '0.0.0', angularCli: '22.3.0' };

  it('has the documented shape and no secrets', () => {
    const config = createProjectConfig(DEFAULT_OPTIONS, generator);
    expect(config).toEqual({ schemaVersion: 1, generator, options: DEFAULT_OPTIONS });
  });

  it('round-trips through readConfigFile', async () => {
    const path = await write(
      'g.json',
      serializeProjectConfig(createProjectConfig(DEFAULT_OPTIONS, generator)),
    );
    expect(await readConfigFile(path, dir)).toEqual(DEFAULT_OPTIONS);
  });

  it('serializes with two-space indentation and a trailing newline', () => {
    const text = serializeProjectConfig(createProjectConfig(DEFAULT_OPTIONS, generator));
    expect(text.endsWith('}\n')).toBe(true);
    expect(text).toContain('\n  "schemaVersion": 1');
  });
});
