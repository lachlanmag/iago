# QA Pass Hidden Listings Refinement Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Update the `iago-daily` workflow so clearly live recruiter, private-advertiser, and aggregator-only listings are saved even when no non-aggregator direct link is available, while adding explicit proof-strength and hidden-employer flags.

**Architecture:** This is a skill-and-schema change, not an application-code change. The implementation updates the operational policy in `.cursor/skills/iago-daily/SKILL.md`, aligns the published config and example schemas with the new behavior, and documents how tracker rows and daily reports should carry proof metadata and inferred employer hints. The current search order, dedup model, and QA gate remain in place, but the acceptance rule changes from de facto direct-link-required to best-available-live-listing-accepted.

**Tech Stack:** Markdown skill files, YAML example schemas, shell verification, git.

**Spec:** `docs/superpowers/specs/2026-07-07-qa-pass-hidden-listings-design.md`

---

## File map

| File | Responsibility after change |
|------|-----------------------------|
| `.cursor/skills/iago-daily/SKILL.md` | Source of truth for daily search rules, listing freshness, dedup, QA gate, tracker writes, and report layout |
| `examples/config.example.yaml` | Published schema and comments for `listing_freshness`, dedup, and QA expectations |
| `examples/seen-jobs.example.yaml` | Published example for dedup index fields, including new proof metadata |
| `README.md` | Optional follow-up only if current user-facing workflow text explicitly claims aggregator pages must never be saved |
| `docs/superpowers/specs/2026-07-07-qa-pass-hidden-listings-design.md` | Approved design reference for the implementation |

---

### Task 1: Update `iago-daily` search rules and intake policy

**Files:**
- Modify: `.cursor/skills/iago-daily/SKILL.md`
- Test: `.cursor/skills/iago-daily/SKILL.md`

- [ ] **Step 1: Update the strict-priority search rules so direct links are preferred, not required**

In `.cursor/skills/iago-daily/SKILL.md`, replace the current rules 9–12 block:

```markdown
9. **Links:** Direct job listing URLs only (not search result pages).
10. **Listing freshness (at intake):** Before adding any role to the candidate pool, check the listing page for expiry/closed signals and closing dates. A visible job description alone is **not** proof the role is open.
11. **Dedup:** Before saving any role, run duplicate detection. Store the **canonical** (most direct) URL only.
12. **QA gate:** Before writing tracker files, run the mandatory **QA gate** (step 5). No role is saved or recommended in top picks until it passes.
```

with:

```markdown
9. **Links:** Prefer the strongest direct listing URL available, but do **not** reject a role only because no non-aggregator direct link exists. Save the best available live listing page, not search result pages.
10. **Listing freshness (at intake):** Before adding any role to the candidate pool, check the best available listing page for expiry/closed signals and closing dates. A visible job description alone is **not** proof the role is open.
11. **Dedup:** Before saving any role, run duplicate detection. Store the strongest verified canonical URL available for that role, even if it is an aggregator page.
12. **QA gate:** Before writing tracker files, run the mandatory **QA gate** (step 5). No role is saved or recommended in top picks until it passes.
```

- [ ] **Step 2: Rewrite listing freshness intake guidance to allow aggregator fallback**

In `.cursor/skills/iago-daily/SKILL.md`, replace the opening paragraph under `### 2a. Listing freshness at intake (required during search)`:

```markdown
For **every** candidate role found during search: before scoring, tiering, or adding to the candidate pool: open the **canonical** listing URL and verify it is still accepting applications.
```

with:

```markdown
For **every** candidate role found during search: before scoring, tiering, or adding to the candidate pool: identify the **best available listing page**, verify it is still accepting applications, and keep trying to upgrade to a stronger direct listing when possible.
```

- [ ] **Step 3: Replace the listing freshness rules table**

In `.cursor/skills/iago-daily/SKILL.md`, replace the current table under `Apply these rules:` with:

```markdown
| Check | Action |
|-------|--------|
| **Closed signals** | If page text matches any `closed_signals` phrase (case-insensitive), **skip immediately**. Log in daily report **Skipped expired / closed**. |
| **Closing date** | If `date_fields` show a date, parse it. Past date → skip. Within `closing_soon_days` → keep but flag **closing soon** in report. |
| **Open proof** | Require evidence from `open_proof`: active Apply control, no expired banner, URL resolves. Follow `board_hints`. |
| **Direct-link upgrade** | If a stronger direct ATS/company/recruiter/gov listing can be found, use it as canonical. |
| **Aggregator fallback** | If no stronger direct page can be found, keep the best available live listing page as canonical if it clearly looks like a real open job listing. |
| **Archived JD trap** | If full JD is visible but an expired/closed banner exists, treat as **closed** regardless of body text. |
```

