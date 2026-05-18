---
name: using-supernemawashi
description: Use when starting any conversation - establishes how to find and use interpersonal communication skills
---

# Using supernemawashi

You have access to interpersonal communication skills. These help you navigate workplace dynamics, craft strategic replies, and prepare for meetings.

## Available Skills

All skills are verb-first under the `nemawashi-` prefix.

| Skill | Use When |
|-------|----------|
| `supernemawashi:nemawashi-collect` | User wants to create or update someone's profile |
| `supernemawashi:nemawashi-analyze` | User wants to analyze someone's behavioral patterns |
| `supernemawashi:nemawashi-show` | User wants to view, list, or display existing profiles (read-only) |
| `supernemawashi:nemawashi-discover` | User wants to find people they interact with but haven't profiled yet |
| `supernemawashi:nemawashi-check` | User wants to check which profiles are stale or need re-analysis |
| `supernemawashi:nemawashi-reply` | User needs help replying to someone or deciding what to say |

Updating a profile is normally a 2-step pipeline: **nemawashi-collect** (pull from MCP sources — slow, rate-limited) → **nemawashi-analyze** (local-only — fast). They are kept as separate skills so re-analysis without re-collection is cheap.

## Skill Routing

When the request is ambiguous, use this decision tree:

```
"update/collect profile for X" (specific person)
  → nemawashi-collect (then suggest nemawashi-analyze)

"analyze X" / "what kind of person is X?"
  → nemawashi-analyze

"show X" / "view X's profile" / "X見せて" / "Xのprofile" / "list profiles" / "誰がいる?"
  → nemawashi-show

"update all profiles" / "batch update" / "re-analyze everyone"
  → dispatch parallel agents (see Bulk Operations below)

"check profiles" / "which are stale?" / "who needs re-analysis?"
  → nemawashi-check (can launch parallel agents to re-analyze)

"discover people" / "who am I missing?"
  → nemawashi-discover

"how should I reply to X?" / "what should I say?"
  → nemawashi-reply
```

**Key disambiguations:**
- Specific person → `nemawashi-collect` or `nemawashi-analyze`. Multiple/all people → dispatch parallel agents (see Bulk Operations).
- "Check" or "status" → `nemawashi-check` (read-only by default; can dispatch agents to re-analyze if the user opts in).
- "Show" / "view" / "見せて" / "見たい" → `nemawashi-show` (read-only display, no analysis or modification).

## Bulk Operations

For multi-person operations ("update all profiles", "batch update", "re-analyze everyone"), dispatch parallel agents — one per person — each invoking the appropriate skill. Aggregate results in the main session.

- `nemawashi-analyze` is local-file-only, so parallelism is unconstrained.
- `nemawashi-collect` hits MCP sources (Slack/Gmail/Calendar/GitHub); for 5+ profiles, stagger dispatch in batches of 5 to avoid rate limits.

To triage first (find stale profiles, then re-analyze only those), use `nemawashi-check`.

## The Rule

**Invoke relevant skills BEFORE any response or action.** If a user mentions replying to someone, preparing for a meeting, or dealing with a person — check for applicable skills.

## Variables

These variables are referenced by all supernemawashi skills. Do not redefine in individual skills.

- `PROFILE_DIR` = `~/.local/share/supernemawashi/profiles`

## Profile Data

Profiles are stored in `PROFILE_DIR/<person-name>/`:
- `profile.md` — Objective data and behavioral analysis
- `relationship.md` — Your relationship and approach strategies
- `facts.md` — Chronological record of statements and actions
- `contradictions.md` — Detected contradictions

Always check if a profile exists before advising on communication with someone. If no profile exists, suggest running nemawashi-collect first.

## Situation Categories

DO/DON'T rules in `profile.md` (under the "Communication Strategy" section) are organized by these 4 situation categories. nemawashi-analyze generates them; nemawashi-reply consumes them. Do not redefine in individual skills.

1. **When Requesting** — you need something from them
2. **During Conflict** — disagreement or tension
3. **When Reporting** — delivering news (good or bad)
4. **Routine Collaboration** — day-to-day interaction

## Coexistence with superpowers

supernemawashi handles interpersonal communication. superpowers handles software engineering workflows. They do not overlap.
