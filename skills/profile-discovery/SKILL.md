---
name: profile-discovery
description: Use when user wants to find people they interact with but haven't profiled yet - scans Slack channels and Gmail for untracked contacts
---

# Profile Discovery

Scan communication sources to identify people the user frequently interacts with but hasn't created profiles for yet.

## When to Use

- User says "discover people", "who am I missing?", "find untracked people"
- User says "discover people in #channel-name" (scoped scan)

## Process

### Step 1: Determine Scope

- If the user specified channel(s): use those channels only
- If no specification: use Slack MCP tools to find channels the user is a member of. Filter to channels that have had activity in the last 2 weeks.
- Set scan window: **last 2 weeks** (14 days from today). The user can request a wider window explicitly.

### Step 2: Scan Slack

For each target channel:
1. Use Slack MCP to read recent messages in the channel (within scan window)
2. Extract unique user IDs/names from message authors
3. Count messages per person per channel
4. Track which channels each person appears in
5. Use Slack MCP to resolve display names for unknown user IDs

Skip bot users and app integrations (identifiable by bot flags or app-generated message subtypes).

### Step 3: Scan Gmail

1. Use Gmail MCP to search for threads from the last 2 weeks
2. Read a sample of recent threads to extract sender/recipient names and email addresses
3. Count threads per person
4. Match Gmail contacts to Slack users by name or email where possible to deduplicate

If Gmail MCP is unavailable, skip this step and note the limitation to the user.

### Step 4: Cross-Reference

1. Read existing profile directories from `PROFILE_DIR/`
2. Match discovered people against existing profiles by name (case-insensitive, allow partial match — e.g., "John" matches directory "john")
3. Remove matches from the untracked list
4. Exclude the user themselves
5. If a match is uncertain, keep the person in the list with a note: "may already be tracked as [existing profile name]"

### Step 5: Rank & Present

Present untracked people in a table sorted by total interaction count (Slack messages + Gmail threads), grouped by frequency:

```markdown
## Untracked People (N found)

### High Frequency (10+ interactions)
| # | Name | Slack msgs | Gmail threads | Top channels |
|---|------|-----------|---------------|-------------|
| 1 | john | 23 | 2 | #engineering, #support |
| 2 | alice | 18 | 5 | #engineering, #ops |

### Medium Frequency (3-9 interactions)
| # | Name | Slack msgs | Gmail threads | Top channels |
|---|------|-----------|---------------|-------------|
| 3 | bob | 7 | 0 | #design |

### Low Frequency (1-2 interactions)
(N people — not listed individually, unlikely to need profiles)
```

After the table, prompt:
> "Select people to profile (e.g., '1, 2, 3' or 'all high')"

**If more than 30 untracked people:** Show only High and Medium frequency. Mention the Low frequency count without listing individuals.

**If no untracked people found:** Report that all frequent contacts have profiles. Suggest expanding the scan window or checking different channels.

### Step 6: Collect

For each person the user selected:
1. Invoke `profile-collector` for that person
2. Report completion before moving to the next person
3. After all collections complete, summarize what was created

## Key Principles

- **Discovery, not surveillance** — Find people the user interacts with but forgot to track. Not monitoring people they don't interact with.
- **User selects** — Never auto-collect without explicit user confirmation.
- **Deduplicate across sources** — Same person in Slack and Gmail = one row, not two.
- **Respect scan limits** — 2-week default window keeps MCP call volume reasonable.
- **Graceful degradation** — If one MCP source is unavailable, proceed with the other.