- [ ] **Step 4: Add proof metadata and inferred-employer notes to intake outputs**

In `.cursor/skills/iago-daily/SKILL.md`, replace:

```markdown
Record on each passing candidate (internal notes until save):

- `listing_verified: YYYY-MM-DD`
- `closes: YYYY-MM-DD` (if known)
- `closing_soon: true/false`
```

with:

```markdown
Record on each passing candidate (internal notes until save):

- `listing_verified: YYYY-MM-DD`
- `closes: YYYY-MM-DD` (if known)
- `closing_soon: true/false`
- `listing_proof: strong|medium|weak`
- `hidden_employer: true|false`
- `canonical_source_type: company_ats|company_careers|recruiter_direct|aggregator|gov_direct|niche_board|council_portal`
- optional `inferred_employer:` note when the employer is hidden but the JD strongly suggests one or more likely companies
```

- [ ] **Step 5: Run a focused file review**

Run:

```bash
cd /Users/lachlanmagee/git-repos/job-search-2
rg -n "Links:|Listing freshness|Aggregator hits|Record on each passing candidate" ".cursor/skills/iago-daily/SKILL.md"
```

Expected: matches show the updated policy text and no leftover "Direct job listing URLs only" rule.

- [ ] **Step 6: Commit**

```bash
cd /Users/lachlanmagee/git-repos/job-search-2
git add .cursor/skills/iago-daily/SKILL.md
git commit -m "feat: allow live aggregator listings in iago daily intake"
```

---

### Task 2: Update dedup and QA gate behavior in `iago-daily`

**Files:**
- Modify: `.cursor/skills/iago-daily/SKILL.md`
- Test: `.cursor/skills/iago-daily/SKILL.md`

- [ ] **Step 1: Rewrite duplicate handling to keep stronger verified URLs, not only more direct ones**

In `.cursor/skills/iago-daily/SKILL.md`, replace:

```markdown
**If duplicate found:** do not create a new tracker row. If the new source has a **more direct** URL per `deduplication.canonical_url_priority`, update the existing entry's `url` and move the old URL to `alternate_urls`.
```

with:

```markdown
**If duplicate found:** do not create a new tracker row. If the new source has a **higher-priority direct** URL per `deduplication.canonical_url_priority`, update the existing entry's `url` and move the old URL to `alternate_urls`. If no stronger direct URL exists, keep the **strongest verified live** URL available, even if it is an aggregator page.
```

- [ ] **Step 2: Replace the aggregator resolution note**

In `.cursor/skills/iago-daily/SKILL.md`, replace:

```markdown
**Aggregator resolution:** When a role is found on an aggregator, follow the apply link to find the employer ATS or careers URL. Save that as `url`. Record the aggregator link in `alternate_urls` only.
```

with:

```markdown
**Aggregator resolution:** When a role is found on an aggregator, follow the apply link to find the employer ATS or careers URL when possible. If a stronger direct listing is found and verified open, save that as `url` and record the aggregator link in `alternate_urls`. If no stronger direct listing can be found, save the live aggregator listing itself as canonical and mark its proof strength explicitly.
```

- [ ] **Step 3: Rewrite QA gate check descriptions**

In `.cursor/skills/iago-daily/SKILL.md`, replace the table rows for `verify_listing_open` and `verify_url_resolves`:

```markdown
| **verify_listing_open** | Re-fetch each candidate's canonical URL. Re-apply `listing_freshness` rules. Fail = exclude from save. |
| **verify_url_resolves** | Canonical URL must not 404. Use browser for SPAs that block curl. |
```

with:

```markdown
| **verify_listing_open** | Re-fetch each candidate's chosen canonical listing page. Re-apply `listing_freshness` rules. Fail = exclude from save. Aggregator pages may pass when they are the best available live listing. |
| **verify_url_resolves** | Canonical URL must resolve to a usable listing page, not necessarily a direct employer site. Use browser for SPAs that block curl. |
```

- [ ] **Step 4: Add lower-confidence and hidden-employer reporting requirements**

In `.cursor/skills/iago-daily/SKILL.md`, update the report layout lists.

Replace the above-the-fold items:

```markdown
2. **New roles this run**: tiered table (Tier, Company, Title, Industry, Flags, Location, Work model, Closes, Link)
```

with:

```markdown
2. **New roles this run**: tiered table (Tier, Company, Title, Industry, Flags, Location, Work model, Closes, Link). Flags should include industry focus, hidden-employer status, and proof strength when relevant.
```

Then insert this new below-the-fold item between `Closing soon` and `QA gate`:

```markdown
10. **Lower-confidence open roles**
11. **QA gate**
12. **Deduped this run**
13. **Sources checked**
```

