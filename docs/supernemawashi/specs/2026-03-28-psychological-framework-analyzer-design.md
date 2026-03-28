# Psychological Framework Integration for profile-analyzer

## Context

The current profile-analyzer skill produces surface-level behavioral observations ("communicates politely", "responds slowly") but fails to generate actionable communication rules. By integrating established psychological frameworks, the analyzer can classify behavioral patterns and derive evidence-based DO/DON'T rules that reply-strategist directly consumes.

## Scope

- Rewrite `skills/profile-analyzer/SKILL.md` analysis steps and output format
- Add a Framework Reference appendix to SKILL.md
- Update `skills/reply-strategist/SKILL.md` to reference the new output structure
- Out of scope: ~~data path migration (`~/.supernemawashi/` to `~/.local/share/`)~~ (done), profile-collector changes

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
"Rear-guard criticism to Alice: 'Doesn't the alert being triggered == response needed?'"

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

## Output Format

See `skills/profile-analyzer/OUTPUT-FORMAT.md` for the canonical output format specifications for profile.md and contradictions.md.

## Re-analysis Rules

See the Re-analysis Rules section in `skills/profile-analyzer/SKILL.md` for the canonical rules.

## Framework Reference

The individual framework files in `skills/profile-analyzer/frameworks/` are the single source of truth for all framework definitions, reference tables, signal tags, and rule generation guidance. See `skills/profile-analyzer/FRAMEWORK-CONTRACT.md` for the file template.

## Integration with reply-strategist

reply-strategist currently reads "Behavioral Patterns" and "Communication Strategy" sections. The new format is backward-compatible:
- "Behavioral Patterns" section still exists, now with richer content
- "Communication Strategy" section still exists, now situation-indexed with framework tags
- reply-strategist's Step 3 ("Analyze Situation") should map the user's context to one of the 4 situation categories, then read the corresponding DO/DON'T rules

**Minimal change to reply-strategist:** Add guidance in Step 3 to identify which situation category applies, and to use framework tags when explaining strategy choices to the user.

## Verification

1. Run the updated profile-analyzer on john (richest dataset) — output should be comparable quality to the existing hand-written analysis
2. Run on bob or carol (sparse dataset) — should produce hypothesis-tagged classifications and clear data gaps
3. Use reply-strategist with an analyzed profile — confirm it correctly reads and applies DO/DON'T rules from the new format
