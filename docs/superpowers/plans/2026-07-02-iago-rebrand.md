# Iago Rebrand Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Rename the product from Job Search to Iago across repo identity, skill directories, slash commands, automation, and documentation in a single PR on `rename-app`.

**Architecture:** Single-pass rebrand. Rename two skill directories and one plist file via `git mv`, then update content in place. Slash commands get Iago-primary names with legacy aliases. Natural language triggers stay activity-based per the design spec. No compatibility shims.

**Tech Stack:** Bash, YAML frontmatter (Cursor skills), Markdown docs, macOS launchd plist.

**Spec:** `docs/superpowers/specs/2026-07-02-iago-rebrand-design.md`

---

## File map

| File | Responsibility after rebrand |
|------|------------------------------|
| `.cursor/skills/iago-daily/SKILL.md` | Daily search workflow; `/iago`, `/iago-daily` |
| `.cursor/skills/iago-pipeline-review/SKILL.md` | Pipeline triage; `/iago-pipeline`, `/pipeline-review` |
| `.cursor/skills/update-application/SKILL.md` | Tracker updates; `/iago-update`, `/update-application` |
| `.cursor/skills/company-research/SKILL.md` | Role brief; `/iago-brief`, `/company-research` |
| `.cursor/skills/interview-prep/SKILL.md` | Interview prep; `/iago-interview`, `/interview-prep` |
| `.cursor/skills/resume-feedback/SKILL.md` | Resume review; `/iago-feedback`, `/resume-feedback` |
| `scripts/run-daily-search.sh` | Headless daily runner; points at `iago-daily` |
| `scripts/com.example.iago-daily.plist` | Weekday launchd schedule |
| `README.md` | User-facing quick start, layout, triggers |
| `docs/ROADMAP.md` | Backlog with `lachlanmag/iago` issue links |
| `docs/superpowers/specs/2026-06-26-job-search-workflow-design.md` | Historical spec; update cross-refs |
| `docs/superpowers/specs/2026-07-01-*.md` (4 files) | Historical specs; update cross-refs |

---

### Task 1: Rename directories and plist

**Files:**
- Rename: `.cursor/skills/job-search-daily/` → `.cursor/skills/iago-daily/`
- Rename: `.cursor/skills/job-search-pipeline-review/` → `.cursor/skills/iago-pipeline-review/`
- Rename: `scripts/com.example.job-search-daily.plist` → `scripts/com.example.iago-daily.plist`

- [ ] **Step 1: Rename skill directories with git mv**

```bash
cd /Users/lachlanmagee/git-repos/job-search-2
git mv .cursor/skills/job-search-daily .cursor/skills/iago-daily
git mv .cursor/skills/job-search-pipeline-review .cursor/skills/iago-pipeline-review
git mv scripts/com.example.job-search-daily.plist scripts/com.example.iago-daily.plist
```

- [ ] **Step 2: Verify renames**

```bash
test -d .cursor/skills/iago-daily
test -d .cursor/skills/iago-pipeline-review
test ! -d .cursor/skills/job-search-daily
test ! -d .cursor/skills/job-search-pipeline-review
test -f scripts/com.example.iago-daily.plist
test ! -f scripts/com.example.job-search-daily.plist
```

Expected: all tests pass (exit 0).

- [ ] **Step 3: Commit**

```bash
git add -A
git commit -m "refactor: rename job-search skill dirs and launchd plist to iago"
```

---

### Task 2: Update `iago-daily` skill

**Files:**
- Modify: `.cursor/skills/iago-daily/SKILL.md`

- [ ] **Step 1: Replace YAML frontmatter**

Replace lines 1–7 with:

```yaml
---
name: iago-daily
description: >-
  Run the daily PM/PO/BA job search, surface new listings, and update the
  application tracker. Use when the user says daily job search, job hunt, find
  new jobs, run the job search, run the job search for today, check for jobs
  today, search for new PM roles, what's new on the boards, update the tracker
  from today's search, or runs /iago or /iago-daily.
---
```

- [ ] **Step 2: Update "When to use" section**

Replace the "When to use" bullet list (lines 11–16) with:

```markdown
## When to use

- User asks for a daily/weekly job search
- User wants new PM, Product Owner, or BA roles
- User says "run the job search for today", "check for jobs today", or "what's new on the boards"
- User asks to update the tracker from today's search (add new `discovered` rows; not status changes)
- Cursor Automation or `/loop` triggers this skill
- User runs `/iago` or `/iago-daily`
```

- [ ] **Step 3: Update cross-references in body**

