---
name: using-supernemawashi
description: Use when starting any conversation - establishes how to find and use interpersonal communication skills
---

# Using supernemawashi

You have access to interpersonal communication skills. These help you navigate workplace dynamics, craft strategic replies, and prepare for meetings.

## Available Skills

| Skill | Use When |
|-------|----------|
| `supernemawashi:profile-collector` | User wants to create or update someone's profile |
| `supernemawashi:profile-analyzer` | User wants to analyze someone's behavioral patterns |
| `supernemawashi:profile-viewer` | User wants to view, list, or display existing profiles (read-only) |
| `supernemawashi:profile-discovery` | User wants to find people they interact with but haven't profiled yet |
| `supernemawashi:profile-freshness` | User wants to check which profiles are stale or need re-analysis |
| `supernemawashi:reply-strategist` | User needs help replying to someone or deciding what to say |

## Skill Routing

When the request is ambiguous, use this decision tree:

```
"update/collect profile for X" (specific person)
  → profile-collector

"analyze X" / "what kind of person is X?"
  → profile-analyzer

"show X" / "view X's profile" / "X見せて" / "Xのprofile" / "list profiles" / "誰がいる?"
  → profile-viewer

"update all profiles" / "batch update" / "re-analyze everyone"
  → dispatch parallel agents (see Bulk Operations below)

"check profiles" / "which are stale?" / "who needs re-analysis?"
  → profile-freshness (can launch parallel agents to re-analyze)

"discover people" / "who am I missing?"
  → profile-discovery

"how should I reply to X?" / "what should I say?"
  → reply-strategist
```

**Key disambiguations:**
- Specific person → `profile-collector` or `profile-analyzer`. Multiple/all people → dispatch parallel agents (see Bulk Operations).
- "Check" or "status" → `profile-freshness` (read-only by default; can dispatch agents to re-analyze if the user opts in).
- "Show" / "view" / "見せて" / "見たい" → `profile-viewer` (read-only display, no analysis or modification).

## Bulk Operations

For multi-person operations ("update all profiles", "batch update", "re-analyze everyone"), dispatch parallel agents — one per person — each invoking the appropriate skill. Aggregate results in the main session.

- `profile-analyzer` is local-file-only, so parallelism is unconstrained.
- `profile-collector` hits MCP sources (Slack/Gmail/Calendar/GitHub); for 5+ profiles, stagger dispatch in batches of 5 to avoid rate limits.

To triage first (find stale profiles, then re-analyze only those), use `profile-freshness`.

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

Always check if a profile exists before advising on communication with someone. If no profile exists, suggest running profile-collector first.

## Situation Categories

DO/DON'T rules in `profile.md` (under the "Communication Strategy" section) are organized by these 4 situation categories. profile-analyzer generates them; reply-strategist consumes them. Do not redefine in individual skills.

1. **When Requesting** — you need something from them
2. **During Conflict** — disagreement or tension
3. **When Reporting** — delivering news (good or bad)
4. **Routine Collaboration** — day-to-day interaction

## Coexistence with superpowers

supernemawashi handles interpersonal communication. superpowers handles software engineering workflows. They do not overlap.
