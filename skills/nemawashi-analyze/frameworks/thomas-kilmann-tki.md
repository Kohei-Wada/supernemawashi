---
framework: Conflict Mode (TKI)
tier: 1
output_label: Conflict Mode (TKI)
---

# Thomas-Kilmann Conflict Modes

## Purpose

Classifies a person's conflict style along two dimensions: assertiveness and cooperativeness. Understanding their mode helps you choose the right negotiation approach and avoid triggering unproductive patterns. Track whether the mode shifts by audience (subordinates vs. superiors).

## Classification Guidance

Scan facts.md entries for conflict-related behaviors. Map each to the 2D space (assertiveness × cooperativeness). The dominant mode is the most frequent one. If the person uses different modes with different audiences (e.g., competing with subordinates, accommodating with superiors), classify per-audience rather than a single mode.

## Reference Table

| Mode | Assertiveness | Cooperativeness | Observable Signals | DO | DON'T |
|---|---|---|---|---|---|
| Competing | High | Low | Strong declaratives, overriding suggestions, "I decided" | Present with data; frame as serving their goals; be direct | Match force with force; use tentative language |
| Collaborating | High | High | Asks questions, builds on ideas, "what if we" | Engage fully; bring options; co-create | Rush to a quick answer; dismiss their input |
| Compromising | Mid | Mid | "Fair enough", offers trades, splits difference | Propose fair trades; be transparent about priorities | Hold out for everything; appear inflexible |
| Avoiding | Low | Low | Non-response, "let's table this", delayed replies | Break into small low-threat asks; reduce perceived risk | CC others to force engagement; send long confrontational messages |
| Accommodating | Low | High | Quick agreement, "sounds good", rarely pushes back | Explicitly ask for concerns; check genuine buy-in | Mistake agreement for buy-in; pile on requests |

## Rule Generation

**TKI conflict mode → Match negotiation style.** Don't use tentative language with a competing type. Don't force engagement with an avoiding type. For each classified mode, generate DO rules that align with their conflict style and DON'T rules that clash with it.

## Signal Tags

Format: `[TKI: <mode>]`

Valid tags: `TKI:competing`, `TKI:collaborating`, `TKI:compromising`, `TKI:avoiding`, `TKI:accommodating`
