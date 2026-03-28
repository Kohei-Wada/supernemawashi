# Psychological Framework Integration for profile-analyzer

## Context

The current profile-analyzer skill produces surface-level behavioral observations ("communicates politely", "responds slowly") but fails to generate actionable communication rules. By integrating established psychological frameworks, the analyzer can classify behavioral patterns and derive evidence-based DO/DON'T rules that reply-strategist directly consumes.

## Scope

- Rewrite `skills/profile-analyzer/SKILL.md` analysis steps and output format
- Add a Framework Reference appendix to SKILL.md
- Update `skills/reply-strategist/SKILL.md` to reference the new output structure
- Out of scope: data path migration (`~/.supernemawashi/` to `~/.local/share/`), profile-collector changes

## Chosen Frameworks

### Tier 1 (Always Analyze)

| # | Framework | Why Include |
|---|-----------|-------------|
| 1 | **Defense Mechanisms** | Only framework addressing behavior under threat. Passive aggression, avoidance, rationalization leave clear text traces. Merged with emotional regulation (venting, rumination, suppression). |
| 2 | **Thomas-Kilmann Conflict Modes** | Highest observability from text. 5 modes (competing, collaborating, compromising, avoiding, accommodating) map 1:1 to counter-strategies. |
| 3 | **Transactional Analysis Ego States** | Captures relational dynamics — how someone shifts behavior by audience. Track per-relationship (subordinates vs. superiors vs. peers). |
| 4 | **Core Motivators** (SDT + McClelland) | Only framework addressing what someone wants. Essential for proposal framing. SDT (autonomy, competence, relatedness) + McClelland (achievement, affiliation, power). |
| 5 | **Cognitive Biases** (curated workplace subset) | Most directly actionable. Each bias maps 1:1 to a framing strategy. 8-10 biases: status quo, anchoring, confirmation, sunk cost, authority, negativity, IKEA effect, loss aversion. |

### Tier 2 (When Sufficient Data Exists)

| # | Framework | Why Include |
|---|-----------|-------------|
| 6 | **Attachment Style** | Useful for trust, delegation, and reaction to silence/ambiguity. Anxious/avoidant distinction is most actionable. |

### Excluded

| Framework | Reason |
|-----------|--------|
| Big Five (OCEAN) | Too abstract for DO/DON'T rules. Relevant aspects covered by other frameworks. |
| DISC | Redundant with TKI + TA. Weaker empirical support. |
| Power Dynamics / SDO | Captured by TKI (competing) + TA (CP) + McClelland (power). |

## Analysis Flow (6 Steps)

### Step 1: Read Data
Read all profile files for the target person:
- `profile.md` — existing basic info and communication patterns
- `facts.md` — dated behavioral observations with source tags
- `relationship.md` — relationship context (if exists)

### Step 2: Behavioral Signal Extraction
For each facts.md entry, extract behavioral signals — not "what happened" but "what this reveals about the person." Each signal is tagged with relevant framework dimensions.

**Example:**
```
facts.md entry:
"Rear-guard criticism to Wada: 'Doesn't the alert being triggered == response needed?'"

Signals:
- Withholds information until subordinate acts, then criticizes [defense: info-withholding]
- Question format disguises criticism [TA: CP disguised as A]
- Maintains safe position by not committing upfront [motivator: safety/predictability]
```

This step is internal working — not written to profile.md.

### Step 3: Framework Classification
For each Tier 1 framework, aggregate signals and determine the dominant pattern. Output as a compact classification table. Apply Tier 2 only if 2+ relevant signals exist.

**Confidence rules:**

| Evidence Count | Confidence | Display |
|---|---|---|
| 3+ signals | Confirmed | Shown in table, rules generated normally |
| 1-2 signals | Hypothesis | Shown in table with "Hypothesis" tag, rules tagged `(hypothesis)` |
| 0 signals | Data Gap | Excluded from table, listed in Data Gaps section |

### Step 4: Core Pattern Synthesis
Write 1-3 sentences that unify the framework classifications into a single behavioral explanation. This is the "why behind everything" — the deepest insight.

**Example:** "Treats team members as potential threats rather than collaborators. All behavior optimizes for not being attacked — withholding information (no ammunition), rear-guard criticism (safe offensive), judgment avoidance (no commitments to be held to)."

### Step 5: Situation-Indexed Rule Generation
Using framework classifications from Step 3, generate DO/DON'T rules organized by 4 situation categories:

1. **When Requesting** — you need something from them
2. **During Conflict** — disagreement or tension
3. **When Reporting** — delivering news (good or bad)
4. **Routine Collaboration** — day-to-day interaction

Each rule must include:
- The concrete action (what to do or not do)
- Framework tag(s) citing which classification drives this rule
- Brief reasoning connecting the framework to the action

Rules from "Hypothesis" classifications are included but tagged `(hypothesis)`.

