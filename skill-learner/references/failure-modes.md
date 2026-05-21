# Known failure modes during iterative learning

This file documents failure modes that recur during the Phase 2 attempt
loop and the Phase 3 verification step. Each comes with a detection signal
and a mitigation.

References:

- *Illusions of reflection* — <https://arxiv.org/abs/2510.18254>
- Reflexion extensions (vector memory + roles) — OpenReview, 2026
- CRITIC — <https://arxiv.org/abs/2305.11738>

---

## 1. Confirmation bias in self-verification

**Symptom:** Verifier returns `YES` for a result that an external check
would fail. Often happens when the Verifier sees the Planner's narrative
("we did X because of Y").

**Detection:** Tool signal contradicts the Verifier's `YES` decision.

**Mitigation:**

- Verifier runs with a fresh prompt — no access to the Planner's intent
  or the Critic's reasoning.
- Verifier authority to say `YES` is conditional on at least one external
  tool signal (see `verification-patterns.md`).

---

## 2. Hallucination snowballing

**Symptom:** Once the model commits to a wrong direction, subsequent
reflections justify and extend the wrong direction rather than reversing it.

**Detection:** Same error class repeated across ≥ 2 iterations with
different surface fixes.

**Mitigation:**

- Stopping condition triggers automatically (see SKILL.md Stopping
  conditions table).
- Critic must propose a *different class* of fix than any previous attempt.
- If the Critic cannot, return `BLOCKED` and stop the loop.

---

## 3. Structure snowballing (under constrained decoding)

**Symptom:** Rigid YAML / JSON output requirements cause the model to focus
on satisfying the schema rather than solving the task. The output is
perfectly formatted but semantically wrong.

Documented in <https://arxiv.org/abs/2604.06066>.

**Detection:** Output validates against schema but external tool signal
fails.

**Mitigation:**

- Verifier produces free-form rationale **before** YES/NO, not after.
- Do not force the entire procedure into a single rigid output template.
- Keep schemas at the I/O boundary, not throughout the reasoning chain.

---

## 4. Premature codification

**Symptom:** A workflow passes one trial run and is immediately saved as
a skill. Later, it fails on slightly different inputs.

**Detection:** First load of a newly-codified skill on a new input fails.

**Mitigation:**

- Verify reproducibility — run the workflow twice with the same input.
- Run at least one variant input (different parameter, different file)
  before codifying.
- The skill's `evals/evals.json` should have ≥ 2 examples covering
  different paths.

---

## 5. Over-narrow skills (false generalisation in the other direction)

**Symptom:** The codified skill hardcodes a specific input value, so it
only works for the exact original case.

**Detection:** Skill description mentions specific values rather than the
parameter shape.

**Mitigation:**

- During Phase 4 Codify, replace concrete values in the procedure with
  named parameters.
- Add a description trigger phrase that is general ("parse a CSV",
  not "parse my-data.csv").

---

## 6. Reflection inflation

**Symptom:** Each Critic output is longer than the last and refers to all
prior reasoning, growing the context until it dominates the prompt.

**Detection:** Critic output > 30 lines, or referring to "as I noted
above" / "as previously discussed".

**Mitigation:**

- Critic prompt explicitly demands ≤ 3 lines: cause, lesson, fix.
- Pass only the last 1–2 failures to the Critic, not the full history.
- Compress old history into a one-line `lessons.md` entry between
  iterations.

---

## 7. Verifier sees its own previous output

**Symptom:** Verifier flips from `NO` to `YES` after a code change it
believes is correct, but no new tool signal was generated.

**Detection:** Verifier's `YES` decision lacks a fresh tool-output block
in its input.

**Mitigation:**

- A `YES` decision requires a tool-output block *newer than* the previous
  `NO` decision.
- If the Verifier did not see fresh tool output, the loop must produce one
  before re-running the Verifier.
