# QA Pass Hidden Listings Refinement: Design

## Goal

Refine the `iago-daily` QA pass so the workflow does **not** reject clearly live job listings just because a non-aggregator direct link is unavailable.

The workflow should still prefer direct ATS or company listings when available, but it must save recruiter, private-advertiser, and aggregator-only roles to the tracker when the page shows credible evidence that the job is live. Uncertainty should be surfaced explicitly through structured flags and daily report sections rather than by silently dropping the role.

No personal tracker data or artifacts are committed to git.

## Scope

### In scope

- Update the `iago-daily` skill guidance for intake, canonical URL selection, and QA gate behavior
- Allow aggregator or hidden-employer listings into the tracker when live-listing proof is sufficient
- Add structured metadata for proof strength and hidden-employer status
- Update example schemas to document the new optional fields
- Update daily report expectations so weaker-proof roles are visible and easy to review

### Out of scope

- Changing ranking logic for role fit, tiering, or industry preference
- Browser automation changes beyond what the current search process already uses
- New headless validation scripts
- Treating inferred employer identity as confirmed company data without evidence

## Problem statement

The current workflow strongly prefers canonical direct listings. In practice, this can become too conservative for:

- SEEK private-advertiser roles
- Recruiter listings
- Aggregator pages that are the only accessible public job page
- Hidden-employer roles where the listing is clearly open but the employer is not named

These are common in recruiter-driven and higher-quality searches. The workflow should treat direct listings as the **best available proof**, not as a hard requirement for tracker intake.

## Architecture

**Approach:** Keep the existing search and QA flow, but change the acceptance rule from **direct-link required in practice** to **best available live listing accepted with explicit confidence metadata**.

Existing flow remains:

```text
search candidate
→ listing freshness at intake
→ canonical URL resolution / best available listing selection
→ dedup
→ score and tier
→ QA gate
→ tracker write + daily report
```

Refined flow:

```text
search candidate
→ check for best direct listing
→ if found, use it
→ else keep best available live listing page
→ assign proof metadata
→ dedup
→ QA gate
→ save if not closed and live proof is sufficient
```

## Canonical URL policy

### Core rule

- Always try to find a direct ATS, company careers, recruiter-direct, or gov listing first.
- If found and verified open, use that URL as canonical.
- If no better page is available, use the **best available live listing page** as canonical, including aggregator pages such as SEEK or LinkedIn.
- A role should **not** be rejected only because a non-aggregator direct link could not be found.

### Best available listing selection

Priority still matters, but only for choosing the best URL, not for deciding whether the role can exist in the tracker:

1. `company_ats`
2. `gov_direct`
3. `council_portal`
4. `company_careers`
5. `recruiter_direct`
6. `niche_board`
7. `aggregator`

If the workflow cannot move higher in that list, it should save the strongest verified lower-priority page rather than dropping the role.

## Acceptance rule

### Accept into tracker when

A candidate may be saved when **all** of the following are true:

1. No explicit closed signal is present
2. The page is a real job listing page, not just a search result page
3. There is enough evidence that the listing is currently live
4. The role passes dedup rules or upgrades an existing weaker URL

### Reject when

A candidate should be rejected only when at least one of the following is true:

1. Explicit closed or expired signal appears
2. The page is not a real listing page
3. There is insufficient evidence that it is a currently live role
4. Dedup shows the same role already exists with equal or better canonical proof

## Proof metadata

### New optional fields for `applications.yaml`

Add the following optional fields:

| Field | Type | Meaning |
|------|------|---------|
| `listing_proof` | enum | `strong`, `medium`, or `weak` |
| `hidden_employer` | boolean | `true` when the employer is not clearly identified from the listing |
| `canonical_source_type` | enum | `company_ats`, `company_careers`, `recruiter_direct`, `aggregator`, `gov_direct`, `niche_board`, `council_portal` |
| `listing_verified` | date | Date the role was verified open during the run |

### New optional fields for `seen-jobs.yaml`

Add the same optional metadata where applicable:

| Field | Type | Meaning |
|------|------|---------|
| `listing_proof` | enum | `strong`, `medium`, or `weak` |
| `hidden_employer` | boolean | Employer hidden from the best available listing |
| `canonical_source_type` | enum | Provenance of canonical URL |
| `listing_verified` | date | Last run date that open proof passed |

## Proof strength model

### `strong`

Use when the listing has high-confidence open proof, such as:

- direct ATS or official company page
- active Apply or Apply now control
- no closed signal
- enough role detail to confirm it is a real listing

### `medium`

Use when the listing is credible and appears live, but proof comes from a non-direct source, such as:

- SEEK, LinkedIn, Hatch, or recruiter page
- active Quick Apply or Apply control
- no closed signal
- substantial job description content

### `weak`

Use when the listing probably is live, but confidence is lower, such as:

- hidden employer
- thin listing metadata
- weaker visibility into application flow
- partial open proof without clear contradiction

`weak` listings are still allowed into the tracker if they meet the acceptance rule and show no closed signals.

## Hidden employer policy

- Hidden-employer roles must be saved when the listing appears live and useful.
- They must be explicitly marked with `hidden_employer: true`.
- Their notes and daily report output should clearly say the employer identity is unverified.
- Hidden-employer status is a caution flag, not a rejection reason.

