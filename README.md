# skill-learner

A meta-skill that teaches an LLM agent to **learn a new capability through trial and
error**, then **codify the working workflow as a reusable skill**.

`skill-learner` follows the [AgentSkills](https://agentskills.io/specification) open
standard, so it works with any AgentSkills-compatible host — including
[hermes-agent](https://hermes-agent.nousresearch.com/),
[OpenClaw](https://documentation.openclaw.ai/),
and [Claude Code](https://platform.claude.com/docs/en/agents-and-tools/agent-skills).

---

## What this skill does

When the user asks the agent to "learn how to do X" or "figure it out and save it as a
skill", `skill-learner` activates and walks the agent through a structured loop:

1. **Define** — restate the goal, lock in falsifiable success criteria, and run
   *case retrieval* against existing skills to avoid duplicates.
2. **Attempt loop** — separate `Planner` / `Critic` / `Verifier` roles drive
   plan → validate → execute → reflect → retry. Adaptive stopping replaces a
   fixed retry budget (no progress for 2 turns → pivot).
3. **Verify** — run the `Verifier` in a fresh prompt against an **external tool
   signal** (tests, type-checker, schema validator, smoke run). Pure LLM
   judgement is never sufficient.
4. **Codify** — write a clean, distilled `SKILL.md`, extract reusable
   sub-skills, persist a `lessons.md` alongside, and save to the host's
   correct skills directory (see `skill-learner/references/host-paths.md`).

The point is to convert one-off problem solving into **persistent, transferable
procedural knowledge** the agent owns.

## When to use it

Trigger this skill when:

- The user wants the agent to acquire a new capability ("learn how to use this CLI",
  "figure out the workflow for X").
- The agent does *not yet know* the steps and must discover them by attempting,
  observing, and correcting.
- The user wants a successful workflow saved as a reusable skill, not just a one-off
  result.

## When **not** to use it

- The workflow already worked once in the current session and just needs to be
  packaged — prefer the host's built-in skill-creator (Anthropic skill-creator) or
  OpenClaw's Skill Workshop plugin.
- The user provides explicit step-by-step instructions — there is nothing to learn.
- The task is a one-shot, not a reusable capability.

---

## Installation

One-line install (no clone required) — downloads the skill folder and
copies it into your host's skills directory:

```bash
curl -fsSL https://raw.githubusercontent.com/m1nuzz/skill-learner/main/skill-learner/scripts/install.sh | bash
```

To install into every known host path at once:

```bash
curl -fsSL https://raw.githubusercontent.com/m1nuzz/skill-learner/main/skill-learner/scripts/install.sh | bash -s -- --all
```

The installer **copies** the skill folder into the target directory by
default — no symlinks, so you can delete the source after install. For
developer mode (symlink from a clone for `git pull`-driven updates) and
per-host manual install commands, see [`INSTALL.md`](INSTALL.md).

---

## Repository layout

```
skill-learner/
├── README.md                     # This file
├── INSTALL.md                    # Per-host installation instructions
├── LICENSE                       # MIT
└── skill-learner/
    ├── SKILL.md                  # Frontmatter + procedure (entry point)
    ├── references/               # Loaded on demand — progressive disclosure
    │   ├── role-separation.md
    │   ├── verification-patterns.md
    │   ├── host-paths.md
    │   ├── case-retrieval.md
    │   ├── subgoal-extraction.md
    │   ├── library-maintenance.md
    │   ├── failure-modes.md
    │   └── coexistence.md
    ├── scripts/
    │   ├── detect_host.sh        # Prints hermes | openclaw | claude-code | generic
    │   └── install.sh            # Cross-host installer (copy by default, symlink with --dev)
    └── evals/
        └── evals.json            # Trigger and behavior tests
```

The top-level `SKILL.md` is the entry point that hosts load by default; the
`references/` files are loaded only when the agent follows an internal link
to them (progressive disclosure).

---

## How it differs from related tools

| Tool | When to choose |
|---|---|
| **Anthropic skill-creator** | The user can describe the workflow step by step. Interview-based packaging, no execution loop. |
| **OpenClaw Skill Workshop** | A workflow already ran successfully in the session and just needs to be captured. |
| **`skill-learner` (this repo)** | The agent does *not* yet know how to perform the task and must learn it through iterative trial, error, and correction. |

The three tools are complementary, not replacements for each other.

---

## What changed in v2.0

The v2.0 rewrite applies findings from the research listed in the
[References](#references) section:

- `Planner` / `Critic` / `Verifier` roles are split; the Verifier runs with a
  fresh prompt and requires an external tool signal to return `YES`.
- Adaptive stopping replaces the fixed 5-retry budget — no measurable progress
  for 2 iterations triggers a pivot.
- `Phase 1` runs **case retrieval** against existing skills before generating a
  new one (avoids duplicates and library bloat).
- `Phase 4` extracts reusable **sub-skills** instead of saving monolithic
  workflows, and is **host-aware** when writing to the skills directory.
- A `lessons.md` is persisted alongside each generated `SKILL.md` to capture
  causal lessons learned (not raw failure logs).
- A `Phase 5` maintenance routine periodically prunes stale and failing skills.
- Progressive disclosure: `references/`, `scripts/`, and `evals/` are now
  populated.
- Cross-host installer (`scripts/install.sh`) detects hermes / OpenClaw /
  Claude Code and installs into the correct path.

---

## References

The design of `skill-learner` and its planned improvements draw on the following
sources.

### Agent Skills standards and host documentation

- AgentSkills.io specification — <https://agentskills.io/specification>
- Anthropic — Agent Skills best practices — <https://platform.claude.com/docs/en/agents-and-tools/agent-skills/best-practices>
- Anthropic engineering — Equipping agents for the real world with Agent Skills — <https://www.anthropic.com/engineering/equipping-agents-for-the-real-world-with-agent-skills>
- Anthropic skill-creator reference skill — <https://github.com/anthropics/skills/blob/main/skills/skill-creator/SKILL.md>
- hermes-agent skills system — <https://github.com/NousResearch/hermes-agent/blob/main/website/docs/user-guide/features/skills.md>
- hermes-agent — Creating skills — <https://hermes-agent.nousresearch.com/docs/developer-guide/creating-skills>
- hermes-agent — In-repo skill authoring — <https://hermes-agent.nousresearch.com/docs/user-guide/skills/bundled/software-development/software-development-hermes-agent-skill-authoring>
- OpenClaw — Skills overview — <https://documentation.openclaw.ai/tools/skills>
- OpenClaw — Creating skills — <https://documentation.openclaw.ai/tools/creating-skills>
- OpenClaw — Skill Workshop plugin — <https://documentation.openclaw.ai/plugins/skill-workshop>
- Community best practices — <https://www.mdskills.ai/docs/skill-best-practices> and <https://agentskills.io/skill-creation/best-practices>

### Research (self-improving and skill-learning agents)

- Wang et al., *Voyager: An Open-Ended Embodied Agent with Large Language Models* — <https://arxiv.org/abs/2305.16291>
- Shinn et al., *Reflexion: Language Agents with Verbal Reinforcement Learning* — <https://arxiv.org/abs/2303.11366>
- Madaan et al., *Self-Refine: Iterative Refinement with Self-Feedback* — <https://arxiv.org/abs/2303.17651>
- Gou et al., *CRITIC: Large Language Models Can Self-Correct with Tool-Interactive Critiquing* — <https://arxiv.org/abs/2305.11738>
- Zhao et al., *ExpeL: LLM Agents Are Experiential Learners* — <https://arxiv.org/abs/2308.10144>
- Majumder et al., *CLIN: A Continually Learning Language Agent for Rapid Task Adaptation and Generalization* — <https://arxiv.org/abs/2310.10134>
- Zhou et al., *Language Agent Tree Search (LATS)* — <https://arxiv.org/abs/2310.04406>
- Wang, Neubig, Fried, *TroVE: Inducing Verifiable and Efficient Toolboxes for Solving Programmatic Tasks* — <https://arxiv.org/abs/2401.12869>
- Nottingham et al., *Skill Set Optimization (SSO): Reinforcing Language Model Behavior via Transferable Skills* — <https://arxiv.org/abs/2402.03244>
- Chen et al., *AutoManual: Constructing Instruction Manuals by LLM Agents via Interactive Environmental Learning* — <https://arxiv.org/abs/2405.16247>
- Zhou et al., *Memento: Fine-tuning LLM Agents without Fine-tuning LLMs* — <https://arxiv.org/abs/2508.16153>
- Weatherhead & Salim, *Illusions of reflection: open-ended task reveals systematic failures in LLMs' reflective reasoning* — <https://arxiv.org/abs/2510.18254>
- Latimer et al., *Hindsight is 20/20: Building Agent Memory that Retains, Recalls, and Reflects* — <https://arxiv.org/abs/2512.12818>

---

## License

MIT. See `LICENSE` if present, otherwise treat the contents of this repository as
MIT-licensed.
