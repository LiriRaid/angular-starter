import type { StarterOptions } from '../config/schema.js';
import type { ProgramDeps } from '../deps.js';
import { CliError, RuntimeError } from '../errors.js';
import { println, type CliIo } from '../io.js';
import { createStyler } from '../ui/format.js';

export interface GenerationContext {
  name: string;
  options: StarterOptions;
  cwd: string;
  targetDir: string;
  io: CliIo;
  deps: ProgramDeps;
  verbose: boolean;
  /** Non-fatal problems, shown after the success message. */
  warnings: string[];
  /** True once the project folder has been created by this run. */
  created: boolean;
}

export interface Stage {
  id: string;
  /** Shown as `✓ <title>` when the stage succeeds. */
  title: string;
  /** Shown before the stage runs, for stages that take a while and print nothing meanwhile. */
  pending?: string;
  /** Stages that return false are neither run nor reported. */
  enabled?(context: GenerationContext): boolean;
  run(context: GenerationContext): Promise<void>;
}

/** Runs the stages in order and stops at the first failure; it never reports success on failure. */
export async function runPipeline(
  stages: readonly Stage[],
  context: GenerationContext,
): Promise<void> {
  const style = createStyler(context.io.color);
  for (const stage of stages) {
    if (stage.enabled && !stage.enabled(context)) continue;
    if (stage.pending) {
      println(context.io.stdout, `${style.dim('…')} ${stage.title} (${stage.pending})`);
    }
    try {
      await stage.run(context);
      println(context.io.stdout, `${style.green('✓')} ${stage.title}`);
    } catch (error) {
      println(context.io.stdout, `${style.red('✗')} ${stage.title}`);
      if (error instanceof CliError) throw error;
      const reason = error instanceof Error ? error.message : String(error);
      throw new RuntimeError(`${stage.title} failed: ${reason}`);
    }
  }
}
