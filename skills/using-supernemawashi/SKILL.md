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
| `supernemawashi:reply-strategist` | User needs help replying to someone or deciding what to say |

## The Rule

**Invoke relevant skills BEFORE any response or action.** If a user mentions replying to someone, preparing for a meeting, or dealing with a person — check for applicable skills.

## Profile Data

Profiles are stored in `~/.local/share/supernemawashi/profiles/<person-name>/`:
- `profile.md` — Objective data and behavioral analysis
- `relationship.md` — Your relationship and approach strategies
- `facts.md` — Chronological record of statements and actions
- `contradictions.md` — Detected contradictions

Always check if a profile exists before advising on communication with someone. If no profile exists, suggest running profile-collector first.

## Coexistence with superpowers

supernemawashi handles interpersonal communication. superpowers handles software engineering workflows. They do not overlap.
