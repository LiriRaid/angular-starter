import { describe, expect, it } from 'vitest';
import { validateProjectName } from './project-name.js';

describe('validateProjectName', () => {
  it.each(['my-project', 'app', 'app1', 'my-app-2', 'a', 'InventorySystem', 'My-Project'])(
    'accepts %s',
    (name) => {
      expect(validateProjectName(name)).toBeUndefined();
    },
  );

  it.each([
    ['', 'required'],
    ['1app', 'letter'],
    ['my_app', 'letters'],
    ['my app', 'letters'],
    ['my--app', 'letters'],
    ['my-', 'letters'],
    ['-my', 'letters'],
    ['../escape', 'letters'],
  ])('rejects %j', (name, fragment) => {
    expect(validateProjectName(name)).toContain(fragment);
  });

  it('rejects Node.js core module names', () => {
    expect(validateProjectName('http')).toContain('reserved');
  });

  it('rejects names longer than 214 characters', () => {
    expect(validateProjectName('a'.repeat(215))).toContain('214');
  });
});
