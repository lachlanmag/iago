# LM Studio Interactive Skills Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Ship interactive Iago in LM Studio chat via khtsly/skills, with tracked `.lmstudio/skills/` wrappers over shared `skills/*/WORKFLOW.md`, install/verify scripts, setup docs, and a three-platform README.

**Architecture:** Mirror the Claude Code wrapper pattern (#33): thin platform `SKILL.md` files handle discovery, REPO_ROOT, and LM Studio tool/fetch notes only. Canonical workflow stays in `skills/`. `install-skills.sh --platform lmstudio` verifies wrappers and prints the Skills Directory path for the plugin (no LM Studio config edits).

**Tech Stack:** Markdown skills, bash scripts, YAML frontmatter. LM Studio + [khtsly/skills](https://lmstudio.ai/khtsly/skills) at runtime (not installed by this repo).

**Spec:** [2026-07-10-lm-studio-interactive-skills-design.md](../specs/2026-07-10-lm-studio-interactive-skills-design.md)  
**Issue:** [#36](https://github.com/lachlanmag/iago/issues/36)  
**Branch:** `issue-36-lm-studio-support`

---

## File map

| Path | Responsibility |
|------|----------------|
| `.lmstudio/skills/<name>/SKILL.md` (×7) | LM Studio entrypoints: frontmatter, WORKFLOW mandate, REPO_ROOT, platform notes |
| `scripts/install-skills.sh` | Add `--platform lmstudio` (verify + print path; `both` stays cursor+claude) |
| `scripts/verify-lm-studio.sh` | Preflight: seven wrappers, print path, config hint |
| `scripts/verify-workspace.sh` | Accept `.lmstudio` as a valid repo skill marker; `--platform lmstudio` |
| `scripts/init-data.sh` | Next-steps mention LM Studio + setup doc |
| `docs/lm-studio-setup.md` | Full interactive setup guide |
| `README.md` | Separate Cursor / Claude Code / LM Studio Getting Started; layout diagram |
| `docs/ROADMAP.md` | Already tracks #36; no required change in this plan unless shipping |
| `docs/superpowers/specs/2026-07-10-lm-studio-interactive-skills-design.md` | Spec (commit if not already) |

Skills with wrappers (same seven as Claude; not `iago-upgrade-version`):

`iago-daily`, `iago-setup`, `iago-pipeline-review`, `update-application`, `company-research`, `interview-prep`, `resume-feedback`

---

### Task 1: Commit design spec

**Files:**
- Create (already on disk): `docs/superpowers/specs/2026-07-10-lm-studio-interactive-skills-design.md`
- Possibly already modified: `docs/ROADMAP.md` (include only if intentional for this commit)

- [ ] **Step 1: Check status**

```bash
cd /Users/lachlanmagee/git-repos/iago-1
git status -sb
git branch --show-current
```

Expected: branch `issue-36-lm-studio-support`; spec file untracked or modified.

- [ ] **Step 2: Commit the spec**

```bash
git add docs/superpowers/specs/2026-07-10-lm-studio-interactive-skills-design.md
git commit -m "$(cat <<'EOF'
docs: add LM Studio interactive skills design spec

Defines .lmstudio wrappers, khtsly plugin path, and three-platform README for #36.
EOF
)"
```

If GPG/signing fails, retry with the same message after unlocking the keyring (do not use `--no-gpg-sign` unless the user asks).

- [ ] **Step 3: Optionally commit ROADMAP separately** (only if `docs/ROADMAP.md` is part of this branch’s intentional #36 tracking update and not already committed)

```bash
git add docs/ROADMAP.md
git commit -m "$(cat <<'EOF'
docs: mark LM Studio (#36) in progress on roadmap
EOF
)"
```

Skip Step 3 if ROADMAP should stay uncommitted or is already committed.

---

### Task 2: Create seven `.lmstudio` skill wrappers

**Files:**
- Create: `.lmstudio/skills/iago-daily/SKILL.md`
- Create: `.lmstudio/skills/iago-setup/SKILL.md`
- Create: `.lmstudio/skills/iago-pipeline-review/SKILL.md`
- Create: `.lmstudio/skills/update-application/SKILL.md`
- Create: `.lmstudio/skills/company-research/SKILL.md`
- Create: `.lmstudio/skills/interview-prep/SKILL.md`
- Create: `.lmstudio/skills/resume-feedback/SKILL.md`

- [ ] **Step 1: Write a generator script and run it**

Create and run this exact script (then delete it, or leave it untracked; do not commit the generator unless you want it as a maintainer tool — prefer delete after use):

```bash
cd /Users/lachlanmagee/git-repos/iago-1
python3 <<'PY'
from pathlib import Path

REPO = Path(".")
CLAUDE = REPO / ".claude" / "skills"
OUT = REPO / ".lmstudio" / "skills"

# Extra bullets after the shared LM Studio block (skill-specific)
EXTRA = {
    "iago-setup": [
        "- Walk setup one section at a time in chat (work model, roles, boards, resume path).",
        "- After install, remind the user to set khtsly Skills Directory if skills are missing.",
    ],
    "iago-daily": [
        "- Prefer `run_command` + curl for board/listing fetches; use optional khtsly web-visit if curl fails.",
        "- No browser MCP and no `/loop`; re-run `/iago-daily` in a new turn if the run stalls.",
    ],
    "iago-pipeline-review": [
        "- Ask clarifying questions in chat for bandwidth, shortlist promotions, or ambiguous names.",
        "- No `/loop`; re-run `/iago-pipeline-review` manually when needed.",
    ],
    "update-application": [
        "- After shortlist/apply writes, follow WORKFLOW chaining into company-research / interview-prep in the same turn when possible.",
    ],
    "company-research": [
        "- Ask in chat when company/title or JD source is ambiguous.",
        "- For SPA/career pages that block curl, try optional khtsly web-visit.",
    ],
    "interview-prep": [
        "- Ask in chat when company/title or JD/resume paths are ambiguous.",
    ],
    "resume-feedback": [
        "- Ask in chat when JD path or resume source is ambiguous.",
    ],
}

TITLES = {
    "iago-daily": "Daily job search (LM Studio)",
    "iago-setup": "Iago setup (LM Studio)",
    "iago-pipeline-review": "Pipeline review (LM Studio)",
    "update-application": "Update application (LM Studio)",
    "company-research": "Company research (LM Studio)",
    "interview-prep": "Interview prep (LM Studio)",
    "resume-feedback": "Resume feedback (LM Studio)",
}

SHARED = """## LM Studio-specific

- Ask clarifying questions in chat (no Cursor `AskQuestion` tool).
- Read/write tracker and reports with plugin tools (`read_file`, `write_file`, `patch_file`).
- Run repo scripts with `run_command` (e.g. `bash \"$REPO_ROOT/scripts/verify-workspace.sh\"`).
- Web fetch: `run_command` + curl by default; optional [web-visit](https://lmstudio.ai/khtsly) if pages block curl.
- No headless runner and no `/loop`; re-activate the skill in chat. Automation is tracked in [#40](https://github.com/lachlanmag/iago/issues/40).
"""

for name, title in TITLES.items():
    src = CLAUDE / name / "SKILL.md"
    text = src.read_text()
    if not text.startswith("---"):
        raise SystemExit(f"missing frontmatter: {src}")
    end = text.index("---", 3)
    front = text[: end + 3]

    body = f"""{front}

# {title}

**Mandatory:** Read and follow `$REPO_ROOT/skills/{name}/WORKFLOW.md` before executing this skill. Do not skip or summarize it.

## Resolve REPO_ROOT (always first)

Set `REPO_ROOT` before reading files or running scripts.

| Method | When |
|--------|------|
| Workspace contains `.lmstudio/skills/{name}/SKILL.md` | `REPO_ROOT` = workspace root |
| Skill loaded from this repo | `REPO_ROOT` = parent of `.lmstudio/skills` |
| Nested under parent workspace | `bash \"$REPO_ROOT/scripts/verify-workspace.sh\"`; `REPO_ROOT` = parent of `scripts/` |
| Still unknown | Ask user for the Iago clone path |

When workspace root ≠ `REPO_ROOT`, prefix all Iago paths and scripts with `$REPO_ROOT`.

{SHARED}"""
    for line in EXTRA[name]:
        body += line + "\n"

    dest = OUT / name / "SKILL.md"
    dest.parent.mkdir(parents=True, exist_ok=True)
    dest.write_text(body)
    print(f"wrote {dest}")
PY
```

- [ ] **Step 2: Spot-check one wrapper**

```bash
head -n 40 .lmstudio/skills/iago-daily/SKILL.md
wc -l .lmstudio/skills/*/SKILL.md
```

Expected: frontmatter present; mandatory WORKFLOW line; `.lmstudio` in REPO_ROOT table; each file under ~80 lines.

- [ ] **Step 3: Confirm frontmatter matches Claude**

```bash
for s in iago-daily iago-setup iago-pipeline-review update-application company-research interview-prep resume-feedback; do
  echo "=== $s ==="
  diff <(sed -n '1,/^---$/p' ".claude/skills/$s/SKILL.md" | head -n -0) \
       <(sed -n '1,/^---$/p' ".lmstudio/skills/$s/SKILL.md") || true
done
```

Expected: no diff on the YAML frontmatter block (first `---` … second `---`).

- [ ] **Step 4: Commit**

```bash
git add .lmstudio/skills
git commit -m "$(cat <<'EOF'
feat: add LM Studio thin skill wrappers over shared workflows

Seven .lmstudio/skills entrypoints for khtsly/skills discovery (#36).
EOF
)"
```

---

### Task 3: Extend `install-skills.sh` for `lmstudio`

**Files:**
- Modify: `scripts/install-skills.sh`

- [ ] **Step 1: Write a failing check**

```bash
bash scripts/install-skills.sh --platform lmstudio; echo exit:$?
```

Expected before change: `error: invalid platform: lmstudio` and non-zero exit.

- [ ] **Step 2: Update usage and platform validation**

In `scripts/install-skills.sh`, change usage to:

```bash
Usage: $(basename "$0") [--platform cursor|claude|lmstudio|both]

Install or verify Iago skills for a platform.

Platforms:
  cursor    Symlink .cursor/skills/* → ~/.cursor/skills/* (default)
  claude    Symlink .claude/skills/* → ~/.claude/skills/*
  lmstudio  Verify .lmstudio/skills/* and print Skills Directory path for khtsly
  both      Install for Cursor and Claude Code (not LM Studio)
```

Change the valid-platform case to:

```bash
case "$platform" in
  cursor|claude|lmstudio|both) ;;
  *)
    echo "error: invalid platform: $platform (expected cursor, claude, lmstudio, or both)" >&2
    usage >&2
    exit 1
    ;;
esac
```

- [ ] **Step 3: Add `install_lmstudio` and wire the case**

Add before the final `case "$platform"`:

```bash
REQUIRED_LMSTUDIO_SKILLS=(
  iago-daily
  iago-setup
  iago-pipeline-review
  update-application
  company-research
  interview-prep
  resume-feedback
)

install_lmstudio() {
  echo "=== LM Studio ==="
  local src="$REPO_ROOT/.lmstudio/skills"
  if [[ ! -d "$src" ]]; then
    echo "error: skills not found at $src" >&2
    return 1
  fi

  local missing=0
  local name
  for name in "${REQUIRED_LMSTUDIO_SKILLS[@]}"; do
    if [[ ! -f "$src/$name/SKILL.md" ]]; then
      echo "missing: $src/$name/SKILL.md" >&2
      missing=1
    fi
  done
  if [[ "$missing" -ne 0 ]]; then
    echo "error: incomplete .lmstudio/skills tree" >&2
    return 1
  fi

  echo "Skills Directory Path (paste into khtsly/skills plugin):"
  echo "  $src"
  echo
  echo "Next steps:"
  echo "  1. Install khtsly/skills from the LM Studio Hub"
  echo "  2. Set the plugin Skills Directory to the path above"
  echo "  3. Open LM Studio chat with workspace = $REPO_ROOT"
  echo "  4. Run: bash \"$REPO_ROOT/scripts/verify-lm-studio.sh\""
  echo "  5. In chat: /iago-setup"
  echo "Full guide: $REPO_ROOT/docs/lm-studio-setup.md"
}
```

Extend the final case:

```bash
case "$platform" in
  cursor)
    install_cursor
    ;;
  claude)
    install_claude
    ;;
  lmstudio)
    install_lmstudio
    ;;
  both)
    install_cursor
    echo
    install_claude
    ;;
esac
```

Do **not** call `install_lmstudio` from `both`.

- [ ] **Step 4: Re-run checks**

```bash
bash scripts/install-skills.sh --platform lmstudio
bash scripts/install-skills.sh --platform both | head -20
```

Expected: lmstudio prints absolute `.lmstudio/skills` path and exit 0; `both` still only Cursor + Claude sections.

- [ ] **Step 5: Commit**

```bash
git add scripts/install-skills.sh
git commit -m "$(cat <<'EOF'
feat: add install-skills.sh --platform lmstudio

Verifies .lmstudio wrappers and prints khtsly Skills Directory path.
EOF
)"
```

---

### Task 4: Add `verify-lm-studio.sh`

**Files:**
- Create: `scripts/verify-lm-studio.sh`

- [ ] **Step 1: Create the script**

```bash
#!/usr/bin/env bash
# Preflight for interactive Iago in LM Studio (khtsly/skills).
# Exit 0: wrappers present.
# Exit 1: missing wrappers or incomplete tree.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SKILLS_DIR="$REPO_ROOT/.lmstudio/skills"

REQUIRED_SKILLS=(
  iago-daily
  iago-setup
  iago-pipeline-review
  update-application
  company-research
  interview-prep
  resume-feedback
)

echo "repo_root=$REPO_ROOT"
echo "skills_dir=$SKILLS_DIR"

if [[ ! -d "$SKILLS_DIR" ]]; then
  echo "lmstudio_skills=no"
  echo "hint=Missing .lmstudio/skills; check out branch with LM Studio wrappers or re-clone." >&2
  exit 1
fi

missing=0
for name in "${REQUIRED_SKILLS[@]}"; do
  if [[ ! -f "$SKILLS_DIR/$name/SKILL.md" ]]; then
    echo "missing=$SKILLS_DIR/$name/SKILL.md" >&2
    missing=1
  fi
done

if [[ "$missing" -ne 0 ]]; then
  echo "lmstudio_skills=incomplete"
  exit 1
fi

echo "lmstudio_skills=yes"
echo "skills_directory_path=$SKILLS_DIR"
echo "hint=Paste skills_directory_path into khtsly/skills; open LM Studio chat with workspace=$REPO_ROOT"

if [[ ! -f "$REPO_ROOT/data/config.yaml" ]]; then
  echo "config=missing"
  echo "hint=Run /iago-setup in LM Studio chat (or bash \"$REPO_ROOT/scripts/init-data.sh\" then edit data/config.yaml)"
else
  echo "config=present"
fi

exit 0
```

- [ ] **Step 2: Make executable and run**

```bash
chmod +x scripts/verify-lm-studio.sh
bash scripts/verify-lm-studio.sh
```

Expected: `lmstudio_skills=yes`, prints `skills_directory_path=.../.lmstudio/skills`, exit 0.

- [ ] **Step 3: Negative check**

```bash
mv .lmstudio/skills/iago-daily/SKILL.md /tmp/iago-daily-SKILL.md.bak
bash scripts/verify-lm-studio.sh; echo exit:$?
mv /tmp/iago-daily-SKILL.md.bak .lmstudio/skills/iago-daily/SKILL.md
```

Expected: exit 1 while file is moved; exit 0 after restore.

- [ ] **Step 4: Commit**

```bash
git add scripts/verify-lm-studio.sh
git commit -m "$(cat <<'EOF'
feat: add verify-lm-studio.sh preflight for interactive path
EOF
)"
```

---

### Task 5: Teach `verify-workspace.sh` about `.lmstudio`

**Files:**
- Modify: `scripts/verify-workspace.sh`

- [ ] **Step 1: Extend usage and platform handling**

Update usage platforms to:

```text
  both      Check .cursor/, .claude/, and .lmstudio/ (default: any one present)
  cursor    Check .cursor/skills/iago-setup/SKILL.md only
  claude    Check .claude/skills/iago-setup/SKILL.md only
  lmstudio  Check .lmstudio/skills/iago-setup/SKILL.md only
```

Add:

```bash
lmstudio_skill="$REPO_ROOT/.lmstudio/skills/iago-setup/SKILL.md"
```

Replace the skills_ok case with:

```bash
case "$platform" in
  cursor)
    [[ -f "$cursor_skill" ]] && skills_ok=true
    ;;
  claude)
    [[ -f "$claude_skill" ]] && skills_ok=true
    ;;
  lmstudio)
    [[ -f "$lmstudio_skill" ]] && skills_ok=true
    ;;
  both)
    [[ -f "$cursor_skill" || -f "$claude_skill" || -f "$lmstudio_skill" ]] && skills_ok=true
    ;;
  *)
    echo "error: invalid platform: $platform (expected cursor, claude, lmstudio, or both)" >&2
    usage >&2
    exit 1
    ;;
esac
```

Update nested/external hints so LM Studio users are not told only Cursor/Claude:

```bash
install_hint="bash \"$REPO_ROOT/scripts/install-skills.sh\" --platform both   # or --platform lmstudio"
open_hint="Open $REPO_ROOT as the workspace root (Cursor, Claude Code, or LM Studio chat)"
```

Also update the usage line:

```bash
Usage: $(basename "$0") [--platform cursor|claude|lmstudio|both] [workspace-root]
```

And the `--platform` help text at the top comment: mention LM Studio.

- [ ] **Step 2: Test**

```bash
bash scripts/verify-workspace.sh --platform lmstudio
bash scripts/verify-workspace.sh --platform both
bash scripts/verify-workspace.sh --platform cursor
```

Expected: all exit 0 when run from repo root with wrappers present.

- [ ] **Step 3: Commit**

```bash
git add scripts/verify-workspace.sh
git commit -m "$(cat <<'EOF'
feat: recognize .lmstudio skills in verify-workspace.sh
EOF
)"
```

---

### Task 6: Update `init-data.sh` next steps

**Files:**
- Modify: `scripts/init-data.sh`

- [ ] **Step 1: Extend the echo block**

After the existing Cursor/Claude next-steps lines (around the final `echo` block), ensure users see LM Studio. Replace the next-steps section with:

```bash
echo "Next steps:"
echo "  1. Pick a platform and run setup in chat: Set up job search  (or edit data/config.yaml manually)"
echo "     - Cursor: open repo root, then /iago-setup"
echo "     - Claude Code: open repo root (or install-skills.sh --platform claude), then /iago-setup"
echo "     - LM Studio: bash \"$REPO_ROOT/scripts/install-skills.sh\" --platform lmstudio"
echo "       then follow docs/lm-studio-setup.md and run /iago-setup in chat"
echo "  2. Parent/monorepo workspace (Cursor/Claude): bash \"$REPO_ROOT/scripts/install-skills.sh\" --platform both"
echo "  3. Keep running daily search from chat, or schedule via your platform's runner docs"
```

Keep the existing `install-skills.sh --platform both` call for Cursor/Claude global install as-is (do not auto-run lmstudio there).

- [ ] **Step 2: Sanity check**

```bash
# Dry-read only if data/ already exists; otherwise run init in a throwaway copy
grep -n "LM Studio" scripts/init-data.sh
```

Expected: LM Studio lines present.

- [ ] **Step 3: Commit**

```bash
git add scripts/init-data.sh
git commit -m "$(cat <<'EOF'
docs: mention LM Studio in init-data.sh next steps
EOF
)"
```

---

### Task 7: Write `docs/lm-studio-setup.md`

**Files:**
- Create: `docs/lm-studio-setup.md`

- [ ] **Step 1: Create the guide**

Write this file (adjust nothing material without updating the spec):

```markdown
# LM Studio setup (interactive)

Run Iago skills inside **LM Studio chat** using the [khtsly/skills](https://lmstudio.ai/khtsly/skills) plugin. Canonical workflows live in `skills/`; LM Studio entrypoints are thin wrappers under `.lmstudio/skills/`.

Headless / scheduled runs are **not** covered here. See [#40](https://github.com/lachlanmag/iago/issues/40).

## Prerequisites

- [LM Studio](https://lmstudio.ai/) with a **tool-capable** local model
  - Recommended: `qwen/qwen2.5-coder-14b` or `qwen/qwen3.5-9b`
- Network access for job boards
- This Iago clone on disk

## 1. Install the skills plugin

1. Open LM Studio → Hub (or Plugins).
2. Install **[khtsly/skills](https://lmstudio.ai/khtsly/skills)**.
3. Do not use other skills-plugin forks for this guide (unsupported in v1).

## 2. Point the plugin at Iago wrappers

From your clone:

```bash
cd /path/to/iago
bash scripts/install-skills.sh --platform lmstudio
```

Copy the printed **Skills Directory Path** (it should end in `.lmstudio/skills`).

In the khtsly/skills plugin settings, set **Skills Directory** to that absolute path.

## 3. Open chat on the repo root

In LM Studio, open a chat whose **workspace / project folder** is the Iago repo root (the folder that contains `skills/`, `.lmstudio/`, `scripts/`, and `data/`).

If the workspace is a parent folder, either reopen on the Iago root or set `REPO_ROOT` when the skill asks.

## 4. Preflight

```bash
bash scripts/verify-lm-studio.sh
```

Expect `lmstudio_skills=yes` and a printed `skills_directory_path`.

## 5. First-time setup

In LM Studio chat:

```text
/iago-setup
Set up job search
```

Complete the prompts in chat. This should create or update `data/config.yaml`.

## 6. Daily search

```text
/iago-daily
Run the daily job search for today
```

Expect updates under `data/daily-runs/` and `data/applications.yaml` (or your configured tracker).

### Fetching pages

- Default: `run_command` + `curl`
- If a site blocks curl or is a heavy SPA, install khtsly **web-visit** (optional) and retry
- Record gaps in the daily report rather than inventing listings

## 7. Other skills

Same slash names as Cursor/Claude, for example:

| Skill | Example |
|-------|---------|
| Pipeline review | `/iago-pipeline-review` |
| Update tracker | `/update-application` |
| Company brief | `/company-research` |
| Resume feedback | `/resume-feedback` |
| Interview prep | `/interview-prep` |

## Troubleshooting

| Symptom | Fix |
|---------|-----|
| Skill not found / empty skills list | Re-check Skills Directory path; re-run `install-skills.sh --platform lmstudio` |
| Writes go to the wrong folder | Workspace must be the Iago repo root |
| Model ignores tools | Switch to a stronger coder model; shorten the turn |
| Curl fails on boards | Try web-visit plugin, or note the gap and continue |
| Need unattended daily runs | Out of scope here → [#40](https://github.com/lachlanmag/iago/issues/40) |

## Related

- Design: `docs/superpowers/specs/2026-07-10-lm-studio-interactive-skills-design.md`
- Claude Code / Cursor: see README Getting Started
- Automation follow-up: [#40](https://github.com/lachlanmag/iago/issues/40)
```

- [ ] **Step 2: Commit**

```bash
git add docs/lm-studio-setup.md
git commit -m "$(cat <<'EOF'
docs: add LM Studio interactive setup guide
EOF
)"
```

---

### Task 8: Restructure README Getting Started for three platforms

**Files:**
- Modify: `README.md`

- [ ] **Step 1: Soften the intro**

Replace the second paragraph (Cursor-native only) with:

```markdown
A multi-platform workflow for sourcing tech roles and tracking applications. Use **Cursor**, **Claude Code**, or **LM Studio** (local models). Right now it is built around my Product Management search, though the setup skill and config can adapt to other roles. No app to deploy: clone the repo, pick a platform, run setup in chat, and kick off a daily agent-driven search that updates YAML trackers and writes a daily report.
```

- [ ] **Step 2: Replace Prerequisites + steps 2–3 + scattered platform sections**

Replace from `## Getting Started` through the end of the current `### Claude Code skills` section (before `## How It Works`) with a structure like this. Keep the existing **Upgrading Iago** section where it is today (after Cursor-specific upgrade content). Practical approach:

1. Keep `### 1. Clone` as-is.
2. Replace `### 2. Run setup in Cursor` and `### 3. Run your first search` and the later `### Cursor skills` / `### Claude Code skills` blocks with **Choose your platform** subsections.
3. Move detailed Cursor parent-workspace / global-install notes under `#### Cursor`.
4. Move Claude install notes under `#### Claude Code`.
5. Add `#### LM Studio` linking to `docs/lm-studio-setup.md`.

Concrete README fragment to insert after clone:

```markdown
### Prerequisites

- Network access for job board search
- One of:
  - [Cursor](https://cursor.com) with Agent
  - [Claude Code](https://docs.anthropic.com/en/docs/claude-code)
  - [LM Studio](https://lmstudio.ai/) with the [khtsly/skills](https://lmstudio.ai/khtsly/skills) plugin
- For Cursor headless runs: `cursor agent login` (once)

### 1. Clone

```bash
cd ~/projects
git clone git@github.com:lachlanmag/iago.git
cd iago
```

### 2. Choose your platform

Canonical workflow content lives in `skills/` at the repo root. Each platform has thin entrypoints only.

#### Cursor

1. Open the **Iago repo root** in Cursor (the folder that contains `.cursor/skills/` and `skills/`).
2. In chat: `Set up job search` or `/iago-setup`.
3. Then: `Run the daily job search` or `/iago-daily`.

Skills ship in `.cursor/skills/` and are discovered automatically when this repo is the workspace root.

**Parent workspace** (Obsidian vault + several repos): prefer opening the Iago folder, or run `bash scripts/install-skills.sh --platform cursor` (or `--platform both`) and reload the window. Check **Cursor Settings → Customize → Skills**. Layout check: `bash scripts/verify-workspace.sh`.

**Headless daily search** uses the Cursor Agent CLI (`bash scripts/run-daily-search.sh`). See [How It Works](#how-it-works) / headless notes below.

#### Claude Code

1. Open the Iago repo root as your workspace (folder containing `.claude/skills/` and `skills/`).
2. Same chat triggers as Cursor (`Set up job search`, `/iago-daily`, …).

For a **parent workspace**:

```bash
cd /path/to/your/iago-clone
bash scripts/install-skills.sh --platform claude
```

Headless Claude Code daily search is deferred to [#34](https://github.com/lachlanmag/iago/issues/34).

#### LM Studio

Interactive local models via [khtsly/skills](https://lmstudio.ai/khtsly/skills):

```bash
cd /path/to/your/iago-clone
bash scripts/install-skills.sh --platform lmstudio
```

Paste the printed path into the plugin **Skills Directory**, open LM Studio chat with **workspace = Iago repo root**, then `/iago-setup` and `/iago-daily`.

Full steps, model tips, and troubleshooting: **[docs/lm-studio-setup.md](docs/lm-studio-setup.md)**.

Automation / headless with Pi is tracked in [#40](https://github.com/lachlanmag/iago/issues/40).

### 3. Manual config alternative

Run `bash scripts/init-data.sh`, then edit `data/config.yaml` directly (`profile.resume_path`, `profile.location`, role priorities, search sources). Optional: `profile.output_language` for research, prep, and feedback artifacts.
```

Then keep `## Upgrading Iago` (Cursor-oriented is fine for v1; optionally add one line: “On Claude Code / LM Studio, pull latest then re-run the platform install/verify step in the setup doc.”).

Remove the old standalone `### Cursor skills` and `### Claude Code skills` sections so they are not duplicated.

- [ ] **Step 3: Update Repository Layout**

In the layout diagram, change the skills comment to “shared by all platforms” and add:

```text
  .lmstudio/skills/                  # LM Studio skill entrypoints (khtsly/skills)
    iago-daily/
    iago-setup/
    iago-pipeline-review/
    update-application/
    company-research/
    interview-prep/
    resume-feedback/
```

Add `verify-lm-studio.sh` to the scripts line comment.

- [ ] **Step 4: Skim for leftover “Cursor-only product” claims** in Getting Started that contradict the three-platform intro. Leave deeper How It Works examples Cursor-flavored if needed.

- [ ] **Step 5: Commit**

```bash
git add README.md
git commit -m "$(cat <<'EOF'
docs: split README Getting Started by Cursor, Claude, and LM Studio
EOF
)"
```

---

### Task 9: Structural verification + smoke checklist

**Files:**
- None required (checklist evidence goes in the PR or a short note in the plan’s completion comment)

- [ ] **Step 1: Structural checks**

```bash
cd /Users/lachlanmagee/git-repos/iago-1

for s in iago-daily iago-setup iago-pipeline-review update-application company-research interview-prep resume-feedback; do
  test -f ".lmstudio/skills/$s/SKILL.md" || echo "MISSING $s"
  grep -q "skills/$s/WORKFLOW.md" ".lmstudio/skills/$s/SKILL.md" || echo "NO WORKFLOW REF $s"
done

# Business logic should not be duplicated into wrappers
! grep -R "QA gate" .lmstudio/skills || echo "unexpected QA gate copy in wrappers"

bash scripts/install-skills.sh --platform lmstudio
bash scripts/verify-lm-studio.sh
bash scripts/verify-workspace.sh --platform lmstudio
bash scripts/install-skills.sh --platform both | grep -i lmstudio && echo "FAIL: both should not install lmstudio" || echo "OK: both excludes lmstudio"
```

Expected: no MISSING/NO WORKFLOW REF; no QA gate in wrappers; scripts exit 0; `both` does not mention installing lmstudio skills into a home dir.

- [ ] **Step 2: Interactive mid-bar smoke (manual in LM Studio)**

Record model id used:

1. Plugin + Skills Directory + workspace = repo root  
2. `/iago-setup` → `data/config.yaml` exists  
3. `/iago-daily` → daily report under `data/daily-runs/` and tracker updated  

Optional (note skip reason if model fails): pipeline-review, apply-chain, resume-feedback.

- [ ] **Step 3: Commit plan file if not already committed**

```bash
git add docs/superpowers/plans/2026-07-10-lm-studio-interactive-skills.md
git commit -m "$(cat <<'EOF'
docs: add LM Studio interactive skills implementation plan
EOF
)"
```

---

### Task 10: Sync GitHub issue #36 with the design

**Files:** none (GitHub)

- [ ] **Step 1: Update issue body**

Use `gh issue edit 36` so the architecture section says:

- Plugin Skills Directory → `.lmstudio/skills/` (not `.cursor/skills/`)
- Thin wrappers over `skills/*/WORKFLOW.md`
- Link design + plan paths
- Mid-bar acceptance
- README three-platform Getting Started

Keep #40 as the Pi/automation follow-up.

- [ ] **Step 2: Add a short comment**

```bash
gh issue comment 36 --body "$(cat <<'EOF'
Design and plan landed on \`issue-36-lm-studio-support\`:

- Spec: \`docs/superpowers/specs/2026-07-10-lm-studio-interactive-skills-design.md\`
- Plan: \`docs/superpowers/plans/2026-07-10-lm-studio-interactive-skills.md\`

v1 plugin target is \`.lmstudio/skills/\` (Claude-style thin wrappers), not \`.cursor/skills/\`.
EOF
)"
```

---

## Spec coverage self-check

| Spec requirement | Task |
|------------------|------|
| `.lmstudio` wrappers ×7 | Task 2 |
| `install-skills.sh --platform lmstudio`; `both` unchanged | Task 3 |
| `verify-lm-studio.sh` | Task 4 |
| `verify-workspace.sh` recognizes `.lmstudio` | Task 5 |
| `init-data.sh` next steps | Task 6 |
| `docs/lm-studio-setup.md` | Task 7 |
| README three platforms + layout | Task 8 |
| Mid-bar smoke | Task 9 |
| Update #36 body | Task 10 |
| Design committed | Task 1 |
| khtsly only; curl + optional web-visit | Tasks 2, 7 |
| No Pi / Hub plugin / dirty-data | Out of scope (not tasked) |
| Ollama | Out of scope (#37) |

---

## Execution handoff

Plan complete and saved to `docs/superpowers/plans/2026-07-10-lm-studio-interactive-skills.md`.

**Two execution options:**

1. **Subagent-Driven (recommended)** — dispatch a fresh subagent per task, review between tasks  
2. **Inline Execution** — run tasks in this session with executing-plans and checkpoints  

Which approach?
