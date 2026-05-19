---
adapter: slack
output_tag: slack
identifiers: [handle, display_name, email]
---

# Adapter: Slack

## Purpose
Captures real-time communication style: response patterns, tone shifts by audience, topic engagement, and reaction behavior from the user's Slack workspace.

## MCP Tools Required
- `mcp__claude_ai_Slack__slack_search_public_and_private` — search messages by the target's name, handle, or email
- `mcp__claude_ai_Slack__slack_read_user_profile` — fetch the target's bio, title, status
- `mcp__claude_ai_Slack__slack_read_thread` — read thread context around hits
- `mcp__claude_ai_Slack__slack_read_channel` — sample channels the target is active in

If any of the above is unavailable, skip this adapter.

## Collection Recipe

**Shape: author-search.** The target is known by name, so query directly for their messages instead of walking channels. Author-search returns permalinks with channel and timestamp metadata already attached, so a separate channel-sampling pass is unnecessary in the common case. (For the inverse case — target unknown — see the Discovery Recipe below, which is built around channel-walking.)

1. Resolve the target's Slack handle (search by display name or email if not already known).
2. Fetch their profile (`slack_read_user_profile`) for title, status, team.
3. **Author-search for messages they wrote.** Call `slack_search_public_and_private` with the query `from:<handle>` over the default window (last 30-90 days). Each hit includes the permalink, channel, and timestamp — no separate channel-walk is needed to attribute the message.
4. **Optional: search for messages mentioning them.** Query `to:<handle>` for direct mentions, or `<handle>` (no modifier) for any reference. Use sparingly — both can return high volume on common handles, and the value tapers off quickly after the top hits.
5. For high-signal hits from step 3 or 4, read the surrounding thread (`slack_read_thread`) to capture context.
6. **Fallback (rare):** if author-search returns fewer than ~5 hits across the window, the target may be active in private channels not indexed by search, or the handle may be misresolved. In that case, sample the top 3-5 channels the target is known to participate in (`slack_read_channel`). Skip this step when author-search already yielded sufficient signal.

## Fact Extraction
Record observable behaviors only — what they said, how they replied, who they tagged. Do not infer psychology (that is nemawashi-analyze's job).

Signals worth capturing:
- Response latency on contentious vs. routine topics
- Tone shifts when addressing superiors vs. peers vs. reports
- Recurring topics, projects, stated opinions
- Reaction patterns (which emojis, to whom)

Append one JSONL record per signal to `<profile-dir>/facts.jsonl` following the canonical schema in `../FACTS-SCHEMA.md`. Use `source: "slack"`. Slack-specific optional field: `channel` (channel name with leading `#`).

Example:

```jsonl
{"date":"2026-03-28","source":"slack","content":"<observable behavior>","url":"https://<workspace>.slack.com/archives/<channel-id>/p<timestamp>","channel":"#<channel-name>"}
```

Permalinks come from the message metadata. Omit `url` only if it cannot be constructed. Never modify a pre-existing `facts.md` — new entries always go to `facts.jsonl`.

## Discovery Recipe
Used by nemawashi-discover to find unprofiled people the user interacts with.

**Shape: channel-walking.** The target set is unknown, so we have to sample the user's surface area (their channels) and extract who appears in it. This is the inverse of the Collection Recipe — use channel-walking when the target is unknown, author-search when it is known.

1. List the channels the user is a member of, filtered to those with activity in the scan window (default 14 days).
2. For each channel, read recent messages (`slack_read_channel`).
3. Extract unique authors; resolve display names via `slack_read_user_profile` if needed.
4. Count messages per person per channel; track which channels each person appears in.
5. Return a list of `{handle, display_name, channels, msg_count}` records.

## Identity Resolution
Used by the identity cache (`.identity.md`) to record the user's own Slack identifiers once per refresh cycle.

1. Determine the user's display name from the session context (e.g. CLI user, git config, or an explicit hint).
2. Call `slack_search_users` (or equivalent user-lookup tool) with the display name to resolve the user's Slack `handle`, `user_id`, and `email`.
3. Optionally call `slack_read_user_profile` against the resolved `user_id` to enrich with `display_name` and team.

Output (written to the `## slack` section of `.identity.md`):

```
- handle: <handle>
- user_id: <U…>
- display_name: <name>
- email: <email>
```

## Pitfalls
- **Bot accounts**: filter out app integrations and bot users (check message subtype / bot flags).
- **Thread bias**: long threads over-represent vocal participants. Weight a single thread as one data point, not N.
- **Privacy boundaries**: only collect from channels the user is a member of. Do not try to read DMs the target has with third parties.
- **Rate limits**: search API is rate-limited. Batch queries; stop after the first 50-100 hits unless the user asks for a deeper scan.
