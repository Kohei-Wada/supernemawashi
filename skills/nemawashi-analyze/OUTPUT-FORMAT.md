# Output Format

The analyze flow produces three kinds of files per profile:

```
PROFILE_DIR/<name>/
  profile.md                  Slim index: Basic Info + Core Pattern + Framework Summary
  contradictions.md           Cross-framework inconsistencies
  frameworks/
    <slug>.md                 One per framework — classification + evidence + situation-indexed rules
```

## profile.md

The top-level profile is now a **slim index**. The per-framework details (classification rationale, evidence, situation-indexed rules) live in `frameworks/<slug>.md`. The profile keeps the parts a human writes manually (Basic Info, Communication Patterns, Active Channels, Work Patterns) plus the cross-framework synthesis.

```markdown
---
name: <Full Name>
role: <Role>
last_updated: YYYY-MM-DD
---

# <Full Name>

## Basic Info
[Preserved across analyses — manual content. Examples: organization, team, reporting line, time zone.]

## Communication Patterns
[Preserved across analyses — manual notes on language preferences, response cadence, channel norms.]

## Active Channels
[Preserved — Slack channels, email threads, repos where this person is active.]

## Work Patterns
[Preserved — meeting cadence, focus hours, escalation patterns.]

## Core Pattern
[1-3 sentence synthesis across all frameworks — the deepest insight about what drives this person. Regenerated on every analyze.]

## Framework Summary

| Framework | Classification | Confidence | Details |
|---|---|---|---|
| Defense Mechanisms | [classification text from frameworks/defense-mechanisms.md] | Confirmed | [frameworks/defense-mechanisms.md](frameworks/defense-mechanisms.md) |
| Conflict Mode (TKI) | ... | ... | [frameworks/thomas-kilmann-tki.md](frameworks/thomas-kilmann-tki.md) |
| Ego States (TA) | ... | ... | [frameworks/transactional-analysis-ta.md](frameworks/transactional-analysis-ta.md) |
| Core Motivators | ... | ... | [frameworks/core-motivators.md](frameworks/core-motivators.md) |
| Cognitive Biases | ... | ... | [frameworks/cognitive-biases.md](frameworks/cognitive-biases.md) |
| Attachment Style | ... | Hypothesis | [frameworks/attachment-style.md](frameworks/attachment-style.md) |

### Data Gaps
- [ ] [Missing dimension or situation]: [what to collect and how]

<!-- analyzed: YYYY-MM-DD, facts_count: N -->
```

**Important**: profile.md no longer carries the full Framework Classifications table with evidence summaries, nor the situation-indexed Communication Strategy block. Those move into the per-framework files. Consumers (`nemawashi-show`, `nemawashi-reply`) read the framework files directly when they need that detail.

## frameworks/&lt;slug&gt;.md

One per framework. The orchestrator dispatches one agent per framework definition under `skills/nemawashi-analyze/frameworks/`, and each agent writes its own output file under `PROFILE_DIR/<name>/frameworks/<slug>.md` with the matching `<slug>`.

```markdown
---
framework: <slug>
classification: <one-line classification text>
confidence: Confirmed | Hypothesis | Data Gap
last_updated: YYYY-MM-DD
---

# <Framework display name>

## Classification
[1-3 sentences expanding the one-line classification — what pattern, in what contexts, with what intensity.]

## Evidence
- [YYYY-MM-DD] [source] <fact citation> → <signal explanation> [signal: <tag>]
- ...

## Rules

### When Requesting
**DO:**
- [Action] — [reasoning] [signal: <tag>]

**DON'T:**
- [Action] — [reasoning] [signal: <tag>]

### During Conflict
**DO:** ...
**DON'T:** ...

### When Reporting
**DO:** ...
**DON'T:** ...

### Routine Collaboration
**DO:** ...
**DON'T:** ...
```

**Special cases**:

- **Data Gap classification** — omit the `## Rules` section entirely and replace with a `## Data Gap` section explaining what evidence would be needed.
- **Hypothesis confidence** — rules are included but each rule line is tagged `(hypothesis)`. The classification frontmatter still says `Hypothesis`.
- **No applicable rule for a situation** — write `- (no framework-specific rule for this situation)` under the relevant DO or DON'T heading rather than fabricating one.

**Multi-framework rules**: Some rules cite a primary + secondary framework (e.g. `[signal: info-withholding + TKI: competing]`). Place the rule under its **primary** framework's file. The secondary framework appears in the bracket annotation only — it does not duplicate the rule.

## contradictions.md

Cross-framework inconsistencies — verbal contradictions, say-do gaps, audience-dependent behavior, temporal reversals. The schema is unchanged from prior versions.

```markdown
---
person: [Full Name]
last_updated: [YYYY-MM-DD]
---

# Contradictions: [Full Name]

## Verbal Contradictions
- **[Short label]** — [Summary of the contradiction]
  - [YYYY-MM-DD] [source] [Statement A] (url)
  - [YYYY-MM-DD] [source] [Statement B] (url)
  - **Pattern implication:** [What this reveals about the person]

## Say-Do Gaps
- **[Short label]** — [Summary]
  - Said: [YYYY-MM-DD] [source] [What they said] (url)
  - Did: [YYYY-MM-DD] [source] [What they did] (url)
  - **Pattern implication:** [What this reveals]

## Audience-Dependent Behavior
- **[Short label]** — [Summary]
  - With [audience A]: [YYYY-MM-DD] [source] [Behavior] (url)
  - With [audience B]: [YYYY-MM-DD] [source] [Opposite behavior] (url)
  - **Pattern implication:** [What this reveals]

## Temporal Reversals
- **[Short label]** — [Summary]
  - Before: [YYYY-MM-DD] [source] [Original position] (url)
  - After: [YYYY-MM-DD] [source] [Reversed position] (url)
  - **Pattern implication:** [What this reveals]

<!-- analyzed: YYYY-MM-DD, facts_count: N -->
```

Omit any category section that has no entries. If no contradictions are found at all, write:

```markdown
---
person: [Full Name]
last_updated: [YYYY-MM-DD]
---

# Contradictions: [Full Name]

No contradictions detected with current data. Re-run after collecting more facts.

<!-- analyzed: YYYY-MM-DD, facts_count: N -->
```

## Atomic writes

All files (`profile.md`, `frameworks/<slug>.md`, `contradictions.md`) are written via temp file + `mv`. A crash during analysis leaves the prior version intact.
