# Host paths — where to save generated skills

Different AgentSkills-compatible hosts use different default locations and
have different precedence rules. The Codify phase must detect the host and
save to the correct path.

If unsure, run `scripts/detect_host.sh` (returns one of `hermes`, `openclaw`,
`claude-code`, `generic`).

---

## hermes-agent (Nous Research)

Canonical user path: `~/.hermes/skills/<name>/SKILL.md`

Preferred method to create a new skill:

```python
skill_manage(action="create", name="<name>", description="...", body="...")
```

`skill_manage` handles validation against
`tools/skill_manager_tool.py::_validate_frontmatter` and ensures the skill
is picked up without a restart.

In-repo (committed) skills go to `<repo>/skills/<category>/<name>/SKILL.md`
via `write_file` + `git add`. `skill_manage(action='create')` does NOT
target the in-repo tree.

Validation rules to satisfy:

- Starts with `---` as the first bytes (no leading blank line).
- Closes with `\n---\n` before the body.
- YAML mapping.
- `name` field present (kebab-case).
- `description` field present, ≤ 1024 chars (`MAX_DESCRIPTION_LENGTH`).
- Non-empty body after the closing `---`.

Practical: the **first sentence** of `description` should be ≤ 60 chars
because the system-prompt skill index truncates to that length
(hermes issue #13944).

After saving, the skill becomes available as `/skill-name` slash command.

---

## OpenClaw

Precedence (highest first):

| Path | Visibility |
|---|---|
| `<workspace>/skills/<name>/` | Only the current workspace's agent |
| `<workspace>/.agents/skills/<name>/` | Only the current workspace's agent |
| `~/.agents/skills/<name>/` | All local agents |
| `~/.openclaw/skills/<name>/` | All local agents |
| Bundled (shipped with install) | All agents |
| `skills.load.extraDirs` (config) | All local agents |

When generating a new skill, prefer `<workspace>/skills/<name>/` — it has
highest precedence and is scoped to the current project.

If the agent is not running inside a workspace, fall back to
`~/.agents/skills/<name>/` (portable across hosts).

OpenClaw also has a **Skill Workshop** plugin that auto-captures workflows.
Coexistence note: if Skill Workshop is enabled, `skill-learner` should still
be used for *learning new capabilities*; Skill Workshop is for capturing
already-completed workflows. See `coexistence.md`.

---

## Claude Code (Anthropic)

| Scope | Path |
|---|---|
| User | `~/.claude/skills/<name>/SKILL.md` |
| Project | `<repo>/.claude/skills/<name>/SKILL.md` |

Description truncation in Claude Code is around 250 characters in the
system prompt skill index — keep descriptions ≤ 250 chars in total.

---

## Generic / fallback (any AgentSkills-compatible host)

When the host cannot be identified or when authoring for portability:

```
~/.agents/skills/<name>/SKILL.md
```

This is the AgentSkills lowest-common-denominator location. OpenClaw reads
it natively (3rd precedence). hermes-agent can be configured to read it via
`skills.external_dirs`. Other compatible hosts typically read it too.

---

## Universal install (push to every known path)

If the skill is portable and you want it visible everywhere:

```bash
SRC="<absolute path to the skill folder>"
for dest in \
  "$HOME/.hermes/skills/<name>" \
  "$HOME/.openclaw/skills/<name>" \
  "$HOME/.agents/skills/<name>" \
  "$HOME/.claude/skills/<name>"; do
    mkdir -p "$(dirname "$dest")"
    ln -snf "$SRC" "$dest"
done
```

Symlinks (not copies) — updates to the source folder propagate immediately.

---

## When to use absolute vs relative paths

- `skills.external_dirs` in hermes: use **absolute paths** only. Relative
  paths were broken at one point (hermes issue #9949, since fixed) and are
  still risky depending on the starting cwd of the runtime.
- `skills.load.extraDirs` in OpenClaw: absolute or workspace-relative.
- Symlink targets: always absolute.