and remove the old numbering block:

```markdown
10. **QA gate**
11. **Deduped this run**
12. **Sources checked**
```

- [ ] **Step 5: Update tracker-write field expectations**

In `.cursor/skills/iago-daily/SKILL.md`, replace:

```markdown
- Append genuinely **new** roles to `data/applications.yaml` with `status: discovered`, `industry`, `resume_fit`, `resume_fit_note`, canonical `url`, `discovered: YYYY-MM-DD`.
- Append to `data/seen-jobs.yaml` with `first_seen`, canonical `url`, optional `alternate_urls`, `ats_id`, and `listing_verified: YYYY-MM-DD`.
```

with:

```markdown
- Append genuinely **new** roles to `data/applications.yaml` with `status: discovered`, `industry`, `resume_fit`, `resume_fit_note`, canonical `url`, `discovered: YYYY-MM-DD`, and when known `listing_verified`, `listing_proof`, `hidden_employer`, `canonical_source_type`.
- Append to `data/seen-jobs.yaml` with `first_seen`, canonical `url`, optional `alternate_urls`, `ats_id`, `listing_verified: YYYY-MM-DD`, and when known `listing_proof`, `hidden_employer`, `canonical_source_type`.
```

- [ ] **Step 6: Add inferred employer guidance near tracker writes or reporting**

Add this paragraph immediately after the tracker write bullets in `.cursor/skills/iago-daily/SKILL.md`:

```markdown
When the employer is hidden, keep the canonical `company` field generic (for example `Private Advertiser` or recruiter name) unless the listing directly evidences the employer. If the JD strongly suggests one or more likely employers, include that only as an explicitly labeled inferred note or report flag, never as confirmed company identity.
```

- [ ] **Step 7: Run a targeted search to confirm the QA section text**

Run:

```bash
cd /Users/lachlanmagee/git-repos/job-search-2
rg -n "verify_listing_open|verify_url_resolves|Lower-confidence open roles|hidden-employer|inferred" ".cursor/skills/iago-daily/SKILL.md"
```

Expected: each updated concept appears at least once in the skill file.

- [ ] **Step 8: Commit**

```bash
cd /Users/lachlanmagee/git-repos/job-search-2
git add .cursor/skills/iago-daily/SKILL.md
git commit -m "feat: add proof strength and hidden-employer QA rules"
```

---

### Task 3: Update published config guidance in `examples/config.example.yaml`

**Files:**
- Modify: `examples/config.example.yaml`
- Test: `examples/config.example.yaml`

- [ ] **Step 1: Update the canonical URL comment block**

In `examples/config.example.yaml`, replace the `canonical_url_priority` comment:

```yaml
  canonical_url_priority:
    - company_ats
    - gov_direct
    - council_portal
    - company_careers
    - recruiter_direct
    - niche_board
    - aggregator
```

with:

```yaml
  canonical_url_priority:
    # Prefer stronger direct listings first, but if none are available,
    # keep the best verified live listing page even when it is an aggregator.
    - company_ats
    - gov_direct
    - council_portal
    - company_careers
    - recruiter_direct
    - niche_board
    - aggregator
```

- [ ] **Step 2: Replace the aggregator board hint**

In `examples/config.example.yaml`, replace:

```yaml
    aggregators: "Never save from aggregator alone: resolve to ATS and verify open there"
```

with:

```yaml
    aggregators: "Try to resolve to ATS first. If no stronger direct page exists, a clearly live aggregator listing may be saved with proof-strength and hidden-employer flags."
```

- [ ] **Step 3: Add proof metadata comments near `listing_freshness` or `qa_gate`**

Insert this comment block after the `board_hints` section and before `qa_gate:`:

```yaml
# Roles saved from weaker but still credible listing pages should carry:
# - listing_proof: strong | medium | weak
# - hidden_employer: true | false
# - canonical_source_type: company_ats | company_careers | recruiter_direct | aggregator | gov_direct | niche_board | council_portal
# - optional inferred employer note in tracker/reporting when the company is hidden but likely
```

- [ ] **Step 4: Run YAML-safe inspection**

Run:

```bash
cd /Users/lachlanmagee/git-repos/job-search-2
python3 - <<'PY'
import yaml, pathlib
path = pathlib.Path("examples/config.example.yaml")
yaml.safe_load(path.read_text())
print("config example ok")
PY
```

Expected:

```text
config example ok
```

- [ ] **Step 5: Commit**

```bash
cd /Users/lachlanmagee/git-repos/job-search-2
git add examples/config.example.yaml
git commit -m "docs: update config example for hidden listing QA policy"
```

---

