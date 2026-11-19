import { describe, expect, it } from 'vitest';
import { validateProjectName } from './project-name.js';

describe('validateProjectName', () => {
  it.each(['my-project', 'app', 'app1', 'my-app-2', 'a'])('accepts %s', (name) => {
    expect(validateProjectName(name)).toBeUndefined();
  });

  it.each([
    ['', 'required'],
    ['My-Project', 'lowercase'],
    ['1app', 'letter'],
    ['my_app', 'lowercase'],
    ['my app', 'lowercase'],
    ['my--app', 'lowercase'],
    ['my-', 'lowercase'],
    ['-my', 'lowercase'],
    ['../escape', 'lowercase'],
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
