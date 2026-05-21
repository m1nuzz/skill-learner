# Library maintenance — trim stale and failing skills

Pattern from TroVE (<https://arxiv.org/abs/2401.12869>) and Skill Set
Optimization (<https://arxiv.org/abs/2402.03244>): periodically prune
skills that are unused or stop working. TroVE reported toolboxes 79–98%
smaller with the same or higher accuracy after trimming.

Run this maintenance routine when the agent's skill library exceeds about
30 skills, or every N sessions in long-running setups.

---

## Step 1: build a library index

If the host does not track usage, maintain a `library-index.json` in the
skills root with one entry per skill:

```json
{
  "skill-name": {
    "path": "/abs/path/to/skill-name",
    "usage_count": 0,
    "last_used_at": "2026-04-21T10:32:14Z",
    "last_eval_at": null,
    "last_eval_passed": null
  }
}
```

Increment `usage_count` and update `last_used_at` every time the skill is
loaded.

## Step 2: flag stale skills

A skill is flagged `[STALE]` if **both** are true:

- `last_used_at` is older than **60 days**.
- `usage_count` is **less than 3**.

These thresholds are starting points; tune to taste.

## Step 3: re-evaluate flagged skills

For each `[STALE]` skill:

- If it has `evals/evals.json`, run it. Record pass/fail in
  `last_eval_passed`.
- If it does not have evals, attempt a smoke trigger using the description's
  trigger phrases. Pass = skill loaded and produced its expected output
  shape on a synthetic input.

## Step 4: archive (do not delete) failing skills

A skill that fails its re-eval is moved to `archive/<skill-name>/`,
**not deleted**. Reasons:

- The failure may be environmental (broken dependency) and recoverable.
- The original learning trajectory still has value in `lessons.md`.
- Recovery is one move; recreation is hours.

Update `library-index.json` to record the archive timestamp and the failure
reason.

## Step 5: log the maintenance run

Append a one-line record to `maintenance.log`:

```
2026-05-21T10:00:00Z  cleaned 7 skills  archived 2 (json-parser, web-scraper)  reasons: [stale-failing, dependency-broken]
```

---

## What about composition?

When archiving a skill, check whether any other skill **references it**
(via the subgoal-extraction composition pattern). If yes:

- Do **not** auto-archive — flag the parent for re-eval first.
- Decision is then driven by whether the parent still works.

---

## When to skip this maintenance

- Library has fewer than ~10 skills — overhead exceeds benefit.
- All skills are very recently created (initial bootstrap phase).
- The host has its own built-in usage tracking and pruning (e.g. when
  hermes-agent ships the feature requested in issue #13534).
