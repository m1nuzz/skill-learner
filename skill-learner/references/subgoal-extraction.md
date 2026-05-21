# Subgoal extraction — break successful workflows into reusable sub-skills

Pattern from Skill Set Optimization
(<https://arxiv.org/abs/2402.03244>) — "extract common subtrajectories
with high rewards" — applied to skill authoring.

When a working workflow is captured in Phase 4, do not save it as one
monolithic skill if it contains substeps that are useful on their own.
Decompose into a **parent skill** + **primitive sub-skills**.

---

## Algorithm

Given a working workflow as N ordered steps:

1. For each contiguous subsequence of length 2 to N-1:
   - Ask: would this subsequence be useful on its own, applied to a
     different but related task?
   - If yes, mark it as a candidate sub-skill.
2. Among candidates, prefer **shorter** and **more general** ones — they
   compose better.
3. For each chosen sub-skill:
   - Extract to its own skill folder (`<sub-skill-name>/SKILL.md`).
   - Generalise the inputs (replace concrete values with named parameters).
4. In the parent skill, replace the inlined steps with a reference:

   ```
   ## Procedure
   1. Run `<sub-skill-name>` with: <parameters>.
   2. <next step>
   ```

---

## Heuristics for what makes a good sub-skill

Good sub-skill:

- Has well-defined inputs and outputs.
- Solves a problem that recurs across many tasks (e.g. "parse a JSON
  response and surface schema errors").
- Has independent value — could be called directly by the user without the
  parent skill.

Bad sub-skill:

- Tightly coupled to the parent's specific intermediate state.
- Single-line shell command — too small, just inline it.
- Whole workflow minus the final step — too large, just reference it.

---

## When NOT to decompose

- The workflow is short (≤3 steps). Decomposition adds friction without
  benefit.
- The steps only make sense in sequence (e.g. a strict 5-step deploy that
  fails halfway). Decomposing creates the illusion of independent components
  that do not exist.
- The user explicitly asked for a single-purpose skill.

---

## After extraction

- Both the parent and each new sub-skill are subject to verification — run
  the parent's `evals/evals.json` to confirm the composition still works.
- Each new sub-skill should ideally have at least one entry in its own
  `evals/evals.json`.
- Update the parent skill's `lessons.md` to record which sub-skills it now
  depends on.