In the same file, replace:
- `job-search-pipeline-review` → `iago-pipeline-review` (suggest line ~199)
- `scripts/com.example.job-search-daily.plist` → `scripts/com.example.iago-daily.plist` (3 occurrences in launchd block)
- `com.example.job-search-daily.plist` → `com.example.iago-daily.plist` (launchctl load line)

- [ ] **Step 4: Commit**

```bash
git add .cursor/skills/iago-daily/SKILL.md
git commit -m "refactor: rebrand iago-daily skill triggers and cross-refs"
```

---

### Task 3: Update `iago-pipeline-review` skill

**Files:**
- Modify: `.cursor/skills/iago-pipeline-review/SKILL.md`

- [ ] **Step 1: Replace YAML frontmatter**

```yaml
---
name: iago-pipeline-review
description: >-
  Review the open application pipeline, re-verify listings, rank roles by fit
  and urgency, and recommend which jobs to shortlist or apply to first. Use when
  the user asks to review the pipeline, prioritize applications, decide what to
  shortlist, triage discovered roles, what should I apply to first, which jobs
  should I shortlist, rank my open roles, weekly pipeline review, help me decide
  what to apply to this week, or runs /iago-pipeline or /pipeline-review.
---
```

- [ ] **Step 2: Update "When to use" and "Not this skill"**

Replace "When to use" bullets to add slash triggers:

```markdown
## When to use

- User wants to triage `discovered` roles and decide what to shortlist
- User asks which open jobs to apply to first this week
- User wants a ranked view of the pipeline without running a new search
- Weekly review after one or more daily search runs
- User says "review my pipeline", "prioritize applications", "triage discovered roles", "what should I apply to first", "which jobs should I shortlist", "rank my open roles", "weekly pipeline review", or "help me decide what to apply to this week"
- User runs `/iago-pipeline` or `/pipeline-review`

**Not this skill:** finding new listings (use `iago-daily`), marking applied/rejected (use `update-application`).
```

- [ ] **Step 3: Update body cross-references**

Replace all `job-search-daily` → `iago-daily` in the file (listing freshness note, tier reference).

- [ ] **Step 4: Commit**

```bash
git add .cursor/skills/iago-pipeline-review/SKILL.md
git commit -m "refactor: rebrand iago-pipeline-review skill triggers and cross-refs"
```

---

### Task 4: Update `update-application` skill

**Files:**
- Modify: `.cursor/skills/update-application/SKILL.md`

- [ ] **Step 1: Replace YAML frontmatter**

```yaml
---
name: update-application
description: >-
  Update pipeline status and dates in applications.yaml. Automatically runs
  company-research when a role is shortlisted and interview-prep when an
  application is submitted. Use when the user shortlists, applies, rejects,
  withdraws, moves to interview, updates tracker status, says shortlist
  [Company], set [Company] to applied, mark [Company] as rejected, withdraw
  [Company], move [Company] to interview, update my tracker, I applied to
  [Company], reject [Company], or runs /iago-update or /update-application.
---
```

- [ ] **Step 2: Update "When to use"**

Add slash line to existing bullets:

```markdown
## When to use

- User shortlists, applies, rejects, withdraws, or changes interview stage
- User says "set [Company] to applied", "shortlist [Company]", "mark [Company] as rejected", "withdraw [Company]", "move [Company] to interview", "update my tracker", "I applied to [Company]", or "reject [Company]"
- User runs `/iago-update` or `/update-application`
- Any workflow that changes `status` in `data/applications.yaml`
```

- [ ] **Step 3: Update "Out of scope" cross-refs**

```markdown
- Discovering new roles (`iago-daily`)
- Pipeline ranking (`iago-pipeline-review`), but pipeline-review should chain `company-research` when it promotes rows to `shortlisted` with user confirmation
```

- [ ] **Step 4: Commit**

```bash
git add .cursor/skills/update-application/SKILL.md
git commit -m "refactor: add iago slash triggers to update-application skill"
```

---

### Task 5: Update `company-research` skill

**Files:**
- Modify: `.cursor/skills/company-research/SKILL.md`

- [ ] **Step 1: Replace YAML frontmatter**

```yaml
---
name: company-research
description: >-
  Produce a role brief for a shortlisted job from the listing, company site, and
  tracker context. Runs automatically when a role is promoted to shortlisted
  (via update-application or pipeline-review). Use when the user shortlists a
  role, asks for a company brief, role brief, research [Company], company brief
  for [Company], role brief for [Company], brief on this role, tell me about
  [Company] for this role, prep a brief before I apply, or runs /iago-brief or
  /company-research.
---
```

