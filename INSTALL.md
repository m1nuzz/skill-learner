# Installing skill-learner

`skill-learner` follows the [AgentSkills](https://agentskills.io/specification)
open standard. The same skill folder works in hermes-agent, OpenClaw,
Claude Code, and any other compatible host.

The installer **copies** the skill folder directly into the host's skills
directory. You can delete the source clone afterward — the skill stays put.

## One-line install (no clone required)

Recommended for end users:

```bash
curl -fsSL https://raw.githubusercontent.com/m1nuzz/skill-learner/main/skill-learner/scripts/install.sh | bash
```

The script auto-detects your host and downloads the skill folder into the
correct directory. To install into every known host path at once:

```bash
curl -fsSL https://raw.githubusercontent.com/m1nuzz/skill-learner/main/skill-learner/scripts/install.sh | bash -s -- --all
```

To pin to a specific tag or commit:

```bash
curl -fsSL https://raw.githubusercontent.com/m1nuzz/skill-learner/main/skill-learner/scripts/install.sh | bash -s -- --ref v2.0.0
```

## Install from a local clone

If you've already cloned the repo:

```bash
git clone https://github.com/m1nuzz/skill-learner.git
cd skill-learner
bash skill-learner/scripts/install.sh           # auto-detects host
bash skill-learner/scripts/install.sh --all     # installs into every known path
```

The script copies the `skill-learner/` folder into the host's skills
directory; you can `rm -rf` the clone afterward.

## Manual install per host

If you prefer to skip the installer, copy the skill folder directly:

### hermes-agent

Without cloning the repo:

```bash
mkdir -p "$HOME/.hermes/skills/skill-learner"
curl -fsSL https://github.com/m1nuzz/skill-learner/archive/main.tar.gz \
  | tar -xz -C "$HOME/.hermes/skills/skill-learner" \
        --strip-components=2 skill-learner-main/skill-learner
```

Or, from a local clone:

```bash
cp -R skill-learner/skill-learner "$HOME/.hermes/skills/skill-learner"
```

Then `/skill-learner` is available as a slash command. See
`skill-learner/references/host-paths.md` for in-repo vs user-scope authoring
details.

### OpenClaw

For the active workspace (highest precedence):

```bash
cp -R skill-learner/skill-learner "<workspace>/skills/skill-learner"
```

For all local agents:

```bash
mkdir -p "$HOME/.agents/skills"
cp -R skill-learner/skill-learner "$HOME/.agents/skills/skill-learner"
```

OpenClaw also reads `~/.openclaw/skills/`. See
`skill-learner/references/host-paths.md` for the full precedence list.

### Claude Code

```bash
mkdir -p "$HOME/.claude/skills"
cp -R skill-learner/skill-learner "$HOME/.claude/skills/skill-learner"
```

### Generic AgentSkills-compatible host

```bash
mkdir -p "$HOME/.agents/skills"
cp -R skill-learner/skill-learner "$HOME/.agents/skills/skill-learner"
```

This is the lowest-common-denominator path. Most AgentSkills-compatible
hosts will pick it up from there.

## Developer mode (symlink from a clone)

If you intend to edit the skill and want `git pull` updates to propagate
without re-installing, use `--dev`:

```bash
git clone https://github.com/m1nuzz/skill-learner.git ~/code/skill-learner
cd ~/code/skill-learner
bash skill-learner/scripts/install.sh --dev
```

`--dev` creates a symlink to the local clone instead of copying. It refuses
to symlink from `/tmp` or `/var/tmp` to avoid broken links after a reboot —
keep your clone in a persistent path like `~/code/`, `~/projects/`, or
`~/.local/share/`.

## Verify the installation

```bash
ls -la "$HOME/.agents/skills/skill-learner"      # or whichever path applies
cat "$HOME/.agents/skills/skill-learner/SKILL.md" | head -10
```

You should see the frontmatter (`name: skill-learner`, etc.) and a regular
directory (or a symlink, if you used `--dev`).

In your agent, confirm the skill is visible:

- hermes-agent: `hermes skills list` should include `skill-learner`.
- OpenClaw: `openclaw skills list` should include `skill-learner`.
- Claude Code: the skill should appear in `available_skills` on the next
  conversation turn.

## Updating

If you installed via copy (default), re-run the installer to pull the latest
version:

```bash
curl -fsSL https://raw.githubusercontent.com/m1nuzz/skill-learner/main/skill-learner/scripts/install.sh | bash
```

If you installed via `--dev`, run `git pull` in your clone — updates
propagate immediately through the symlink.

## Uninstall

```bash
rm -rf "$HOME/.hermes/skills/skill-learner"   # or whichever path(s) you used
rm -rf "$HOME/.openclaw/skills/skill-learner"
rm -rf "$HOME/.agents/skills/skill-learner"
rm -rf "$HOME/.claude/skills/skill-learner"
```
