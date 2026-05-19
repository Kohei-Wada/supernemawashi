---
name: nemawashi-check
description: Use when user wants to check which profiles need re-analysis - scans all profiles for staleness and new unanalyzed data
---

# Profile Freshness

Triage profiles along two axes — **analysis freshness** (is the recorded analysis old?) and **subject activity** (has the person been active recently?) — and offer re-analysis for the rows where it actually pays off.

## When to Use

- User says "check profiles", "which profiles are stale?", "who needs re-analysis?"
- User says "profile status" or "freshness check"

## Process

### Step 1: Run the helper script

Invoke `./check.sh` (relative to the plugin root — the file lives alongside this skill in the same plugin). No arguments needed; it defaults to `~/.local/share/supernemawashi/profiles`.

The script is the **single source of truth** for classification. Do not re-derive `analysis_status` or `activity_status` from raw file contents in this skill — the script already merges facts.jsonl + facts.md, handles month-precision dates, and computes the inactivity window. Keeping the logic in one place prevents drift between the bash and the prose.

The script emits a TSV with these columns (one row per profile, plus a header):

| Column | Meaning |
|---|---|
| `name` | Profile directory name |
| `analyzed_date` | Last analysis date or `never` |
| `days_ago` | Days since analysis (or `-` if never) |
| `analyzed_facts` | facts_count recorded at last analysis |
| `current_facts` | Current fact count across facts.jsonl + facts.md |
| `latest_fact_date` | Most recent fact date or `-` |
| `inactivity_days` | Days since the latest fact (or `-`) |
| `analysis_status` | `never_analyzed` / `stale` / `fresh` / `no_data` |
| `activity_status` | `active` (<30d) / `inactive` (30-90d) / `dormant` (>90d) / `unknown` |

Thresholds (7 / 30 / 90 days) are constants near the top of the script — tune them there, not in this prose.

### Step 2: Render the Dashboard

Group rows by the action implied by combining `analysis_status` and `activity_status`. Suppress empty sections.

| Section | Rows that match |
|---|---|
| **Needs Re-analysis** (active subjects) | `analysis_status ∈ {stale, never_analyzed}` AND `activity_status == active` |
| **Inactive Subjects** | `activity_status == inactive` (any analysis status) |
| **Archive Candidates** | `activity_status == dormant` (any analysis status) |
| **Up to Date** | `analysis_status == fresh` AND `activity_status == active` |
| **No Data** | `analysis_status == no_data` — suggest `nemawashi-collect` first |

Render as:

```markdown
## Profile Freshness Dashboard

### Needs Re-analysis (active subjects)
| Profile | Last Analyzed | Days Ago | Facts (analyzed → current) | Latest Fact | Reason |
|---------|--------------|----------|---------------------------|-------------|--------|
| john | 2026-03-15 | 13 | 8 → 15 | 2026-05-18 (1d) | Stale + new facts |

### Inactive Subjects (30–90d since latest fact)
| Profile | Last Analyzed | Latest Fact | Days Idle | Suggestion |
|---------|--------------|-------------|-----------|------------|
| bob | 2026-03-20 | 2026-04-10 | 39 | Review whether bob is still relevant before re-analyzing |

### Archive Candidates (>90d since latest fact)
| Profile | Last Analyzed | Latest Fact | Days Idle | Suggestion |
|---------|--------------|-------------|-----------|------------|
| dave | 2025-12-01 | 2025-11-15 | 186 | Subject inactive — consider archiving (future: nemawashi-prune) |

### Up to Date
| Profile | Last Analyzed | Latest Fact | Facts |
|---------|--------------|-------------|-------|
| carol | 2026-05-18 | 2026-05-19 (0d) | 12 |

Summary: 1 re-analyze · 1 review · 1 archive candidate · 1 up to date
```

Prompt **only for the Needs Re-analysis rows**:

> "Re-analyze the active-subject stale profiles? (e.g., 'yes' for all, 'john only', or 'no')"

For Inactive / Archive Candidate rows, surface them but **do not** auto-suggest re-analysis — the right next step is a human "is this person still relevant?" decision, not more compute.

### Step 3: Re-analyze (optional)

If the user opts in, dispatch one parallel subagent per selected profile. Use the following **uniform prompt template** — substitute `${name}` and `${today}` per row, and reuse the rest verbatim. The template exists because earlier ad-hoc dispatches produced wildly inconsistent return shapes (3-line vs. 30-line summaries) — pinning the format here makes the aggregated output usable.

```
Re-analyze the supernemawashi profile for "${name}".

Today: ${today}
Profile path: ~/.local/share/supernemawashi/profiles/${name}/

Invoke the `supernemawashi:nemawashi-analyze` skill on this profile end-to-end. The skill dispatches one `framework-analyzer` agent per framework definition in parallel, then synthesizes the slim `profile.md` (Core Pattern + Framework Summary) plus `contradictions.md`. Per-framework details and situation-indexed DO/DON'T rules land in `PROFILE_DIR/${name}/frameworks/<slug>.md`.

When done, return ONLY a one-line summary in this exact shape:

${name}: <core pattern in one sentence> | DO: <single top rule> | DON'T: <single top rule> | contradictions: <count or "none">

No framework details, no evidence quotes, no process narration. One line only.
```

`nemawashi-analyze` is local-file-only (no MCP calls), so parallelism is unconstrained — fan out across all selected profiles at once.

After all subagents return, summarize as a short table (one row per re-analyzed profile, columns matching the one-line shape above) and re-run `./check.sh` to confirm the updated freshness state.

## Edge Cases

- **No profiles exist**: Report and suggest `nemawashi-collect` or `nemawashi-discover`.
- **Script not found** (rare — only if the plugin install is partial): fall back to running the equivalent classification in the LLM, but warn the user that the source-of-truth helper is missing.
- **`activity_status == unknown`** (no facts at all): same row treatment as Inactive — surface for human review, do not auto-re-analyze.
- **Latest fact dated in the future** (clock skew, mistagged entry): `inactivity_days` will be negative. The script still classifies as Active. Surface the anomaly to the user; don't try to "fix" it.

## Key Principles

- **Script is canonical** — classification logic lives in `./check.sh`. This skill renders and orchestrates; it does not reclassify.
- **Two axes, not one** — analysis staleness and subject inactivity are independent signals with different remediations. A Dormant subject doesn't need re-analysis even if its analysis is old.
- **Parallel re-analysis** — when the user opts in, dispatch one agent per Needs Re-analysis row in parallel using the template above. Don't auto-batch Inactive or Dormant rows.
- **Uniform dispatch prompts** — never improvise per-row prompts when bulk re-analyzing; the template is the contract that keeps subagent reports aggregable.