- [ ] **Step 2: Update "When to use" and cross-refs**

In "When to use", update the manual trigger line:

```markdown
- User says "research [Company]", "company brief for [Company]", "role brief for [Company]", "brief on this role", "tell me about [Company] for this role", "prep a brief before I apply", `/iago-brief`, or `/company-research`.
```

Replace:
- `job-search-daily` → `iago-daily` in "Not this skill" line
- `job-search-pipeline-review` → `iago-pipeline-review` in caller note (~line 142)

- [ ] **Step 3: Commit**

```bash
git add .cursor/skills/company-research/SKILL.md
git commit -m "refactor: add iago slash triggers to company-research skill"
```

---

### Task 6: Update `interview-prep` skill

**Files:**
- Modify: `.cursor/skills/interview-prep/SKILL.md`

- [ ] **Step 1: Replace YAML frontmatter**

```yaml
---
name: interview-prep
description: >-
  Build interview talking points, STAR stories, and questions to ask from the JD,
  resume, and any company brief. Runs automatically when an application is
  submitted (status applied via update-application). Use when the user applies,
  asks for interview prep, talking points, interview prep for [Company], talking
  points for [role], help me prep for [Company] interview, STAR stories for
  [Company], questions to ask [Company], or runs /iago-interview or
  /interview-prep.
---
```

- [ ] **Step 2: Update "When to use" manual trigger line**

```markdown
- User says "interview prep for [Company]", "talking points for [role]", "help me prep for [Company] interview", "STAR stories for [Company]", "questions to ask [Company]", `/iago-interview`, or `/interview-prep`.
```

- [ ] **Step 3: Commit**

```bash
git add .cursor/skills/interview-prep/SKILL.md
git commit -m "refactor: add iago slash triggers to interview-prep skill"
```

---

### Task 7: Update `resume-feedback` skill

**Files:**
- Modify: `.cursor/skills/resume-feedback/SKILL.md`

- [ ] **Step 1: Replace YAML frontmatter**

```yaml
---
name: resume-feedback
description: >-
  Review a tailored resume JSON against a job description for role fit, ATS
  readiness, and hiring recommendation. Use when the user asks for resume
  feedback, ATS review, tailoring quality check, hiring review of a tailored
  resume, review my tailored resume, ATS review for [Company], check my resume
  against the JD, tailoring quality check, is this resume ready to submit, or
  runs /iago-feedback or /resume-feedback.
disable-model-invocation: true
---
```

- [ ] **Step 2: Update "When to use" and cross-refs**

```markdown
- User says "review my tailored resume", "resume feedback", "ATS review for [Company]", "check my resume against the JD", "tailoring quality check", "is this resume ready to submit", `/iago-feedback`, or `/resume-feedback`
```

Replace in "Not this skill":
- `job-search-daily` / `job-search-pipeline-review` → `iago-daily` / `iago-pipeline-review`

- [ ] **Step 3: Commit**

```bash
git add .cursor/skills/resume-feedback/SKILL.md
git commit -m "refactor: add iago slash triggers to resume-feedback skill"
```

---

### Task 8: Update automation scripts

**Files:**
- Modify: `scripts/run-daily-search.sh`
- Modify: `scripts/com.example.iago-daily.plist`

- [ ] **Step 1: Update `run-daily-search.sh`**

Replace all `JOB_SEARCH_TZ` with `IAGO_TZ` (variable name, comment, and all usages). Replace the PROMPT block skill reference:

```bash
# Default timezone for run date. Override with IAGO_TZ if needed.
IAGO_TZ="${IAGO_TZ:-Australia/Brisbane}"

local_date() {
  TZ="$IAGO_TZ" date "$@"
}
```

In the PROMPT heredoc, change line 49 to:

```
Read and follow the iago-daily skill at .cursor/skills/iago-daily/SKILL.md in this workspace.
```

And `${JOB_SEARCH_TZ}` → `${IAGO_TZ}` in the PROMPT and echo lines.

- [ ] **Step 2: Update plist**

In `scripts/com.example.iago-daily.plist`, replace the XML comment block and Label:

```xml
<!--
  macOS launchd template for weekday daily job search.
  Before use:
    1. Replace __REPO_ROOT__ with the absolute path to your iago clone
    2. Replace com.example.iago-daily with your reverse-DNS label if desired
    3. cp scripts/com.example.iago-daily.plist ~/Library/LaunchAgents/
    4. launchctl load ~/Library/LaunchAgents/com.example.iago-daily.plist
-->
```

