import { rm } from 'node:fs/promises';
import { join } from 'node:path';
import { pathToFileURL } from 'node:url';
import { afterAll, beforeAll, describe, expect, it } from 'vitest';
import { loadBlueprintModule } from '../../../tests/helpers/blueprint-module.js';

/** The generated `core/presence/presence.protocol.ts`, compiled here as plain TypeScript. */
interface Protocol {
  parseServerMessage(raw: unknown): unknown;
  serializeChange(change: {
    status: string;
    auto?: boolean;
    durationMinutes?: number | null;
  }): string;
}

interface Types {
  PRESENCE_STATUSES: readonly string[];
  presenceStatusIcon(status: string | null | undefined): string | null;
}

let protocol: Protocol;
let types: Types;
let directory: string;

beforeAll(async () => {
  const loaded = await loadBlueprintModule<Protocol>(
    'presence',
    'src/app/core/presence',
    'presence.protocol.ts',
  );
  protocol = loaded.module;
  directory = loaded.directory;
  types = (await import(pathToFileURL(join(directory, 'presence.types.ts')).href)) as Types;
});

afterAll(async () => {
  await rm(directory, { recursive: true, force: true });
});

const parse = (message: unknown): unknown => protocol.parseServerMessage(JSON.stringify(message));

describe('presence wire protocol (server to client)', () => {
  it('reads the welcome that tells the client who it is', () => {
    expect(parse({ type: 'welcome', userId: 42 })).toEqual({ type: 'welcome', userId: '42' });
  });

  it('reads the snapshot the server sends on subscription', () => {
    expect(
      parse({
        type: 'presence:snapshot',
        payload: [
          { userId: 1, status: 'online' },
          { userId: 'b', status: 'busy' },
        ],
        timerRemainingSeconds: 900,
      }),
    ).toEqual({
      type: 'snapshot',
      users: [
        { userId: '1', status: 'online' },
        { userId: 'b', status: 'busy' },
      ],
      timerRemainingSeconds: 900,
    });
  });

  it('reads the update of one user, with or without a remaining time', () => {
    expect(parse({ type: 'presence', userId: 'a', status: 'away' })).toEqual({
      type: 'update',
      userId: 'a',
      status: 'away',
    });
    expect(
      parse({ type: 'presence', userId: 'a', status: 'busy', timerRemainingSeconds: 60 }),
    ).toEqual({ type: 'update', userId: 'a', status: 'busy', timerRemainingSeconds: 60 });
  });

  it('ignores a remaining time that is not a positive number', () => {
    for (const bad of [0, -1, 'soon', null, Number.NaN]) {
      expect(
        parse({ type: 'presence', userId: 'a', status: 'busy', timerRemainingSeconds: bad }),
      ).toEqual({ type: 'update', userId: 'a', status: 'busy' });
    }
  });

  it('drops the snapshot entries it does not understand and keeps the rest', () => {
    expect(
      parse({
        type: 'presence:snapshot',
        payload: [
          { userId: 'a', status: 'dancing' },
          { status: 'online' },
          null,
          { userId: 'b', status: 'online' },
        ],
      }),
    ).toEqual({ type: 'snapshot', users: [{ userId: 'b', status: 'online' }] });
  });

  it.each([
    ['not json', 'nope'],
    ['an array', '[]'],
    ['an unknown type', JSON.stringify({ type: 'conversation:new' })],
    ['an unknown status', JSON.stringify({ type: 'presence', userId: 'a', status: 'dancing' })],
    ['no user', JSON.stringify({ type: 'presence', status: 'online' })],
    ['a snapshot without a list', JSON.stringify({ type: 'presence:snapshot' })],
  ])('returns null for %s instead of throwing', (_name, raw) => {
    expect(protocol.parseServerMessage(raw)).toBeNull();
  });

  it('accepts a message that was already parsed', () => {
    expect(protocol.parseServerMessage({ type: 'welcome', userId: 'x' })).toEqual({
      type: 'welcome',
      userId: 'x',
    });
  });
});

describe('presence wire protocol (client to server)', () => {
  it('sends the manual status with its duration', () => {
    expect(
      JSON.parse(protocol.serializeChange({ status: 'busy', auto: false, durationMinutes: 15 })),
    ).toEqual({ type: 'presence:set', status: 'busy', durationMinutes: 15 });
  });

  it('marks the automatic away so the server does not keep it as a preference', () => {
    expect(JSON.parse(protocol.serializeChange({ status: 'away', auto: true }))).toEqual({
      type: 'presence:set',
      status: 'away',
      auto: true,
    });
  });

  it('leaves out the duration when there is none', () => {
    expect(
      JSON.parse(protocol.serializeChange({ status: 'online', durationMinutes: null })),
    ).toEqual({
      type: 'presence:set',
      status: 'online',
    });
  });
});

describe('presence statuses', () => {
  it('are the four of the reference, with an icon for each one that is not online', () => {
    expect(types.PRESENCE_STATUSES).toEqual(['online', 'away', 'busy', 'invisible']);
    expect(types.presenceStatusIcon('online')).toBeNull();
    expect(types.presenceStatusIcon('away')).toBe('Moon');
    expect(types.presenceStatusIcon('busy')).toBe('CircleMinus');
    expect(types.presenceStatusIcon('invisible')).toBe('CircleDot');
    expect(types.presenceStatusIcon(undefined)).toBeNull();
  });
});
