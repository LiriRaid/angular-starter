# ADR-0013: The wizard can go back and change a previous answer

- Status: accepted
- Date: 2026-11-21
- Deciders: project maintainer

## Context

The wizard of `as new` is a chain (ADR-0010, ADR-0011): each answer decides which questions come next,
and a choice can set another one (the shell and the components imply Lucide Icons). After picking the
essential collection and seeing the list of components, the maintainer could not change the collection:
the only way out of a wrong answer was Ctrl+C and starting again. `@inquirer/prompts` 8 (core 12) has no
"back" in any prompt, but every prompt takes an `AbortSignal` that rejects it with `AbortPromptError`,
and `select` and `checkbox` build their help line through `theme.style.keysHelpTip`; `input` and
`confirm` have no help line, but their message goes through `theme.style.message`.

## Decision

1. **Esc goes back, in the four kinds of prompt.** The prompter listens to the Esc key while a question
   is open, aborts it and throws `BackRequested`. The question shows it: `esc back` in the help line of
   `select` and `checkbox`, a dim `(esc to go back)` after the message of `input` and `confirm` (only
   while it is open, so the answered line stays clean). A question carries `canGoBack`; the first
   question of the wizard has nothing before it, so it does not listen and does not show the hint.
2. **A history of answers, replayed.** The wizard keeps the raw answer of each question really asked, in
   order (`wizard/history.ts`). Going back to question _n_ discards what came after, then runs the same
   linear flow again from the start: the questions before _n_ answer themselves from the history and _n_
   is asked again with its previous answer selected (ticked, for the component list). Because the flow
   is deterministic, everything derived (the candidates of each category, the implied Lucide, the skipped
   questions) is recomputed and nothing needs to be undone. The questions after _n_ are asked fresh.
   Values that came from flags or the config file are never asked, so never re-asked and never a step
   to go back to.
3. **The final confirmation is a choice.** "Create project with this configuration?" becomes a list:
   _Create the project_, _Change an answer_ and _Cancel_ (the old "No", exit code 130). _Change an
   answer_ lists the questions answered, each with its answer, and jumps to the chosen one with the same
   replay; Esc there returns to the confirmation, and Esc on the confirmation goes back to the last
   question. The confirmation moves from `commands/new.ts` into the wizard, which prints the summary
   through a callback each time before it asks.
4. **Nothing changes without a terminal.** Flags, `--defaults` and `--config` never prompt, so none of
   this applies. The project name, asked before the wizard when it was not given, is not a step.

## Alternatives considered

- A "← Back" choice in each list: rejected, it does not exist for `input` and `confirm`, and in the
  component checklist it would be one more tickable line.
- Undo functions per question: rejected, each question sets answers and implied values that a later
  question reads; replaying the flow gets them right without a second set of rules.
- Keep the later answers as the initial value when asking forward again: rejected, it breaks the rule
  that the shape of the project (architecture, routing, shell, components) is never preselected.
- Keep the yes/no confirmation and only add Esc: rejected, fixing an answer far back would take one Esc
  per question.

## Consequences

- Positive: a wrong answer, in any question or in the summary, is fixed without starting again; one
  mechanism for four kinds of prompt; the chained rules are untouched because the flow is the same code.
- Negative: Esc alone is delayed about half a second by the terminal (it shares its first byte with the
  arrow keys); the previous question remains on screen until it is cleared, which depends on
  `clearPromptOnDone` being read when the prompt settles.
- Follow-up: going back to the project name when it was asked; the same history for `as add`.
