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

1. **Define** — restate the goal and lock in falsifiable success criteria.
2. **Attempt loop** — plan a small action, execute it, observe the actual result,
   reflect on the gap, fix the smallest thing, and retry. Up to a fixed retry budget.
3. **Verify** — confirm the final result against the success criteria and check
   reproducibility.
4. **Codify** — once a working procedure exists, write a clean, distilled `SKILL.md`
   for the new capability and save it under the host's skills directory so the agent
   can re-use the workflow later without re-learning it.

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

The skill is hosted-agnostic; just copy or symlink the `skill-learner/` directory
into your host's skills folder.

### hermes-agent

```bash
git clone https://github.com/m1nuzz/skill-learner.git
ln -s "$(pwd)/skill-learner/skill-learner" "$HOME/.hermes/skills/skill-learner"
```

Then `/skill-learner` becomes available as a slash command in any hermes CLI or
messaging session.

### OpenClaw

For the active workspace (highest precedence):

```bash
git clone https://github.com/m1nuzz/skill-learner.git
ln -s "$(pwd)/skill-learner/skill-learner" "<workspace>/skills/skill-learner"
```

Or for all local agents:

```bash
ln -s "$(pwd)/skill-learner/skill-learner" "$HOME/.agents/skills/skill-learner"
```

### Claude Code

```bash
git clone https://github.com/m1nuzz/skill-learner.git
ln -s "$(pwd)/skill-learner/skill-learner" "$HOME/.claude/skills/skill-learner"
```

### Generic AgentSkills host

The lowest-common-denominator path is `~/.agents/skills/<name>/SKILL.md` — most
AgentSkills-compatible runtimes will pick it up from there.

---

## Repository layout

```
skill-learner/
├── README.md                     # This file
└── skill-learner/
    └── SKILL.md                  # The skill definition (frontmatter + procedure)
```

The skill is intentionally a single self-contained `SKILL.md` for now. See the
[Roadmap](#roadmap) below for planned subfolders (`references/`, `scripts/`, `evals/`).

---

## How it differs from related tools

| Tool | When to choose |
|---|---|
| **Anthropic skill-creator** | The user can describe the workflow step by step. Interview-based packaging, no execution loop. |
| **OpenClaw Skill Workshop** | A workflow already ran successfully in the session and just needs to be captured. |
| **`skill-learner` (this repo)** | The agent does *not* yet know how to perform the task and must learn it through iterative trial, error, and correction. |

The three tools are complementary, not replacements for each other.

---

## Roadmap

Improvements planned (tracked in
[`skill-learner-improvements.md`](#references) — see references below):

- Split `Critic` and `Verifier` roles for tool-grounded verification.
- Persist `lessons.md` alongside each generated `SKILL.md` (causal abstractions, not
  raw failure logs).
- Replace fixed 5-retry budget with adaptive stopping (no progress for 2 turns → pivot).
- Case-conditioned prompting: scan existing skills before generating a new one to
  avoid duplicates and inherit conventions.
- Periodic library maintenance: prune stale or failing skills.
- Subgoal extraction: decompose successful workflows into reusable sub-skills.
- `references/`, `scripts/`, and `evals/` subfolders for progressive disclosure.
- Cross-host installer (`scripts/install.sh`) that detects hermes / OpenClaw /
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
