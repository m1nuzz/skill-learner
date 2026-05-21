---
name: skill-learner
description: Use this skill when the user wants Claude to learn a new capability through trial, error correction, and iteration — then save the successful workflow as a reusable skill. Trigger whenever the user says things like "learn how to do X", "teach yourself to do X", "figure it out and save it", "practice until it works then make a skill", or "try until it works and create a reusable workflow". Also trigger when the user wants to capture a successful multi-step workflow from the current conversation into a skill. Always use this skill over ad-hoc attempts when the goal is a repeatable, saved capability.
---

# Skill Learner

## Purpose
Enable Claude to acquire new capabilities by attempting a task, observing failures, correcting mistakes, and iterating until success — then codify the working workflow into a reusable skill file.

## Inputs
- A clear description of what the agent should learn to do
- Access to relevant tools, files, or APIs needed for the task
- Optionally: sample inputs/outputs or success criteria from the user

---

## Procedure

### Phase 1 — Define

Before attempting anything:

1. Restate the goal in one precise sentence.
2. Define the success criteria explicitly — what does "done" look like?
3. List the tools, files, and commands available.
4. Identify risks or irreversible actions and flag them to the user.

### Phase 2 — Attempt Loop

Repeat up to **5 times** or until success is verified:

**Step 1: Plan**
- Break the task into the smallest testable unit.
- Choose the simplest valid first action.
- Prefer reversible, low-risk approaches.

**Step 2: Execute**
- Run the command, code snippet, or tool call.
- Capture all output: stdout, stderr, file changes, API responses.

**Step 3: Observe**
- Compare the actual result against the success criteria.
- Classify: ✅ success / ⚠️ partial / ❌ failure.
- Record the exact failure point or deviation.

**Step 4: Reflect**
- Explain *why* it failed or fell short.
- Extract one concrete lesson.
- Identify the smallest useful fix.

**Step 5: Revise and retry**
- Apply only the identified fix — do not rewrite everything.
- Do not repeat the same action without a meaningful change.

### Phase 3 — Verify

Once the task appears complete:

1. Run a final validation check against the original success criteria.
2. Confirm the result is reproducible (run it once more if possible).
3. If validation fails, return to Phase 2.

### Phase 4 — Codify

After confirmed success, create a new skill:

1. Identify the skill name (short kebab-case, e.g. `pdf-extractor`, `api-tester`).
2. Write a clean `SKILL.md` — distilled workflow only, no failure history.
3. Save to `/mnt/skills/user/<skill-name>/SKILL.md`.

Use this template for the generated skill:

```md
---
name: <skill-name>
description: <one sentence: what it does and when to trigger it>
---

# <Skill Name>

## Purpose
What this skill enables the agent to accomplish.

## When to use
Trigger phrases and task contexts. Boundaries and exclusions.

## Inputs
Expected inputs, files, tools, environment assumptions.

## Procedure
Numbered steps of the working workflow.

## Validation
How to verify success.

## Known failure modes
Failure patterns found during learning and how to avoid them.
```

---

## Stopping conditions

| Condition | Action |
|-----------|--------|
| Success verified | Proceed to codify |
| 5 retries exhausted, no success | Stop; save partial skill only if partially reusable; mark it `[INCOMPLETE]` |
| Environment makes success impossible | Stop; report blockers clearly |

---

## Output at the end

Always conclude with:

- **Result**: what was produced
- **Learning outcome**: what worked and what didn't
- **Skill saved**: name and path of the new skill file (or reason it wasn't saved)

---

## Operating principles

- Prefer tested knowledge over guessed knowledge.
- Never claim success without running a verification step.
- Never save a skill that hasn't actually worked.
- Keep generated skills concise and implementation-focused — omit the messy learning history.
- Prefer small targeted fixes over full rewrites unless the current path is fundamentally broken.