### Task 4: Update `examples/seen-jobs.example.yaml` schema comments

**Files:**
- Modify: `examples/seen-jobs.example.yaml`
- Test: `examples/seen-jobs.example.yaml`

- [ ] **Step 1: Replace the comment header**

In `examples/seen-jobs.example.yaml`, replace lines 1–6:

```yaml
# Jobs surfaced in daily runs (dedup index)
#
# canonical url: preferred direct listing URL (company ATS, gov portal, careers site)
# alternate_urls (optional): aggregator or mirror links for the same role
# ats_id (optional): lever/workable/greenhouse/ashby job id when known: used for cross-board dedup
# listing_verified (optional): YYYY-MM-DD last QA/freshness check passed (see config listing_freshness + qa_gate)
```

with:

```yaml
# Jobs surfaced in daily runs (dedup index)
#
# canonical url: strongest verified listing URL available for the role
# alternate_urls (optional): aggregator, recruiter, or mirror links for the same role
# ats_id (optional): lever/workable/greenhouse/ashby job id when known: used for cross-board dedup
# listing_verified (optional): YYYY-MM-DD last QA/freshness check passed
# listing_proof (optional): strong | medium | weak
# hidden_employer (optional): true when the best available listing does not confirm the employer
# canonical_source_type (optional): company_ats | company_careers | recruiter_direct | aggregator | gov_direct | niche_board | council_portal
```

- [ ] **Step 2: Add a commented example row below `seen_jobs: []`**

Replace:

```yaml
seen_jobs: []
```

with:

```yaml
seen_jobs: []
# seen_jobs:
#   - url: https://www.seek.com.au/job/93146030
#     company: Private Advertiser
#     title: Product Manager - HealthTech
#     industry: Healthtech
#     listing_verified: 2026-07-07
#     listing_proof: medium
#     hidden_employer: true
#     canonical_source_type: aggregator
#     first_seen: 2026-07-07
#     alternate_urls:
#       - https://example-recruiter-page.invalid/product-manager-healthtech
```

- [ ] **Step 3: Run YAML-safe inspection**

Run:

```bash
cd /Users/lachlanmagee/git-repos/job-search-2
python3 - <<'PY'
import yaml, pathlib
path = pathlib.Path("examples/seen-jobs.example.yaml")
yaml.safe_load(path.read_text())
print("seen-jobs example ok")
PY
```

Expected:

```text
seen-jobs example ok
```

- [ ] **Step 4: Commit**

```bash
cd /Users/lachlanmagee/git-repos/job-search-2
git add examples/seen-jobs.example.yaml
git commit -m "docs: add proof metadata to seen-jobs example"
```

---

### Task 5: Final verification and optional README sweep

**Files:**
- Modify if needed: `README.md`
- Test: `.cursor/skills/iago-daily/SKILL.md`
- Test: `examples/config.example.yaml`
- Test: `examples/seen-jobs.example.yaml`

- [ ] **Step 1: Search for now-invalid hard requirements**

Run:

```bash
cd /Users/lachlanmagee/git-repos/job-search-2
rg -n "Direct job listing URLs only|Never save from aggregator alone|resolve to ATS and verify open there" .cursor/skills/iago-daily/SKILL.md examples/config.example.yaml README.md
```

Expected:

- no matches in `.cursor/skills/iago-daily/SKILL.md`
- no matches in `examples/config.example.yaml`
- `README.md` may match zero times; if it matches, inspect and update it to align with the new policy before continuing

- [ ] **Step 2: Run all lightweight validation commands**

Run:

```bash
cd /Users/lachlanmagee/git-repos/job-search-2
python3 - <<'PY'
import yaml, pathlib
for rel in ["examples/config.example.yaml", "examples/seen-jobs.example.yaml"]:
    yaml.safe_load(pathlib.Path(rel).read_text())
print("yaml validation ok")
PY
```

Expected:

```text
yaml validation ok
```

- [ ] **Step 3: Inspect the final diff**

Run:

```bash
cd /Users/lachlanmagee/git-repos/job-search-2
git diff -- .cursor/skills/iago-daily/SKILL.md examples/config.example.yaml examples/seen-jobs.example.yaml README.md
```

Expected: diff shows only the policy changes from the approved spec, with no unrelated edits.

- [ ] **Step 4: Commit final documentation alignment if needed**

If `README.md` changed:

```bash
cd /Users/lachlanmagee/git-repos/job-search-2
git add README.md .cursor/skills/iago-daily/SKILL.md examples/config.example.yaml examples/seen-jobs.example.yaml
git commit -m "docs: align daily search guidance with hidden listing policy"
```
If `README.md` did not change and the previous task commits already cover all edits, skip this commit.