### Step 6: Write & Report
Write results to profile.md. Report summary to user including:
- Key patterns identified (with evidence counts)
- Recommended strategies (top 3 DO/DON'T highlights)
- Data gaps and collection recommendations

## Output Format (profile.md)

```markdown
## Behavioral Patterns

### Core Pattern
[1-3 sentence synthesis across all frameworks]

### Framework Classifications

| Framework | Classification | Confidence | Evidence |
|---|---|---|---|
| Defense Mechanisms | [mechanisms] | Confirmed/Hypothesis | [evidence summary] |
| Conflict Mode (TKI) | [modes, context-dependent] | ... | ... |
| Ego States (TA) | [states per relationship] | ... | ... |
| Core Motivators | [SDT/McClelland needs] | ... | ... |
| Cognitive Biases | [top biases] | ... | ... |
| Attachment Style | [style] | ... | ... |

### Communication Strategy

#### When Requesting
**DO:**
- [Action] [Framework: tag + evidence]
- ...

**DON'T:**
- [Action] [Framework: tag + evidence]
- ...

#### During Conflict
**DO:** ...
**DON'T:** ...

#### When Reporting
**DO:** ...
**DON'T:** ...

#### Routine Collaboration
**DO:** ...
**DON'T:** ...

### Data Gaps
- [ ] [Missing dimension]: [what to collect and how]
```

## Re-analysis Rules

- Each framework row embeds `<!-- analyzed: YYYY-MM-DD, facts_count: N -->` HTML comment
- On re-analysis: only update framework dimensions that have new facts since last analysis
- Lines tagged `<!-- manual -->` are preserved across re-analysis
- The Core Pattern is always regenerated (it depends on all frameworks)

## Framework Reference (SKILL.md Appendix)

SKILL.md includes a reference table for each framework to ensure consistent classification across sessions:

```markdown
## Framework Reference

### Defense Mechanisms
| Mechanism | Definition | Observable Signals | DO | DON'T |
|---|---|---|---|---|
| Avoidance | Evading threatening topics/decisions | Non-response, topic change, delayed reply on contentious topics only | Lower the stakes; break into small asks | Chase in the avoided channel; send long messages |
| Passive Aggression | Indirect resistance while appearing compliant | "Sure, I'll do it" + no action; backhanded compliments; strategic delays | Name the specific behavior neutrally | Call out "you're being passive-aggressive" |
| Rationalization | Post-hoc justification to protect self-image | Long explanations for failures; "because..." chains | Validate reasoning, then redirect to future | Argue against the justification directly |
| Projection | Attributing own behavior to others | Accusing others of their own patterns | Address the projected behavior factually | Mirror the accusation back |
| Displacement | Redirecting frustration to safe targets | Harsh to juniors after pressure from above | Don't engage when freshly stressed; revisit later | Confront during displacement episode |
| Info Withholding | Keeping information as leverage | Reveals info only after others commit | Present all your info first; leave no gaps | Share info incrementally (invites reciprocal withholding) |
| Venting | Extended emotional discharge | Long emotional messages, escalation | Let them finish before problem-solving | Jump to solutions mid-vent |
| Rumination | Returning to past grievances | Repeated references to old incidents | Acknowledge the past issue proactively | Dismiss or minimize the old incident |
| Suppression | Flat affect masking accumulation | Minimal emotional expression, then eventual explosion | Check in periodically; don't assume calm = fine | Pile on requests assuming they're handling it |

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
| Critical Parent (CP) | "You should", imperatives, blame | Respond from Adult: facts + options. Avoid Adapted Child submission. |
| Nurturing Parent (NP) | "Don't worry", protective, "let me help" | Accept support gracefully; respond from Adult or Free Child |
| Adult (A) | Facts, logical questions, "what are the options?" | Match with Adult: data, analysis, options |
| Free Child (FC) | Humor, informal, spontaneous ideas | Engage playfully when appropriate; don't shut down with CP |
| Adapted Child (AC) | "Sorry", hedging, "is that okay?" | Respond from NP or Adult to create safety; don't respond from CP |

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
| Confirmation | Only engages with supporting evidence | Present idea as consistent with their existing beliefs |
| Sunk Cost | Refuses to abandon failing projects they invested in | Acknowledge investment before proposing alternatives |
| Authority | Defers to seniority over evidence | Get senior stakeholder buy-in first |
| Negativity | Focuses on risks over opportunities | Lead with risk mitigation, not opportunity |
| IKEA Effect | Overvalues ideas they contributed to | Involve them in creating the solution |
| Loss Aversion | Reacts more strongly to losses than equivalent gains | Frame as "what we lose by not doing this" rather than "what we gain" |

### Attachment Style (Tier 2)
| Style | Observable Signals | DO | DON'T |
|---|---|---|---|
| Secure | Proportionate responses, comfortable with feedback | Communicate directly; give honest feedback | Over-explain or over-manage |
| Anxious | Follow-up messages, "did you see?", emotional escalation when ignored | Acknowledge receipt promptly; set clear timelines | Leave messages unread; give vague timelines |
| Avoidant | Short replies, infrequent check-ins, "I'll handle it" | Use async channels; respect autonomy; minimal meetings | Schedule unnecessary check-ins; require emotional debriefs |
| Disorganized | Contradictory messages, hot/cold, unpredictable | Be consistent and predictable yourself; don't mirror their inconsistency | Assume today's behavior predicts tomorrow's |
```

## Integration with reply-strategist

reply-strategist currently reads "Behavioral Patterns" and "Communication Strategy" sections. The new format is backward-compatible:
- "Behavioral Patterns" section still exists, now with richer content
- "Communication Strategy" section still exists, now situation-indexed with framework tags
- reply-strategist's Step 3 ("Analyze Situation") should map the user's context to one of the 4 situation categories, then read the corresponding DO/DON'T rules

**Minimal change to reply-strategist:** Add guidance in Step 3 to identify which situation category applies, and to use framework tags when explaining strategy choices to the user.

## Verification

1. Run the updated profile-analyzer on alice (richest dataset) — output should be comparable quality to the existing hand-written analysis
2. Run on fukuhara or arao (sparse dataset) — should produce hypothesis-tagged classifications and clear data gaps
3. Use reply-strategist with an analyzed profile — confirm it correctly reads and applies DO/DON'T rules from the new format
