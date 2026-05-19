---
name: nemawashi-discover
description: Use when user wants to find people they interact with but haven't profiled yet - scans available MCP sources (Slack, Gmail, Calendar, GitHub, and any other discoverable sources via the adapter pattern) for untracked contacts
---

# Profile Discovery

Scan communication sources to identify people the user frequently interacts with but hasn't created profiles for yet.

## When to Use

- User says "discover people", "who am I missing?", "find untracked people"
- User says "discover people in #channel-name" (scoped scan)

## Process

### Step 1: Determine Scope

- If the user specified channel(s): use those as the Slack scope.
- If no specification: use the per-adapter defaults defined in each adapter's Discovery Recipe.
- Set scan window: **last 2 weeks** (14 days from today) unless the user requests a wider window.

### Step 2: Scan All Sources (Adapter-Driven)

Read all `*.md` files in `../nemawashi-collect/adapters/` (relative to this skill). For each adapter:

1. Check the adapter's **MCP Tools Required** section against the tools available in this session.
2. If a `## Discovery Recipe` section exists AND all required tools are present, run the recipe with the scan window from Step 1.
3. If required tools are missing, skip the adapter and note the gap in the final report.
4. If the adapter has no Discovery Recipe, skip it (the source has no person-discovery shape).

Each adapter returns a list of person records keyed by the identifier types it knows about (handle / email / display_name / github_login / ...).

After running every known adapter, scan for additional MCP servers that look discovery-relevant but are not covered. Same best-effort fallback as nemawashi-collect — note any source you use this way so a dedicated adapter file can be added later.

### Step 3: Cross-Reference

1. Read existing profile directories from `PROFILE_DIR/`.
2. Match discovered people against existing profiles by name (case-insensitive, allow partial match — e.g., "John" matches directory "john") or by email/handle.
3. Remove matches from the untracked list.
4. Exclude the user themselves.
5. **Deduplicate across sources**: same person appearing in multiple adapters (e.g., Slack handle + Gmail address that resolve to the same human) collapses to one row. Match by name first, then email/handle when name is ambiguous.
6. If a match is uncertain, keep the person in the list with a note: "may already be tracked as [existing profile name]".

### Step 4: Rank & Present

Present untracked people in a table sorted by total interaction count (sum across all sources), grouped by frequency:

```markdown
## Untracked People (N found)

### High Frequency (10+ interactions)
| # | Name        | Sources                           | Top context        |
|---|-------------|-----------------------------------|--------------------|
| 1 | alice       | slack: 23, gmail: 2               | #engineering       |
| 2 | bob         | slack: 18, calendar: 4, github: 1 | weekly 1:1         |

### Medium Frequency (3-9 interactions)
| # | Name        | Sources                           | Top context        |
|---|-------------|-----------------------------------|--------------------|
| 3 | carol       | gmail: 7                          | proposal threads   |

### Low Frequency (1-2 interactions)
(N people — not listed individually, unlikely to need profiles)
```

After the table, prompt:
> "Select people to profile (e.g., '1, 2, 3' or 'all high')"

**If more than 30 untracked people:** show only High and Medium frequency; mention the Low frequency count without listing individuals.

**If no untracked people found:** report that all frequent contacts have profiles. Suggest expanding the scan window or checking different channels.

### Step 5: Hand off to nemawashi-collect

`nemawashi-discover` stops at "found unprofiled people, user picked some". Actually producing the profiles is `nemawashi-collect`'s job — and `nemawashi-collect` already owns the batch / parallel dispatch protocol (see its `## Parallel Dispatch` section). Keep the responsibilities separated.

After the user has selected names:

1. **Confirm** the handoff with the user: "Collect profiles for: alice, bob, carol — run `nemawashi-collect` now?" Treat selection alone as intent to proceed, but show the list so the user can adjust.
2. **Invoke `nemawashi-collect`** with the selected names. The collect skill handles MCP-tool filtering and parallel `profile-collector` agent dispatch for the batch.
3. **Summarize** whatever `nemawashi-collect` reports back; don't re-format or re-aggregate — that summary is already the collect skill's deliverable.
4. **Suggest** `nemawashi-analyze` for the freshly collected profiles.

Discover never dispatches `profile-collector` directly and never touches `PROFILE_DIR/<name>/`. Its writes are zero. Its job is finished once the list crosses the boundary into collect.

## Key Principles

- **Discovery, not surveillance** — Find people the user interacts with but forgot to track. Not monitoring people they don't interact with.
- **User selects** — Never auto-collect without explicit user confirmation.
- **Deduplicate across sources** — Same person across N adapters = one row, not N.
- **Respect scan limits** — 2-week default window keeps MCP call volume reasonable.
- **Graceful degradation** — Adapters whose MCP tools are absent are skipped silently; the user is told what was scanned in the final report.
