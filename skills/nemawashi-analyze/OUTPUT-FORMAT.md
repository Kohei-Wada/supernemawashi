# Output Format

## profile.md

Write/update the following sections in profile.md. Preserve all existing sections (Basic Info, Communication Patterns, Active Channels, etc.) — only add/replace the sections below.

```markdown
## Behavioral Patterns

### Core Pattern
[1-3 sentence synthesis across all frameworks]

### Framework Classifications

| Framework | Classification | Confidence | Evidence |
|---|---|---|---|
| Defense Mechanisms | [dominant mechanisms] | Confirmed/Hypothesis | [brief evidence summary] |
| Conflict Mode (TKI) | [mode(s), context if varies] | ... | ... |
| Ego States (TA) | [states per relationship] | ... | ... |
| Core Motivators | [SDT/McClelland needs] | ... | ... |
| Cognitive Biases | [top biases] | ... | ... |
| Attachment Style | [style] | ... | ... |

<!-- analyzed: YYYY-MM-DD, facts_count: N -->

## Communication Strategy

### When Requesting
**DO:**
- [Action] — [reasoning]
  [framework: tag + evidence]

**DON'T:**
- [Action] — [reasoning]
  [framework: tag + evidence]

### During Conflict
**DO:** ...
**DON'T:** ...

### When Reporting
**DO:** ...
**DON'T:** ...

### Routine Collaboration
**DO:** ...
**DON'T:** ...

### Data Gaps
- [ ] [Missing dimension or situation]: [what to collect and how]
```

## contradictions.md

Write/update the following in `PROFILE_DIR/<person-name>/contradictions.md`:

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
