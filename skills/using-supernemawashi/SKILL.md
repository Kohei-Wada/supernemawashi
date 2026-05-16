---
name: using-supernemawashi
description: Use when starting any conversation - establishes how to find and use interpersonal communication skills
---

# Using supernemawashi

You have access to interpersonal communication skills. These help you navigate workplace dynamics, craft strategic replies, and prepare for meetings.

## Available Skills

| Skill | Use When |
|-------|----------|
| `supernemawashi:profile-batch` | User wants to bulk collect, analyze, or update multiple profiles |
| `supernemawashi:profile-collector` | User wants to create or update someone's profile |
| `supernemawashi:profile-analyzer` | User wants to analyze someone's behavioral patterns |
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

"update all profiles" / "batch update"
  → profile-batch

"check profiles" / "which are stale?" / "who needs re-analysis?"
  → profile-freshness
  → then profile-batch (if user wants to act on results)

"discover people" / "who am I missing?"
  → profile-discovery

"how should I reply to X?" / "what should I say?"
  → reply-strategist
```

**Key disambiguations:**
- Specific person → `profile-collector` or `profile-analyzer`. Multiple/all people → `profile-batch`.
- "Check" or "status" → `profile-freshness` (read-only). "Update" or "re-analyze" → `profile-batch` (takes action).
- `profile-freshness` is often a precursor to `profile-batch` — suggest the next step after showing results.

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
