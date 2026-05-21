# Verification patterns

The Verifier is only allowed to return `YES` when an external tool signal
backs the decision. This file lists the tool signal to use per task type.

The pattern comes from CRITIC (<https://arxiv.org/abs/2305.11738>):

> Self-correction through pure LLM judgement consistently underperforms
> tool-grounded verification.

---

## Code (Python / JS / TS / Go / Rust / etc.)

Required tool signals — at least one must pass:

- Unit tests via the project's test runner (`pytest`, `npm test`, `cargo test`).
- Type checker (`mypy`, `pyright`, `tsc --noEmit`, `cargo check`).
- Linter for syntax errors (`ruff`, `eslint`, `clippy`).
- Smoke run with a sample input that produces an expected output.

Insufficient on their own:

- "The code compiles" — compilation is necessary, not sufficient.
- "The function returns something" — without comparing to an expected value.

---

## Shell pipelines / CLI workflows

Required signals — at least one:

- Exit code 0 on a representative run.
- Output matches expected pattern (grep, diff against an expected file).
- A side effect can be checked (file exists, row in DB, status of remote resource).

---

## Data transformation

Required signals — at least one:

- Output validates against a JSON Schema / Avro schema / Pydantic model.
- Diff against an expected sample (`diff`, `jd`, `dyff`).
- Statistical invariants hold (row count, sum of a column, distribution).

---

## API integration

Required signals — at least one:

- HTTP response status is in the expected set (e.g. 2xx).
- Response body matches expected schema and has expected fields.
- An idempotent check call confirms the side effect (e.g. read-after-write).

---

## File-based / document tasks (PDF, image, markdown)

Required signals — at least one:

- File exists and has plausible size (e.g. > 0 bytes, < expected max).
- File-type validator passes (`file`, `pdfinfo`, `identify`).
- Sampled content matches expected pattern (extract first page, check for known string).

---

## When NO external signal is available

If the task genuinely cannot be checked with a tool — e.g. "explain this
concept" or "draft a poem" — the Verifier returns `UNVERIFIABLE` and:

- The skill is **not saved**. There is nothing learnable to codify.
- The agent reports the result with `[UNVERIFIED]` tag.
- This is rare. Most tasks have *some* tool signal — sometimes you need to
  invent it (e.g. write a script that re-checks a fact).

---

## Anti-patterns

- "The LLM said it works" — never sufficient.
- Output looks plausible — not a signal.
- Same LLM as Planner and Verifier sharing context — confirmation bias.
- Verifier reads the code instead of running it — runs catch errors the
  reader does not.
