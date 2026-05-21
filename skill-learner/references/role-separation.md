# Role separation: Planner / Critic / Verifier

The same LLM plays all three roles, but each role uses a **fresh prompt with
no shared context** with the others. This is what prevents confirmation
bias (model rubber-stamping its own work) and the "structure snowballing"
failure mode documented in *Illusions of reflection*
(<https://arxiv.org/abs/2510.18254>).

Empirically, splitting these roles gave **+12.2 percentage points Pass@1**
on HumanEval in the Reflexion-extensions TMLR work.

---

## Planner

Input: goal, available tools, summary of prior attempts (compressed).

Output: one concrete next action, plus the expected observation if it succeeds.

Prompt skeleton:

```
You are the Planner. Produce ONE next action to make progress toward the goal.

Goal: <restated goal>
Available tools: <list>
Prior attempts (summary): <bulleted, max 5 lines>

Output:
- Action: <single command or tool call>
- Expected observation: <one line — what should happen if it works>
- Reversibility: <reversible | irreversible>
```

For irreversible or expensive actions, the Planner produces **2–3 candidate
actions** instead of one. The Verifier scores them cheaply, and only the
top candidate is executed.

---

## Critic

Input: the failing action and its actual output. **Not** the goal restatement,
**not** prior critic outputs.

Output: cause, lesson, smallest fix.

Prompt skeleton:

```
You are the Critic. The following action did not produce the expected result.

Action: <action>
Expected: <what was expected>
Actual: <stdout / stderr / state diff>

Output:
- Cause: <one sentence — why it failed>
- Lesson: <one sentence — generalisable insight>
- Smallest fix: <one concrete change to try next>
```

The Critic must propose a **different** fix than any previous attempt — if it
cannot, return `BLOCKED: <reason>` and stop the loop.

---

## Verifier

Input: success criteria and the final state. **Not** the code, **not** the
plan, **not** the Critic's reasoning.

Output: free-form rationale followed by a final `YES` / `NO`.

The Verifier's authority to say `YES` is contingent on at least one
**external tool signal** — see `verification-patterns.md`. If no tool signal
exists, the Verifier returns `UNVERIFIABLE` and the loop continues until one
can be produced.

Prompt skeleton:

```
You are the Verifier. Decide whether the success criteria are met based on
the external tool output below. Do not trust narrative claims.

Success criteria:
<bulleted criteria>

External tool output:
<stdout/stderr/diff/test report>

Output:
- Rationale: <3–6 lines comparing each criterion to the tool output>
- Decision: YES | NO | UNVERIFIABLE
```

A `YES` decision without an external tool block in the input is invalid —
the loop must not advance.

---

## Why fresh prompts matter

If the Verifier sees the Planner's intent ("we tried X because of Y"), it
inherits the Planner's expectation that X works and is much more likely to
return a false positive `YES`. Reflexion-extensions and *Illusions of
reflection* both document this systematically.

Implementation note: in a single chat session, "fresh prompt" can be
approximated by prefixing the Verifier prompt with explicit instructions to
ignore prior content, and by passing only the strict inputs listed above
(criteria + tool output).