```xml
  <string>com.example.iago-daily</string>
```

- [ ] **Step 3: Verify script references**

```bash
rg 'JOB_SEARCH_TZ|job-search-daily|job-search' scripts/
```

Expected: no matches.

- [ ] **Step 4: Commit**

```bash
git add scripts/run-daily-search.sh scripts/com.example.iago-daily.plist
git commit -m "refactor: rebrand daily automation script and launchd plist"
```

---

### Task 9: Update README

**Files:**
- Modify: `README.md`

- [ ] **Step 1: Update title and clone instructions**

```markdown
# Iago

A Cursor-native workflow for sourcing PM/PO/BA roles and tracking applications. No app to deploy: open the repo in Cursor, configure local search criteria, and run a daily agent-driven search that updates YAML trackers and writes a daily report.
```

Quick start block:

```bash
git clone git@github.com:lachlanmag/iago.git
cd iago
bash scripts/init-data.sh
```

- [ ] **Step 2: Update repository layout tree**

```markdown
iago/
  .cursor/skills/
    iago-daily/                      # Daily search; /iago, /iago-daily
    iago-pipeline-review/            # Pipeline triage; /iago-pipeline
    update-application/              # Tracker updates; /iago-update
    company-research/                # Role brief; /iago-brief
    interview-prep/                  # Talking points; /iago-interview
    resume-feedback/                 # Resume review; /iago-feedback
```

- [ ] **Step 3: Update launchd and timezone sections**

```bash
# Replace __REPO_ROOT__ in scripts/com.example.iago-daily.plist with your clone path
cp scripts/com.example.iago-daily.plist ~/Library/LaunchAgents/
launchctl load ~/Library/LaunchAgents/com.example.iago-daily.plist
```

```bash
IAGO_TZ=Australia/Sydney bash scripts/run-daily-search.sh
```

- [ ] **Step 4: Update trigger phrase sections**

Pipeline review section (~line 98):

```markdown
Writes a report to `data/pipeline-reviews/YYYY-MM-DD.md` with ranked apply targets, shortlist promotions, and listing verification. Trigger phrases: pipeline review, prioritize applications, `/iago-pipeline`, `/pipeline-review`.
```

Company research section:

```markdown
Trigger phrases: company brief, role brief, `/iago-brief`, `/company-research`. Runs automatically when you shortlist via `update-application` or pipeline review.
```

Resume feedback section:

```markdown
Trigger phrases: resume feedback, ATS review, `/iago-feedback`, `/resume-feedback`.
```

Interview prep section:

```markdown
Trigger phrases: talking points, `/iago-interview`, `/interview-prep`. Runs automatically when you set status to `applied` via `update-application`.
```

Update applications section: add slash triggers:

```markdown
Trigger phrases: shortlist [Company], set [Company] to applied, `/iago-update`, `/update-application`.
```

- [ ] **Step 5: Add post-merge checklist section before License**

```markdown
## Post-merge checklist (repo rename)

After merging the Iago rebrand:

1. Rename the GitHub repo to `iago` on github.com
2. `git remote set-url origin git@github.com:lachlanmag/iago.git`
3. Optionally rename your local clone directory to `iago`
4. If launchd is loaded: `launchctl unload ~/Library/LaunchAgents/com.example.job-search-daily.plist`
5. Remove the old plist from `~/Library/LaunchAgents/`
6. Set `__REPO_ROOT__` in `scripts/com.example.iago-daily.plist`
7. `cp scripts/com.example.iago-daily.plist ~/Library/LaunchAgents/`
8. `launchctl load ~/Library/LaunchAgents/com.example.iago-daily.plist`
9. Re-open the repo in Cursor from the new folder path
```

- [ ] **Step 6: Commit**

```bash
git add README.md
git commit -m "docs: rebrand README for Iago"
```

---

### Task 10: Update ROADMAP

**Files:**
- Modify: `docs/ROADMAP.md`

- [ ] **Step 1: Bulk replace identifiers**

Run replacements in order (specific before general):

```bash
cd /Users/lachlanmagee/git-repos/job-search-2
# Use editor or sed; order matters:
# job-search-daily → iago-daily
# job-search-pipeline-review → iago-pipeline-review
# job-search-setup → iago-setup
# job-search Cursor workflow → Iago Cursor workflow
# github.com/lachlanmag/job-search → github.com/lachlanmag/iago
```

Updated opening line:

