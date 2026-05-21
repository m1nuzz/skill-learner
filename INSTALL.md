# Installing skill-learner

`skill-learner` follows the [AgentSkills](https://agentskills.io/specification)
open standard, so the same skill folder works in hermes-agent, OpenClaw,
Claude Code, and any other compatible host.

## Quick install (recommended)

Clone the repo and run the bundled installer:

```bash
git clone https://github.com/m1nuzz/skill-learner.git
cd skill-learner
bash skill-learner/scripts/install.sh
```

The installer auto-detects which host you have installed and symlinks the
skill folder into the right location.

To install into every known host path at once (useful when you switch
between hosts):

```bash
bash skill-learner/scripts/install.sh --all
```

## Manual install per host

### hermes-agent

```bash
ln -snf "$(pwd)/skill-learner/skill-learner" "$HOME/.hermes/skills/skill-learner"
```

Then `/skill-learner` is available as a slash command in any hermes CLI
or messaging session. See `skill-learner/references/host-paths.md` for
in-repo vs user-scope authoring details.

### OpenClaw

For the active workspace (highest precedence):

```bash
ln -snf "$(pwd)/skill-learner/skill-learner" "<workspace>/skills/skill-learner"
```

For all local agents:

```bash
ln -snf "$(pwd)/skill-learner/skill-learner" "$HOME/.agents/skills/skill-learner"
```

OpenClaw also reads `~/.openclaw/skills/`. See
`skill-learner/references/host-paths.md` for the full precedence list.

### Claude Code

```bash
ln -snf "$(pwd)/skill-learner/skill-learner" "$HOME/.claude/skills/skill-learner"
```

### Generic AgentSkills-compatible host

```bash
ln -snf "$(pwd)/skill-learner/skill-learner" "$HOME/.agents/skills/skill-learner"
```

This is the lowest-common-denominator path. Most AgentSkills-compatible
hosts will pick it up from there.

## Verify the installation

After installation, run:

```bash
ls -la "$HOME/.agents/skills/skill-learner"
# or whichever path you used
```

You should see a symlink pointing to your local clone. Updates pulled via
`git pull` propagate immediately — no re-installation needed.

In your agent (hermes / OpenClaw / Claude Code), confirm the skill is
visible:

- hermes-agent: `hermes skills list` should include `skill-learner`.
- OpenClaw: `openclaw skills list` should include `skill-learner`.
- Claude Code: the skill should appear in `available_skills` on the next
  conversation turn.

## Uninstall

```bash
rm "$HOME/.hermes/skills/skill-learner"   # or whichever path(s) you used
rm "$HOME/.openclaw/skills/skill-learner"
rm "$HOME/.agents/skills/skill-learner"
rm "$HOME/.claude/skills/skill-learner"
```

Symlinks only — the source clone is untouched.
