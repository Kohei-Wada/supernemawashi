---
name: profile-analyzer
description: Use when user wants to analyze a person's behavioral patterns - reads profile data from ~/.local/share/supernemawashi/profiles/ and adds psychological analysis with actionable DO/DON'T communication rules
---

# Profile Analyzer

Analyze a person's collected profile data using psychological frameworks to identify behavioral patterns, classify psychological tendencies, and generate evidence-based communication strategies.

## When to Use

- User says "analyze X" or "what kind of person is X?"
- After profile-collector finishes (suggest this automatically)
- User wants to update analysis with new data

## Prerequisites

A profile must exist at `~/.local/share/supernemawashi/profiles/<person-name>/profile.md`. If it doesn't, tell the user to run profile-collector first.

## Process

### Step 1: Read All Profile Data

Read the following files for the target person:
- `~/.local/share/supernemawashi/profiles/<person-name>/profile.md`
- `~/.local/share/supernemawashi/profiles/<person-name>/facts.md` (if exists)
- `~/.local/share/supernemawashi/profiles/<person-name>/relationship.md` (if exists)

### Step 2: Behavioral Signal Extraction

Read all `*.md` files in the `frameworks/` directory (relative to this skill). For each entry in facts.md, extract **behavioral signals** — not "what happened" but "what this reveals about the person psychologically." Tag each signal with relevant framework dimensions using each framework file's Reference Table and Signal Tags.

Facts entries follow the standard format: `- [YYYY-MM-DD] [source] Description text (url)`. Parse each line matching this pattern as one fact entry.

**Example:**

```
facts.md entry:
- [2026-03-27] [slack] Rear-guard criticism to Alice: 'Doesn't the alert being triggered == response needed?' (https://slack.com/archives/C123/p456)

Signals:
- Withholds information until subordinate acts, then criticizes [defense: info-withholding]
- Question format disguises criticism [TA: CP disguised as A]
- Maintains safe position by not committing upfront [motivator: safety/predictability]
```

This step is internal working — do NOT write it to profile.md. Use it as input for the following steps.

### Step 3: Framework Classification

For each framework file loaded in Step 2, check its `tier` frontmatter field and aggregate signals accordingly:

- **Tier 1** — Always analyze. Determine the dominant pattern using the framework file's Classification Guidance section.
- **Tier 2** — Analyze only if 2+ relevant signals exist for this framework. Skip otherwise.

**Confidence rules:**

| Evidence Count | Confidence | Display |
|---|---|---|
| 3+ signals | Confirmed | Shown in table, rules generated normally |
| 1-2 signals | Hypothesis | Shown in table with "Hypothesis" tag, rules tagged `(hypothesis)` |
| 0 signals | Data Gap | Excluded from table, listed in Data Gaps section |

Output the classification as the **Framework Classifications** table in profile.md.

### Step 4: Core Pattern Synthesis

Write 1-3 sentences that unify the framework classifications into a single behavioral explanation — the "why behind everything." This should be the deepest insight about what drives this person.

**Example:** "Treats team members as potential threats rather than collaborators. All behavior optimizes for not being attacked — withholding information (no ammunition), rear-guard criticism (safe offensive), judgment avoidance (no commitments to be held to)."

Output this as the **Core Pattern** section in profile.md.

### Step 5: Situation-Indexed Rule Generation

Using the framework classifications from Step 3, generate concrete DO/DON'T rules organized by these 4 situation categories:

1. **When Requesting** — you need something from them
2. **During Conflict** — disagreement or tension
3. **When Reporting** — delivering news (good or bad)
4. **Routine Collaboration** — day-to-day interaction

**Each rule MUST include:**
- The concrete action (what to do or not do)
- Framework tag(s) citing which classification drives this rule (e.g., `[defense: info-withholding + TKI: competing]`)
- Brief reasoning connecting the framework to the action

**Deriving rules from frameworks:** For each classified framework, read its Rule Generation section and apply it to derive situation-indexed DO/DON'T rules.

Rules from "Hypothesis" classifications are included but tagged `(hypothesis)`.

Output as the **Communication Strategy** section in profile.md.

### Step 6: Contradiction Detection

Compare facts.md entries to identify inconsistencies — statements or behaviors that contradict each other. Look for:

1. **Verbal contradictions** — Person said X on one occasion but said the opposite on another
2. **Say-do gaps** — Person stated an intention or value but acted against it
3. **Audience-dependent behavior** — Person behaves one way with subordinates and the opposite with superiors
4. **Temporal reversals** — Person took a position, then later reversed it without acknowledging the change

**Rules:**
- Each contradiction MUST cite 2+ specific facts.md entries as evidence (with dates and sources)
- Do NOT flag legitimate changes of mind where the person acknowledged the shift
- Do NOT flag minor inconsistencies — only contradictions that reveal a meaningful behavioral pattern
- If no contradictions are found, write contradictions.md with an empty entries section and a note: "No contradictions detected with current data."

Output to `contradictions.md` in the format specified below.

### Step 7: Write & Report

Write all results to profile.md in the format specified below. Update relationship.md "Approach Strategy" section if it exists. Write contradiction analysis to contradictions.md.

**Report to user:**
- Core Pattern (the synthesis)
- Top 3 most important DO/DON'T rules with reasoning
- Contradictions detected (count and most significant, if any)
- Data Gaps and what to collect next

## Output Format (profile.md)

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

## Output Format (contradictions.md)

Write/update the following in `~/.local/share/supernemawashi/profiles/<person-name>/contradictions.md`:

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

## Re-analysis Rules

- Check `<!-- analyzed: YYYY-MM-DD, facts_count: N -->` comment in profile.md
- If facts.md has new entries since last analysis, re-run Steps 2-7
- Lines tagged `<!-- manual -->` are user additions — preserve them across re-analysis
- The Core Pattern is always regenerated (it depends on all frameworks)
- **Update, don't overwrite** — when re-analyzing, preserve manually added notes outside auto-generated sections

## Key Principles

- **Evidence-based** — Every classification and rule must cite specific data points from facts.md. No speculation without evidence.
- **Non-judgmental framing** — Describe behaviors and patterns, not character. "Defaults to avoidance under conflict" not "is a coward."
- **Actionable output** — Every framework classification MUST produce at least one DO/DON'T rule. If it can't, don't include the classification.
- **Hypothesis transparency** — Low-data classifications are included but clearly marked. The user decides whether to act on hypotheses.
- **Framework reference consistency** — Always consult the framework files in `frameworks/` for definitions. Do not rely on general knowledge alone.

---

## Framework File Contract

Each `*.md` file in the `frameworks/` directory defines one psychological framework. To add a new framework, create a file following this template:

```markdown
---
framework: [Name]
tier: 1 or 2
output_label: [Label for Framework Classifications table]
---

# [Name]

## Purpose
[1-2 sentences: what this framework measures and why it matters for communication strategy]

## Classification Guidance
[How to aggregate signals into a classification for this framework]

## Reference Table
[Lookup table with types, observable signals, and DO/DON'T actions]

## Rule Generation
[Principle for deriving DO/DON'T rules from this framework's classifications]

## Signal Tags
[Tag format and enumerated list of valid tags]
```

**Required fields:** All sections above are mandatory. `tier: 1` frameworks are always analyzed. `tier: 2` frameworks are analyzed only when 2+ relevant signals exist. The `output_label` value appears in the Framework Classifications table in profile.md.