### Inferred employer hints

As part of the same ticket, the workflow should make a best-effort attempt to infer likely employer identity for hidden-employer listings using evidence such as:

- location
- industry
- salary band
- product domain wording
- customer type
- hiring language
- known watch companies or recently seen matching roles

Rules:

- Inference is optional and best-effort only.
- Any inferred identity must be labeled explicitly as **inferred** or **likely**, never confirmed.
- If multiple plausible employers exist, preserve that ambiguity instead of collapsing to one name.
- Inference should never overwrite the saved `company` field when the listing is genuinely hidden. The canonical tracker company should remain something like `Private Advertiser` or recruiter name unless the employer is directly evidenced.
- Inference is supporting context for prioritization and follow-up, not a replacement for verified company identity.

## QA gate changes

### Intake freshness

Update intake guidance:

- direct links remain preferred
- lack of a direct link is **not** a failure condition
- aggregator pages may serve as canonical when they are the best available verified listing

### `verify_listing_open`

The QA gate should verify the **chosen canonical listing page**, even if it is an aggregator page.

Pass conditions:

- canonical page resolves
- no closed signal
- enough evidence of a live listing page

Fail conditions:

- canonical page shows closed signal
- page is clearly a dead wrapper, generic search page, or unrelated redirect
- evidence is too weak to treat it as a live role

### `verify_url_resolves`

Update wording so success means:

- canonical URL resolves to a usable listing page, not necessarily a direct employer site

### `dedup_all_candidates`

If two pages represent the same role:

- keep the higher-priority canonical page if both are live
- otherwise keep the stronger verified page even if it is an aggregator
- preserve lower-priority links in `alternate_urls` when useful

## Daily report changes

### New roles table

Keep the existing table but make flags more informative. Example flags:

- `★ healthtech`
- `hidden employer`
- `medium proof`
- `weak proof`

### New section

Add a dedicated section:

## Lower-confidence open roles

This section should list roles saved with:

- `listing_proof: medium` or `weak`
- `hidden_employer: true`

Purpose:

- keep these roles visible for follow-up
- avoid burying cautionary context in notes only

If hidden-employer roles have plausible employer hints, include a short note such as:

- `Likely employer (inferred): Best Practice Software`
- `Possible employers (inferred): Best Practice Software, Genie Solutions`

This note must remain clearly marked as inferred.

### QA gate section

Update QA commentary to explain when:

- a direct link was found and promoted to canonical
- no direct link was found, so the aggregator page was retained
- a hidden-employer role was saved with weaker proof

## Example behavior

### Case 1: direct ATS found

- SEEK result found
- apply link resolves to Lever
- Lever page open
- save Lever as canonical
- `listing_proof: strong`
- `canonical_source_type: company_ats`

### Case 2: SEEK private advertiser

- SEEK page is a full listing page
- Quick Apply active
- no closed signal
- employer hidden
- no better direct page found
- save SEEK page as canonical
- `listing_proof: medium` or `weak` depending on page detail
- `hidden_employer: true`
- `canonical_source_type: aggregator`
- add optional note such as `Likely employer (inferred): <name>` only if the JD gives a reasonable evidence-based hint

### Case 3: stale wrapper

- LinkedIn page visible in search
- opening the page falls back to generic search results or unrelated content
- no reliable open proof
- reject from tracker

## Documentation updates

### `.cursor/skills/iago-daily/SKILL.md`

Update these sections:

- Search rules
- Listing freshness at intake
- Duplicate detection
- QA gate
- Daily run report layout

Also add guidance that hidden-employer roles may include inferred employer hints when evidence supports it, but those hints must never be presented as confirmed fact.

### `data/config.yaml` example and schema docs

Document:

- direct-link preference as best-effort, not hard requirement
- proof strength model
- hidden-employer acceptance

### `examples/seen-jobs.example.yaml`

Add commented examples for:

- `listing_proof`
- `hidden_employer`
- `canonical_source_type`

## Testing and validation

- SEEK private advertiser listing saves successfully with `hidden_employer: true`
- Aggregator-only but clearly live listing saves successfully
- Direct ATS page still wins over aggregator when both exist
- Generic search-result or stale wrapper pages still fail QA
- Daily report includes lower-confidence roles explicitly
- Dedup still prevents duplicates when recruiter and ATS versions of the same role are found
- Hidden-employer listing can carry an inferred employer hint without changing the canonical `company` field
- Ambiguous hidden-employer listing can store multiple possible employers as inferred notes rather than forcing one answer

## Success criteria

1. Clearly live recruiter or hidden-employer roles are no longer dropped just because there is no non-aggregator direct link.
2. Direct ATS or company links still win when available.
3. Uncertainty is visible through structured metadata and report sections.
4. The QA pass remains conservative about closed or ambiguous pages without becoming blind to recruiter-led opportunities.

## Future work

| Item | Notes |
|------|-------|
| Smarter employer inference | Improve hidden-employer inference heuristics over time using historical tracker matches and watch-company patterns |
| Confidence-weighted ranking | Use `listing_proof` in apply-priority suggestions if needed |
| Source-specific proof heuristics | Add more detailed board-level rules once real-world edge cases accumulate |