```markdown
Prioritized backlog for the Iago Cursor workflow. v1 search and triage skills (`iago-daily`, `iago-pipeline-review`) and v1.1 application workflow skills (`update-application`, `company-research`, `interview-prep`, `resume-feedback`) are shipped. Remaining items are tracked as [GitHub issues](https://github.com/lachlanmag/iago/issues).
```

Skills table row for setup:

```markdown
| `iago-setup` | Planned | [#1](https://github.com/lachlanmag/iago/issues/1) | Conversational onboarding; writes gitignored `data/` YAML |
```

Daily and pipeline rows:

```markdown
| `iago-daily` | **Shipped** | n/a | Daily search, dedup, QA gate, fit scoring, tracker updates, daily report |
| `iago-pipeline-review` | **Shipped** | n/a | Triage open pipeline, re-verify listings, rank and recommend shortlist/apply priorities |
```

- [ ] **Step 2: Verify no old GitHub URLs remain**

```bash
rg 'lachlanmag/job-search' docs/ROADMAP.md
```

Expected: no matches.

- [ ] **Step 3: Commit**

```bash
git add docs/ROADMAP.md
git commit -m "docs: rebrand ROADMAP for Iago"
```

---

### Task 11: Update historical design specs

**Files:**
- Modify: `docs/superpowers/specs/2026-06-26-job-search-workflow-design.md`
- Modify: `docs/superpowers/specs/2026-07-01-update-application-design.md`
- Modify: `docs/superpowers/specs/2026-07-01-company-research-design.md`
- Modify: `docs/superpowers/specs/2026-07-01-interview-prep-design.md`
- Modify: `docs/superpowers/specs/2026-07-01-resume-feedback-design.md`

- [ ] **Step 1: Apply replacements to each spec file**

In each file, replace in this order:

1. `job-search-daily` → `iago-daily`
2. `job-search-pipeline-review` → `iago-pipeline-review`
3. `job-search-setup` → `iago-setup`
4. `com.example.job-search-daily` → `com.example.iago-daily`
5. `job-search/` → `iago/` (tree roots only; verify context)
6. `github.com/lachlanmag/job-search` → `github.com/lachlanmag/iago`

In `2026-06-26-job-search-workflow-design.md`, also update title if it says "Job Search Cursor Workflow" to note it was the original v1 design (optional subtitle: "now Iago").

- [ ] **Step 2: Verify specs**

```bash
rg 'job-search' docs/superpowers/specs/ --glob '!2026-07-02-iago-rebrand-design.md'
```

Expected: no matches (the rebrand design spec intentionally documents old names).

- [ ] **Step 3: Commit**

```bash
git add docs/superpowers/specs/
git commit -m "docs: update historical specs for Iago rebrand"
```

---

### Task 12: Final verification

**Files:**
- Verify: entire tracked tree

- [ ] **Step 1: Grep for stale identifiers**

```bash
cd /Users/lachlanmagee/git-repos/job-search-2
rg 'job-search' --glob '!docs/superpowers/specs/2026-07-02-iago-rebrand-design.md'
rg 'JOB_SEARCH_TZ'
rg 'lachlanmag/job-search'
rg '/job-search[^-]'
```

Expected: zero matches for each command.

- [ ] **Step 2: Confirm skill directories**

```bash
ls .cursor/skills/
```

Expected: `iago-daily`, `iago-pipeline-review`, `update-application`, `company-research`, `interview-prep`, `resume-feedback`. No `job-search-*` dirs.

- [ ] **Step 3: Spot-check slash triggers in all six skills**

```bash
rg '/iago' .cursor/skills/
```

Expected: `/iago`, `/iago-daily`, `/iago-pipeline`, `/iago-update`, `/iago-brief`, `/iago-interview`, `/iago-feedback` all present across SKILL.md files.

- [ ] **Step 4: Commit plan file (if not yet committed)**

```bash
git add docs/superpowers/plans/2026-07-02-iago-rebrand.md
git commit -m "docs: add Iago rebrand implementation plan"
```

---

## Spec coverage checklist

| Spec requirement | Task |
|------------------|------|
| Skill dir renames | Task 1 |
| Plist rename + label | Task 1, 8 |
| All six skill triggers (slash + NL) | Tasks 2–7 |
| Daily vs update-application disambiguation | Task 2 |
| `IAGO_TZ` env var | Task 8, 9 |
| `run-daily-search.sh` skill path | Task 8 |
| README clone URL + layout | Task 9 |
| ROADMAP issue links + skill names | Task 10 |
| Historical spec cross-refs | Task 11 |
| Post-merge checklist in README | Task 9 |
| Success criteria grep | Task 12 |
