import { runCommand, type CommandRunner } from './engine/process.js';
import { createInquirerPrompter, type Prompter } from './wizard/prompter.js';

/** Side-effecting collaborators, injectable so tests never spawn processes or draw prompts. */
export interface ProgramDeps {
  run: CommandRunner;
  prompter: Prompter;
  nodeVersion: string;
}

export function createDefaultDeps(): ProgramDeps {
  return {
    run: runCommand,
    prompter: createInquirerPrompter(),
    nodeVersion: process.versions.node,
  };
}
