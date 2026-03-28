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

For each entry in facts.md, extract **behavioral signals** — not "what happened" but "what this reveals about the person psychologically." Tag each signal with relevant framework dimensions from the Framework Reference appendix.

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

For each Tier 1 framework, aggregate signals from Step 2 and determine the dominant pattern. Consult the Framework Reference appendix for definitions and observable signals.

**Tier 1 — Always Analyze:**
1. **Defense Mechanisms** — Which defense/coping mechanisms does this person default to?
2. **Conflict Mode (TKI)** — What is their conflict style? Does it change by audience (subordinates vs. superiors)?
3. **Ego States (TA)** — What ego state do they use with whom? Track per-relationship.
4. **Core Motivators** — What underlying need drives their behavior? (SDT + McClelland)
5. **Cognitive Biases** — Which biases consistently appear in their decisions?

**Tier 2 — Analyze Only If 2+ Relevant Signals Exist:**
6. **Attachment Style** — Secure, anxious, avoidant, or disorganized?

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

**Deriving rules from frameworks — use these principles:**
1. **Defense mechanisms → Avoid triggers.** Identify what activates the defense, and route around it.
2. **TKI conflict mode → Match negotiation style.** Don't use tentative language with a competing type. Don't force engagement with an avoiding type.
3. **TA ego states → Choose your response ego state.** If they go CP, respond from Adult (not Adapted Child). If they go AC, respond from NP or Adult.
4. **Core motivators → Frame proposals to satisfy their need.** Safety-motivated person? Lead with risk mitigation. Power-motivated? Frame as expanding their influence.
5. **Cognitive biases → Frame to work with the bias.** Status quo bias? Present change as an extension. IKEA effect? Involve them in creating the solution.
6. **Attachment style → Adjust communication cadence.** Anxious? Acknowledge promptly. Avoidant? Respect async, don't over-check-in.

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
- **Framework reference consistency** — Always consult the Framework Reference appendix below for definitions. Do not rely on general knowledge alone.

---

## Framework Reference

### Defense Mechanisms

| Mechanism | Definition | Observable Signals | DO | DON'T |
|---|---|---|---|---|
| Avoidance | Evading threatening topics or decisions | Non-response, topic change, delayed reply on contentious topics only | Lower the stakes; break into small asks | Chase in the avoided channel; send long messages |
| Passive Aggression | Indirect resistance while appearing compliant | "Sure, I'll do it" + no action; backhanded compliments; strategic delays | Name the specific behavior neutrally | Call out "you're being passive-aggressive" |
| Rationalization | Post-hoc justification to protect self-image | Long explanations for failures; "because..." chains | Validate reasoning, then redirect to future | Argue against the justification directly |
| Projection | Attributing own behavior to others | Accusing others of their own patterns | Address the projected behavior factually | Mirror the accusation back |
| Displacement | Redirecting frustration to safe targets | Harsh to juniors after pressure from above | Don't engage when freshly stressed; revisit later | Confront during displacement episode |
| Info Withholding | Keeping information as leverage or defense | Reveals info only after others commit | Present all your info first; leave no gaps | Share info incrementally (invites reciprocal withholding) |
| Venting | Extended emotional discharge | Long emotional messages, escalation | Let them finish before problem-solving | Jump to solutions mid-vent |
| Rumination | Returning to past grievances repeatedly | Repeated references to old incidents | Acknowledge the past issue proactively | Dismiss or minimize the old incident |
| Suppression | Flat affect masking emotional accumulation | Minimal emotional expression, then eventual explosion | Check in periodically; don't assume calm = fine | Pile on requests assuming they're handling it |

### Thomas-Kilmann Conflict Modes

