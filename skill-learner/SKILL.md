---
name: skill-learner
description: Runs a learn-by-trial loop and saves the result as a skill. Triggers: "learn how to X", "teach yourself to X", "figure out X and save it", "научись X", "разберись с X", "выучи X", "освой X".
version: 2.1.0
author: m1nuzz
license: MIT
metadata:
  hermes:
    tags: [meta, learning, skill-authoring, agent-skills]
    related_skills: [skill-creator]
  openclaw:
    requires:
      bins: []
      config: []
---

# Skill Learner

A meta-skill that helps the agent acquire a new capability through structured
trial-and-error, then save the working procedure as a reusable skill.

This skill is host-agnostic and works in hermes-agent, OpenClaw, Claude Code,
and any other AgentSkills-compatible runtime. See `references/host-paths.md`
for where generated skills are saved on each host.

## Invocation contract

**Read this first.** When this skill is loaded — whether the user invokes
it by name (`skill-learner ...`) or via a trigger phrase — the agent MUST:

1. Execute Phases 1 → 2 → 3 → 4 of the procedure below, in order. Do not
   skip ahead.
2. **Not** answer the user's underlying request directly as a one-shot. The
   user invoked this skill to make the agent *learn and codify*, not to
   get an immediate answer.
3. Conclude with the **Output at the end** block (Result / Verification
   signal / Skill saved / Lessons captured) — every field filled in or
   explicitly marked "not applicable, because …".

The one explicit exception: if Phase 1 reveals the request is a genuine
one-shot with nothing reusable to capture (e.g. "what is 2+2"), stop at
Phase 1, tell the user *"This is a one-shot — no skill will be created"*,
then handle the underlying request normally.

## When to use

Trigger when:

- The user asks the agent to learn how to do something new. Trigger phrases
  in different languages:
  - English: *"learn how to X"*, *"teach yourself to X"*, *"figure out the
    workflow for X"*, *"practice X until it works"*, *"figure out X and
    save it as a skill"*.
  - Russian: *"научись X"*, *"разберись с X"*, *"выучи X"*, *"освой X"*,
    *"практикуйся в X"*, *"разбери X и сделай скилл"*.
- The agent does not yet know the steps and must discover them by attempting,
  observing failures, correcting, and retrying.
- The user wants a successful workflow saved as a reusable skill.

The skill body and all generated artifacts (procedures, references, lessons)
are written in English regardless of the user's language — this keeps the
skill portable across hosts and avoids translation drift. The agent
converses with the user in their language.

## When not to use

- The workflow already worked in this session — use the host's built-in
  skill-creator (Anthropic) or Skill Workshop (OpenClaw) to package it.
- The user already knows the steps — there is nothing to learn; just follow
  the instructions.
- The task is one-shot — do the task, do not invoke skill-learner.

See `references/coexistence.md` for a full comparison with adjacent tools.

## Inputs

- A clear objective from the user.
- Access to the tools/files/APIs needed for the task.
- Optional: sample inputs/outputs or explicit success criteria.

---

## Procedure

The procedure uses three role-conditioned prompts. The same model can play all
three, but each prompt is independent — the Verifier in particular must not
see the Critic's reasoning or the Planner's intent, to avoid confirmation bias.
See `references/role-separation.md` for full role prompts.

| Role | Job |
|---|---|
| **Planner** | Generate the next concrete action toward the goal. |
| **Critic** | After a failure, explain *why* it failed and propose one minimal fix. |
| **Verifier** | Independently judge whether the success criteria are met, using external tool signals. |

### Phase 1 — Define

1. Restate the goal in one precise sentence.
2. Define success criteria explicitly — what does "done" look like?
   Each criterion must be falsifiable (a tool can check it).
3. List the tools, files, and commands available.
4. Identify risks or irreversible actions; flag them to the user.
5. **Case retrieval** — scan existing skills in the host's skills directory
   for a similar `description` or `name`. If a close match exists:
   - If it covers this goal — stop and tell the user; do not duplicate.
   - If it covers a sub-step — plan to compose it instead of re-implementing.

   See `references/case-retrieval.md`.

### Phase 2 — Attempt loop

Repeat until success is verified, no progress is being made, or a hard
blocker is hit (see Stopping conditions). On each iteration:

**Step 1 (Planner): Plan**

- Break the task into the smallest testable unit.
- Choose the simplest valid first action.
- Prefer reversible, low-risk approaches.
- For **expensive or irreversible** steps: generate 2–3 candidate plans
  instead of one, validate each cheaply, and let the Verifier score them
  before execution (beam search of depth 1).

**Step 2 (Planner): Validate plan**

- Dry-run, lint, type-check, or otherwise statically inspect the planned action.
- Reject plans that obviously won't work before they touch the environment.

**Step 3 (Executor): Execute**

- Run the command, code snippet, or tool call.
- Capture all output: stdout, stderr, file changes, API responses.

**Step 4 (Critic): Reflect on failure**

If the step did not produce the expected result:

- Explain *why* it failed. Quote the relevant error.
- Extract one concrete lesson.
- Identify the smallest useful fix.

**Step 5 (Planner): Revise and retry**

- Apply only the identified fix; do not rewrite everything.
- Never repeat the same action without a meaningful change.

