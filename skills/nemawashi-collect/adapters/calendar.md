---
adapter: calendar
output_tag: calendar
identifiers: [email, display_name]
---

# Adapter: Calendar

## Purpose
Captures meeting cadence and structural relationships: who the target meets with regularly, what kinds of meetings they own vs. attend, recurring patterns.

## MCP Tools Required
- `mcp__claude_ai_Google_Calendar__list_events` — list events involving the target

If unavailable, skip this adapter.

## Collection Recipe
1. List events in a recent window (default 30 days) where the target is the organizer or an attendee (`list_events` with the target's email).
2. Group by recurrence: standing 1:1s, recurring team meetings, one-off invitations.
3. Note meeting types (1:1 vs. group), durations, and whether the target organizes or attends.

## Fact Extraction
Signals worth capturing:
- Recurring 1:1 partners (close working relationships)
- Meeting types the target owns (operational reviews, 1:1s, planning) vs. attends only
- Cadence (daily standups, weekly syncs, monthly reviews)
- Cancellation / decline patterns if visible

Append one JSONL record per signal to `<profile-dir>/facts.jsonl` following the canonical schema in `../FACTS-SCHEMA.md`. Use `source: "calendar"`. Calendar-specific optional field: `meeting_title` (the event title — omit when it contains confidential project names).

Example:

```jsonl
{"date":"2026-03-28","source":"calendar","content":"<observable pattern>","meeting_title":"<event title if non-sensitive>"}
```

Never modify a pre-existing `facts.md` — new entries always go to `facts.jsonl`.

## Discovery Recipe
Used by nemawashi-discover to find unprofiled people the user interacts with.

1. List events in the scan window (default 14 days) — `list_events` for the user's calendar.
2. Extract attendees (excluding the user themselves and resources like meeting rooms).
3. Count meeting participation per attendee.
4. Return a list of `{email, display_name, meeting_count, top_meeting_titles}` records.

## Identity Resolution
Used by the identity cache (`.identity.md`) to record the user's own Calendar identifiers once per refresh cycle.

1. Call `list_calendars` and pick the calendar marked as `primary` (or the first writable owned calendar if no explicit primary flag exists).
2. Record `id` (= `primary_calendar_id`) and `timeZone`.

Output (written to the `## calendar` section of `.identity.md`):

```
- primary_calendar_id: <id>
- timezone: <tz>
```

## Pitfalls
- **Calendar is structural, not behavioral**: it tells you who meets whom, not what they said. Pair with Slack/Gmail for substance.
- **Free/busy noise**: declined or tentative invitations may not reflect real engagement.
- **Privacy**: meeting titles can be sensitive. Record patterns, not raw titles, when the title contains confidential project names.
