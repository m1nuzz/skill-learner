# Coexistence with skill-creator and Skill Workshop

`skill-learner` is not a replacement for the host's built-in skill authors.
The three tools target different points in the skill lifecycle.

---

## Comparison

| Tool | What it does | When to choose |
|---|---|---|
| **Anthropic `skill-creator`** | Interactive interview with the user, then writes a structured `SKILL.md`. | The user can describe the workflow step by step. No execution loop needed. |
| **OpenClaw Skill Workshop** (plugin) | Watches the agent's conversation and proposes `SKILL.md` files when reusable workflows are detected. | A workflow already ran successfully in the current session and just needs to be captured. |
| **`skill-learner`** (this skill) | Runs a structured trial-error-correction loop to learn a new capability, then codifies the working procedure. | The agent does not yet know how to perform the task and must discover it through iteration. |

---

## How to choose at runtime

```
Does the agent already know how to do this?
├─ Yes, and the workflow ran successfully in this session
│  └─ Use OpenClaw Skill Workshop (if on OpenClaw) or Anthropic skill-creator.
├─ No, but the user can tell me the steps
│  └─ Use Anthropic skill-creator (interview mode).
└─ No, and I need to figure it out from scratch
   └─ Use skill-learner.
```

---

## Avoiding conflicts

If both `skill-learner` and Skill Workshop are enabled in the same OpenClaw
setup:

1. `skill-learner` always runs Phase 1 case-retrieval before generating a
   new skill — it will detect any skill (including Skill Workshop's) and
   either compose with it or stop.
2. Skill Workshop writes only to `<workspace>/skills/`. `skill-learner`
   prefers `<workspace>/skills/` too, so the case-retrieval scan will find
   Skill Workshop's output on the same path.
3. Result: even when both are active, dedup happens at Phase 1.

No flag is needed to disable either; the dedup logic is sufficient.

---

## What to do if a duplicate is created anyway

Two skills end up describing the same workflow:

1. Run both against the duplicate's `evals/evals.json` (or the agent's
   memory of trigger phrases).
2. Keep the one with higher pass rate.
3. Archive (do not delete) the other, recording the merge decision in
   `lessons.md` of the kept skill.
4. If the host supports it, redirect the archived skill's name to the
   kept one (e.g. via an alias entry in `library-index.json`).
