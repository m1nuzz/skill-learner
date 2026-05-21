# Case retrieval — find similar skills before generating new ones

Before generating a new skill in Phase 4, the agent must check whether a
similar skill already exists. This avoids skill-library bloat and reuses
prior learning.

The pattern comes from AutoManual (<https://arxiv.org/abs/2405.16247>) —
"case-conditioned prompting" — which significantly reduced rule hallucinations
when updating an instruction manual.

---

## Step 1: enumerate existing skills

For each host, list skills from these directories (use `detect_host.sh` to
pick the right set):

- hermes: `~/.hermes/skills/*/SKILL.md` and `<repo>/skills/**/SKILL.md`.
- OpenClaw: `<workspace>/skills/*/SKILL.md`, `~/.agents/skills/*/SKILL.md`,
  `~/.openclaw/skills/*/SKILL.md`.
- Claude Code: `~/.claude/skills/*/SKILL.md`, `<repo>/.claude/skills/*/SKILL.md`.

For each skill, read just the YAML frontmatter — `name` and `description`
are enough.

## Step 2: score similarity

Two cheap signals:

- **Keyword overlap** — extract the top noun phrases from the candidate
  description and the existing one. Jaccard similarity ≥ 0.4 → similar.
- **Trigger phrase overlap** — if both descriptions list trigger phrases
  ("use when the user says ..."), check overlap of those phrases.

If a more capable retrieval mechanism is available (embeddings + cosine
similarity), prefer that — see `scripts/retrieve_similar.py` once implemented.

## Step 3: act on the result

| Match strength | Action |
|---|---|
| **Exact name collision** | Stop. Either patch the existing skill or rename the new one. Never create a duplicate name. |
| **High description overlap** (≥ 0.6 Jaccard) | Stop. Surface the existing skill to the user and ask whether to patch it instead. |
| **Partial overlap on a sub-step** | Continue, but compose the existing skill — reference it from the new SKILL.md instead of re-implementing the overlapping part. See `subgoal-extraction.md`. |
| **No meaningful overlap** | Continue normally to Phase 4 codify. |

## Step 4: record the decision

In the new skill's `lessons.md` (if created), note what existing skills
were considered and why a new one was created anyway. This makes future
audits easier and prevents the same dedup question being re-asked.

---

## Why this matters

A real hermes-agent setup with 146+ skills reported (issue #13534):

- No usage tracking, no conflict detection, no pre-creation validation
  in the host itself.
- Result: accumulated unused skills waste `available_skills` block tokens
  on every turn.

Doing case retrieval *inside* `skill-learner` solves this for any host,
regardless of whether the host has built-in dedup.