### Phase 3 — Verify

When the workflow appears complete, run the **Verifier** as an independent
check.

The Verifier:

- Receives the success criteria and the final result.
- Does **not** receive the code, the plan, or the Critic's reflections.
- Uses **external tool signals** to decide pass/fail — tests, type checker,
  schema validator, smoke run, diff against an expected output. Pure
  LLM-judgement is never sufficient.
- Returns a short rationale, then a final `YES` / `NO`.

See `references/verification-patterns.md` for tool-grounded checks per task
type, and `references/failure-modes.md` for known reflection failure modes
to guard against.

If the Verifier returns `NO`, return to Phase 2 with the failure note added
to the Critic's context.

### Phase 4 — Codify

After a confirmed `YES` from the Verifier:

1. **Name the skill** — short kebab-case, e.g. `pdf-extractor`, `api-tester`.
   Re-check the existing skill library to avoid name collisions.
2. **Subgoal extraction** — scan the working workflow for reusable
   sub-sequences (≥2 steps that have value on their own). For each, save
   a separate primitive skill and reference it from the parent skill
   instead of inlining. See `references/subgoal-extraction.md`.
3. **Write `SKILL.md`** — clean, distilled workflow only. Use the template
   below. No failure history, no emoji, no first-person voice.
4. **Write `lessons.md`** — alongside `SKILL.md`, in the same skill folder.
   This captures causal lessons learned during the attempt loop:
   "when condition C, prefer approach W over Y". `lessons.md` is for
   future updates of this same skill and similar skills; it is not
   loaded as part of the skill's primary context.
5. **Save to the correct host path** — see `references/host-paths.md`.
   In short:
   - hermes-agent: prefer `skill_manage(action='create')` if available,
     else `~/.hermes/skills/<name>/`.
   - OpenClaw: `<workspace>/skills/<name>/` (highest precedence),
     fallback `~/.agents/skills/<name>/`.
   - Claude Code: `~/.claude/skills/<name>/` or `<repo>/.claude/skills/<name>/`.
   - Generic / fallback: `~/.agents/skills/<name>/`.

### Phase 5 — Maintenance (run when the skill library grows large)

When the agent's skill library exceeds ~30 entries, periodically:

1. For each skill, check `usage_count` and `last_used_at` (track these in a
   `library-index.json` if the host does not).
2. Skills not used in 60 days with `usage_count < 3` → flag `[STALE]`.
3. Re-run each flagged skill's `evals/evals.json`.
4. Still failing → move to `archive/`, do not delete. History matters.

See `references/library-maintenance.md`.

---

## Template for the generated skill

```markdown
---
name: <skill-name>
description: <First sentence ≤60 chars, full text ≤250 chars. Imperative or third-person voice. Includes concrete trigger phrases.>
version: 1.0.0
author: <agent or user>
license: MIT
metadata:
  hermes:
    tags: [<category>, <keywords>]
  openclaw:
    requires:
      bins: []
      config: []
---

# <Skill Name>

## When to use
Trigger phrases and task contexts. Boundaries and exclusions.

## Inputs
Expected inputs, files, tools, environment assumptions.

## Procedure
Numbered steps of the working workflow.

## Validation
How to verify success. Must reference an external tool signal (tests, type
checker, schema, smoke run), not LLM judgement alone.

## Known failure modes
Failure patterns found during learning and how to avoid them.
```

---

## Stopping conditions

Replaces fixed retry budgets with adaptive stopping:

| Condition | Action |
|---|---|
| Verifier returned `YES` | Proceed to Codify. |
| No measurable progress for **2 consecutive iterations** | Pivot the approach or stop. A re-tried failure is not progress. |
| Same error class repeats with different fixes | Stop; the model is in a hallucination loop. Block on the user. |
| Environment makes success impossible (missing tool, credentials, network) | Stop; report blockers clearly. |
| User instructed to stop | Stop immediately. |

If stopped without success, optionally save a `[INCOMPLETE]`-tagged partial
skill **only** if at least one phase was verified working. Mark explicitly
which parts are unverified.

---

## Output at the end

Always conclude with:

- **Result** — what was produced.
- **Verification signal** — which external tool confirmed success, with its output.
- **Skill saved** — name, path, and host. Or the reason it was not saved.
- **Lessons captured** — path to `lessons.md` if non-empty.

---

## Operating principles

- Prefer tested knowledge over guessed knowledge.
- Never claim success without an external tool signal — Verifier alone is not enough.
- Never save a skill that has not actually worked end-to-end.
- Keep generated skills concise and implementation-focused; omit the messy learning history (it goes in `lessons.md`).
- Prefer small targeted fixes over full rewrites.
- The Verifier must run with a fresh prompt — no shared context with Planner or Critic.

---

## Coexistence with similar tools

This skill solves a different problem from related tools — they are
complementary, not replacements.

| Tool | When to choose |
|---|---|
| Anthropic `skill-creator` | The user can describe the workflow step by step. Interview-based. |
| OpenClaw Skill Workshop | A workflow already ran successfully in the session and just needs to be captured. |
| **`skill-learner` (this skill)** | The agent does not yet know how to perform the task and must learn it through iterative trial, error, and correction. |

See `references/coexistence.md` for full details.
