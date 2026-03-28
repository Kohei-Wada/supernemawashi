# Profile Discovery Skill Design

## Context

Profile creation is entirely manual — the user must know who to track and explicitly run profile-collector. There's no mechanism to surface people who appear frequently in Slack channels or email threads but have no profile. This skill closes that gap by scanning communication sources and identifying untracked people.

Closes #5.

## Scope

- Create `skills/profile-discovery/SKILL.md`
- Update `skills/using-supernemawashi/SKILL.md` to include profile-discovery in the routing table
- Update `CLAUDE.md` skills table
- Update `README.md` skills table

## Skill Design

### Trigger Conditions

- User says "discover people", "who am I missing?", "find untracked people"
- User says "discover people in #channel-name" (scoped scan)
- After profile-batch completes (suggest discovery as a follow-up)

### Process (6 Steps)

#### Step 1: Determine Scope

- If user specified channel(s): use those
- If no specification: use Slack MCP to list channels the user is a member of, filter to active channels (had messages in the last 2 weeks)
- Set scan window: last 2 weeks (14 days)

#### Step 2: Scan Slack

For each target channel:
- Use Slack MCP `slack_read_channel` to read recent messages
- Extract unique user IDs/names from message authors
- Count messages per person per channel
- Use `slack_read_user_profile` for display names where needed

#### Step 3: Scan Gmail

- Use Gmail MCP `gmail_search_messages` to find recent threads (last 2 weeks)
- Extract sender/recipient email addresses and names
- Count threads per person
- Match Gmail contacts to Slack users by name/email where possible (deduplicate)

#### Step 4: Cross-Reference

- Read existing profile directories from `PROFILE_DIR/`
- Match discovered people against existing profiles by name (case-insensitive, partial match)
- Exclude the user themselves
- Exclude bots and automated accounts (Slackbot, app integrations, etc.)
- Flag people who have a profile but haven't been seen recently (optional insight)

#### Step 5: Rank & Present

Present untracked people in a table sorted by total interaction count (Slack messages + Gmail threads), grouped by frequency tier:

```
## Untracked People (N found)

### High Frequency (10+ interactions)
| # | Name | Slack msgs | Gmail threads | Top channels |
|---|------|-----------|---------------|-------------|
| 1 | john | 23 | 2 | #engineering, #support |
...

### Medium Frequency (3-9 interactions)
| # | Name | Slack msgs | Gmail threads | Top channels |
...

### Low Frequency (1-2 interactions)
(listed but not recommended for profiling)
```

After the table, prompt the user to select who to profile:
> "Select people to profile (e.g., '1, 2, 3' or 'all high')"

#### Step 6: Collect

For each selected person, invoke `profile-collector` sequentially. Report progress after each collection completes.

### Edge Cases

- **No untracked people found**: Report that all frequent contacts have profiles. Suggest expanding the scan window or checking different channels.
- **Too many results**: If more than 30 untracked people, show only High and Medium frequency. Mention the Low frequency count without listing individuals.
- **Slack-only or Gmail-only**: If one MCP source is unavailable, proceed with the other and note the limitation.
- **Name matching ambiguity**: When matching discovered names against existing profiles, use fuzzy matching (e.g., "John" matches a profile directory named "john"). If uncertain, list the person and note "may already be tracked as [existing profile name]".

### Key Principles

- **Discovery, not surveillance** — The purpose is finding people the user interacts with but forgot to track. Not monitoring people they don't interact with.
- **User selects** — Never auto-collect without user confirmation.
- **Deduplicate across sources** — Same person appearing in Slack and Gmail should be one row, not two.
- **Respect scan limits** — 2-week window keeps MCP call volume reasonable. User can request a wider window explicitly.

## Integration

### using-supernemawashi

Add profile-discovery to the skill routing:
- "discover people", "who am I missing?", "find untracked" → profile-discovery

### Related Skills

- `profile-collector` — downstream; discovery feeds people into collection
- `profile-batch` (#3) — could integrate discovery as an optional first step in the future
