---
name: nemawashi-check
description: Use when user wants to check which profiles need re-analysis - scans all profiles for staleness and new unanalyzed data
---

# Profile Freshness

Check analysis staleness across all profiles and triage which ones need re-analysis.

## When to Use

- User says "check profiles", "which profiles are stale?", "who needs re-analysis?"
- User says "profile status" or "freshness check"

## Process

### Step 1: Scan Profiles

1. List all directories in `PROFILE_DIR/`
2. For each profile directory, read `profile.md` and extract the `<!-- analyzed: YYYY-MM-DD, facts_count: N -->` HTML comment.
3. Count current fact entries across **both** files (newer profiles only have the jsonl, legacy profiles only have the md, profiles mid-migration have both):
   - `facts.jsonl`: count non-empty lines (each line is one record).
   - `facts.md`: count lines matching `^- \[[0-9]{4}-[0-9]{2}(-[0-9]{2})?\] \[` (both `[YYYY-MM-DD]` and `[YYYY-MM]` prefixes are valid).
   - The sum is `current facts count`.
4. Determine the **latest fact date** — the maximum date across:
   - `facts.jsonl`: the `date` field of each record.
   - `facts.md`: the leading `[YYYY-MM-DD]` or `[YYYY-MM]` prefix of each entry.
   For month-precision dates, treat the date as the first day of that month for arithmetic.
5. Record per profile: name, last analyzed date, analyzed facts count, current facts count, latest fact date, days since latest fact (= **inactivity days**).

If a profile has no `<!-- analyzed: -->` comment, the analysis status is "Never Analyzed". If a profile has no fact data at all, the activity status is "Unknown".

`scripts/nemawashi-check.sh` produces all of the above as a TSV — invoking it is the fastest way to gather Step 1 data deterministically.

### Step 2: Classify

Each profile gets **two independent classifications** — one for analysis freshness, one for subject activity. Different combinations imply different actions.

**Analysis status:**

| Status | Criteria |
|--------|----------|
| Never Analyzed | No `<!-- analyzed: -->` comment in profile.md |
| Stale | Last analyzed > 7 days ago OR current facts count > analyzed facts count |
| Fresh | Last analyzed within 7 days AND no new facts |
| No Data | profile.md exists but neither facts.jsonl nor facts.md is present |

**Subject activity** (based on inactivity days — how long since the most recent fact):

| Status | Criteria |
|--------|----------|
| Active | Latest fact within 30 days |
| Inactive | Latest fact 30–90 days old |
| Dormant | Latest fact older than 90 days |
| Unknown | No fact data at all |

**Action matrix** — combine the two axes:

| Analysis ↓ \ Activity → | Active | Inactive | Dormant |
|---|---|---|---|
| Fresh | (skip) | (skip) | Archive Candidate |
| Stale | **Re-analyze** | Review | Archive Candidate |
| Never Analyzed | **Analyze** | Review | Archive Candidate |
| No Data | run nemawashi-collect first | — | — |

The thresholds (7 / 30 / 90 days) match the bash helper's defaults; tune them in `scripts/nemawashi-check.sh` if the workflow needs different cadences.

### Step 3: Present Dashboard

Group profiles by the action implied by the matrix above. Suppress empty sections.

```markdown
## Profile Freshness Dashboard

### Needs Re-analysis (active subjects)
| Profile | Last Analyzed | Days Ago | Facts (analyzed → current) | Latest Fact | Reason |
|---------|--------------|----------|---------------------------|-------------|--------|
| john | 2026-03-15 | 13 | 8 → 15 | 2026-05-18 (1d) | Stale + new facts |
| alice | never | — | 0 → 6 | 2026-05-12 (7d) | Never analyzed |

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

Summary: 2 re-analyze · 1 review · 1 archive candidate · 1 up to date
```

After the dashboard, prompt only for action on the **Needs Re-analysis** rows:

> "Re-analyze the active-subject stale profiles? (e.g., 'yes' for all, 'john only', or 'no')"

For Inactive / Archive Candidate rows, do **not** suggest re-analysis by default — the right next step is usually a human "is this person still relevant?" decision, not more compute. Surface the rows; let the user act.

### Step 4: Re-analyze (Optional)

If the user selects profiles from the Needs Re-analysis section, dispatch parallel agents — one per profile — each invoking `nemawashi-analyze`. nemawashi-analyze is local-file-only (no MCP calls), so parallelism is unconstrained.

After all agents return, show an updated dashboard summary.

## Edge Cases

- **No profiles exist**: Report that no profiles were found. Suggest running nemawashi-collect or nemawashi-discover first.
- **All profiles fresh AND active**: Report that everything is up to date. No action needed.
- **Profile has profile.md but neither facts.jsonl nor facts.md**: Mark as "No data collected — run nemawashi-collect first." Do not suggest re-analysis.
- **Analyzed comment exists but is malformed**: Treat as "Never Analyzed" and note the parsing issue.
- **Latest fact in the future** (clock skew, mislabeled entry): inactivity days will be negative. Treat as Active and surface the anomaly to the user — don't try to "fix" the data.

## Key Principles

- **Read-only by default** — This skill only reads and reports. Re-analysis happens only when the user explicitly requests it.
- **Actionable output** — The dashboard should make it immediately clear what needs attention and why.
- **Two axes, not one** — Analysis staleness and subject inactivity are independent signals with different remediations. Don't conflate them; a Dormant subject doesn't need re-analysis even if their analysis is old.
- **Parallel re-analysis** — When the user opts in, dispatch one agent per stale **and active** profile in parallel. Don't auto-batch Inactive or Dormant rows.