| Mode | Assertiveness | Cooperativeness | Observable Signals | DO | DON'T |
|---|---|---|---|---|---|
| Competing | High | Low | Strong declaratives, overriding suggestions, "I decided" | Present with data; frame as serving their goals; be direct | Match force with force; use tentative language |
| Collaborating | High | High | Asks questions, builds on ideas, "what if we" | Engage fully; bring options; co-create | Rush to a quick answer; dismiss their input |
| Compromising | Mid | Mid | "Fair enough", offers trades, splits difference | Propose fair trades; be transparent about priorities | Hold out for everything; appear inflexible |
| Avoiding | Low | Low | Non-response, "let's table this", delayed replies | Break into small low-threat asks; reduce perceived risk | CC others to force engagement; send long confrontational messages |
| Accommodating | Low | High | Quick agreement, "sounds good", rarely pushes back | Explicitly ask for concerns; check genuine buy-in | Mistake agreement for buy-in; pile on requests |

### Transactional Analysis Ego States

| State | Markers | Effective Response |
|---|---|---|
| Critical Parent (CP) | "You should", imperatives, blame, judgmental tone | Respond from Adult: facts + options. Avoid Adapted Child submission. |
| Nurturing Parent (NP) | "Don't worry", protective, "let me help" | Accept support gracefully; respond from Adult or Free Child |
| Adult (A) | Facts, logical questions, "what are the options?" | Match with Adult: data, analysis, options |
| Free Child (FC) | Humor, informal, spontaneous ideas | Engage playfully when appropriate; don't shut down with CP |
| Adapted Child (AC) | "Sorry", hedging, "is that okay?", excessive deference | Respond from NP or Adult to create safety; don't respond from CP |

**Key:** Track which ego state the person uses with different audiences (subordinates, peers, superiors). State shifts reveal power dynamics.

### Core Motivators

| Motivator | Source | Observable Signals | Framing Strategy |
|---|---|---|---|
| Safety / Predictability | SDT | Resists change, seeks certainty, avoids risk | Lead with risk mitigation; emphasize stability |
| Autonomy | SDT | "I'd prefer my way", resists process mandates | Specify outcome, let them choose the path |
| Competence | SDT | Volunteers for expertise areas, avoids unfamiliar domains | Acknowledge expertise; provide clear specs for new areas |
| Relatedness | SDT | Social messages, team-building, personal questions | Build personal rapport before business asks |
| Achievement | McClelland | Tracks progress, references KPIs, competitive with self | Include metrics, timelines, visible success criteria |
| Affiliation | McClelland | Consensus-building, discomfort with disagreement | Frame as team benefit; avoid zero-sum framing |
| Power | McClelland | Directs others, frames ideas as impact/influence | Frame proposal as expanding their influence |

### Cognitive Biases (Workplace Subset)

| Bias | Observable Signals | Framing Strategy |
|---|---|---|
| Status Quo | "We've always done it this way", resists change proposals | Frame changes as extensions of current approach, not replacements |
| Anchoring | First number/option dominates their response | Strategically choose your opening number/proposal |
| Confirmation | Only engages with evidence supporting their position | Present idea as consistent with their existing beliefs |
| Sunk Cost | Refuses to abandon failing projects they invested in | Acknowledge investment before proposing alternatives |
| Authority | Defers to seniority over evidence | Get senior stakeholder buy-in first |
| Negativity | Focuses on risks and problems over opportunities | Lead with risk mitigation, not opportunity |
| IKEA Effect | Overvalues ideas they contributed to | Involve them in creating the solution |
| Loss Aversion | Reacts more strongly to losses than equivalent gains | Frame as "what we lose by not doing this" rather than "what we gain" |

### Attachment Style (Tier 2)

| Style | Observable Signals | DO | DON'T |
|---|---|---|---|
| Secure | Proportionate responses, comfortable with feedback | Communicate directly; give honest feedback | Over-explain or over-manage |
| Anxious | Follow-up messages, "did you see?", emotional escalation when ignored | Acknowledge receipt promptly; set clear timelines | Leave messages unread; give vague timelines |
| Avoidant | Short replies, infrequent check-ins, "I'll handle it" | Use async channels; respect autonomy; minimal meetings | Schedule unnecessary check-ins; require emotional debriefs |
| Disorganized | Contradictory messages, hot/cold, unpredictable reactions | Be consistent and predictable yourself; don't mirror their inconsistency | Assume today's behavior predicts tomorrow's |
