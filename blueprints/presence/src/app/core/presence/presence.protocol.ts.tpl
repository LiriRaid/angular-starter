import { isPresenceStatus } from './presence.types';
import type { PresenceChange, PresenceEvent, PresenceUser } from './presence.types';

/**
 * The JSON messages of the WebSocket transport (docs/presence.md describes them for the server).
 *
 * Server to client:
 *   { "type": "welcome", "userId": "42" }
 *   { "type": "presence:snapshot", "payload": [{ "userId": "42", "status": "online" }], "timerRemainingSeconds": 900 }
 *   { "type": "presence", "userId": "42", "status": "away", "timerRemainingSeconds": 900 }
 *
 * Client to server:
 *   { "type": "presence:set", "status": "busy", "auto": true, "durationMinutes": 15 }
 */

type Message = Record<string, unknown>;

const isRecord = (value: unknown): value is Message =>
  typeof value === 'object' && value !== null && !Array.isArray(value);

function parseJson(text: string): unknown {
  try {
    return JSON.parse(text);
  } catch {
    return null;
  }
}

/** An id as the server sends it, a string or a number, always as a string. */
function idOf(value: unknown): string | null {
  if (typeof value === 'string' && value !== '') return value;
  return typeof value === 'number' && Number.isFinite(value) ? String(value) : null;
}

function userOf(entry: unknown): PresenceUser | null {
  if (!isRecord(entry)) return null;
  const userId = idOf(entry['userId']);
  const status = entry['status'];
  return userId !== null && isPresenceStatus(status) ? { userId, status } : null;
}

/** The time left of a duration, when the server sends a positive number. */
function remainingOf(message: Message): { timerRemainingSeconds?: number } {
  const value = message['timerRemainingSeconds'];
  return typeof value === 'number' && Number.isFinite(value) && value > 0
    ? { timerRemainingSeconds: value }
    : {};
}

/**
 * Reads one message of the server. Anything that is not a valid presence message (another kind of
 * event, a broken frame, an unknown status) is `null`: a socket shared with other features is fine.
 */
export function parseServerMessage(raw: unknown): PresenceEvent | null {
  const message = typeof raw === 'string' ? parseJson(raw) : raw;
  if (!isRecord(message)) return null;

  switch (message['type']) {
    case 'welcome': {
      const userId = idOf(message['userId']);
      return userId === null ? null : { type: 'welcome', userId };
    }
    case 'presence:snapshot': {
      const payload = message['payload'];
      if (!Array.isArray(payload)) return null;
      const users = payload.flatMap((entry) => userOf(entry) ?? []);
      return { type: 'snapshot', users, ...remainingOf(message) };
    }
    case 'presence': {
      const user = userOf(message);
      return user === null ? null : { type: 'update', ...user, ...remainingOf(message) };
    }
    default:
      return null;
  }
}

/** The message that tells the server the new status of this client. */
export function serializeChange(change: PresenceChange): string {
  return JSON.stringify({
    type: 'presence:set',
    status: change.status,
    ...(change.auto ? { auto: true } : {}),
    ...(change.durationMinutes ? { durationMinutes: change.durationMinutes } : {}),
  });
}
