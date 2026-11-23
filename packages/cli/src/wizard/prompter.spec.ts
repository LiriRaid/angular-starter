import { beforeEach, describe, expect, it, vi } from 'vitest';

const prompts = vi.hoisted(() => ({
  input: vi.fn(),
  select: vi.fn(),
  checkbox: vi.fn(),
  confirm: vi.fn(),
}));
vi.mock('@inquirer/prompts', () => prompts);

import { createInquirerPrompter } from './prompter.js';

beforeEach(() => {
  vi.clearAllMocks();
});

describe('createInquirerPrompter', () => {
  it('trims the answer and turns validate() into inquirer semantics', async () => {
    prompts.input.mockResolvedValue('  my-app  ');
    const answer = await createInquirerPrompter().input({
      name: 'projectName',
      message: 'Project name:',
      validate: (value) => (value === 'bad' ? 'nope' : undefined),
    });

    expect(answer).toBe('my-app');
    const { validate } = prompts.input.mock.calls[0]?.[0] as { validate: (v: string) => unknown };
    expect(validate(' ok ')).toBe(true);
    expect(validate('bad')).toBe('nope');
  });

  it('accepts any value when there is no validator', async () => {
    prompts.input.mockResolvedValue('x');
    await createInquirerPrompter().input({ name: 'a', message: 'a' });
    const { validate } = prompts.input.mock.calls[0]?.[0] as { validate: (v: string) => unknown };
    expect(validate('anything')).toBe(true);
  });

  it('maps the choices of a checkbox with what starts ticked, and returns what was ticked', async () => {
    prompts.checkbox.mockResolvedValue(['button']);
    const answer = await createInquirerPrompter().checkbox({
      name: 'componentList',
      message: 'Which components?',
      choices: [
        { value: 'button', name: 'button', checked: true },
        { value: 'modal', name: 'modal', description: 'Dialog' },
      ],
    });

    expect(answer).toEqual(['button']);
    expect(prompts.checkbox).toHaveBeenCalledWith(
      {
        message: 'Which components?',
        choices: [
          { value: 'button', name: 'button', description: undefined, checked: true },
          { value: 'modal', name: 'modal', description: 'Dialog', checked: false },
        ],
        pageSize: 14,
      },
      {},
    );
  });

  it('maps choices and the default for select', async () => {
    prompts.select.mockResolvedValue('scss');
    const answer = await createInquirerPrompter().select({
      name: 'style',
      message: 'Select a stylesheet format:',
      default: 'css',
      choices: [
        { value: 'css', name: 'CSS' },
        { value: 'scss', name: 'SCSS', description: 'Sass' },
      ],
    });

    expect(answer).toBe('scss');
    expect(prompts.select).toHaveBeenCalledWith(
      {
        message: 'Select a stylesheet format:',
        default: 'css',
        choices: [
          { value: 'css', name: 'CSS', description: undefined },
          { value: 'scss', name: 'SCSS', description: 'Sass' },
        ],
      },
      {},
    );
  });

  it('forwards confirm questions', async () => {
    prompts.confirm.mockResolvedValue(false);
    expect(
      await createInquirerPrompter().confirm({ name: 'c', message: 'Sure?', default: true }),
    ).toBe(false);
    expect(prompts.confirm).toHaveBeenCalledWith({ message: 'Sure?', default: true }, {});
  });
});
