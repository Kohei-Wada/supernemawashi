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
1. Resolve the target's Slack user ID (search by display name or email).
2. Fetch their profile (`slack_read_user_profile`) for title, status, team.
3. Search messages authored by or mentioning the target (`slack_search_public_and_private`). Default window: last 30-90 days.
4. For high-signal hits, read the surrounding thread (`slack_read_thread`) to capture context.
5. Identify the top 3-5 channels they are active in; sample recent activity (`slack_read_channel`).

## Fact Extraction
Record observable behaviors only — what they said, how they replied, who they tagged. Do not infer psychology (that is profile-analyzer's job).

Signals worth capturing:
- Response latency on contentious vs. routine topics
- Tone shifts when addressing superiors vs. peers vs. reports
- Recurring topics, projects, stated opinions
- Reaction patterns (which emojis, to whom)

`facts.md` line format:

```
- [YYYY-MM-DD] [slack] <observable behavior> (https://<workspace>.slack.com/archives/<channel>/p<timestamp>)
```

Permalinks come from the message metadata. Omit the URL only if it cannot be constructed.

## Pitfalls
- **Bot accounts**: filter out app integrations and bot users (check message subtype / bot flags).
- **Thread bias**: long threads over-represent vocal participants. Weight a single thread as one data point, not N.
- **Privacy boundaries**: only collect from channels the user is a member of. Do not try to read DMs the target has with third parties.
- **Rate limits**: search API is rate-limited. Batch queries; stop after the first 50-100 hits unless the user asks for a deeper scan.
