---
name: nemawashi-analyze
description: Use when user wants to analyze a person's behavioral patterns - reads profile data and adds psychological analysis with actionable DO/DON'T communication rules
---

# Profile Analyzer

Analyze a person's collected profile data using psychological frameworks to identify behavioral patterns, classify psychological tendencies, and generate evidence-based communication strategies.

The work is decomposed into independent per-framework agents (one per framework, dispatched in parallel) plus a synthesis pass. Each framework owns its own file under `frameworks/<slug>.md`, and the top-level `profile.md` is a slim index that holds Core Pattern + summary table.

## When to Use

- User says "analyze X" or "what kind of person is X?"
- After nemawashi-collect finishes (suggest this automatically)
- User wants to update analysis with new data

## Prerequisites

A profile must exist at `PROFILE_DIR/<person-name>/`. If `profile.md` is missing or there is no `facts.jsonl`/`facts.md`, tell the user to run `nemawashi-collect` first.

## Process

### Step 1: Read shared inputs

Read these files once, in the main session (shared input for every per-framework agent):

- `PROFILE_DIR/<person-name>/profile.md`
- `PROFILE_DIR/<person-name>/facts.jsonl` (newer profiles)
- `PROFILE_DIR/<person-name>/facts.md` (legacy profiles)
- `PROFILE_DIR/<person-name>/relationship.md` (if exists)

If both `facts.jsonl` and `facts.md` exist, both are read and merged (sort by date descending) — the dual-read transition.

Also enumerate the framework definition files: every `*.md` under `frameworks/` (relative to this skill).

### Step 2: Dispatch one agent per framework

For each framework file, dispatch a subagent (general-purpose) with the prompt template below. The agents run in **parallel** — they share no state and write to disjoint output files.

#### Agent prompt template

```
You are analyzing one psychological framework for a single person.

Framework definition file: <ABSOLUTE_PATH_TO_FRAMEWORK_DEF>
Profile directory:         PROFILE_DIR/<name>/
Output file:               PROFILE_DIR/<name>/frameworks/<slug>.md
Today's date:              YYYY-MM-DD

Read these inputs:
- The framework definition file above (Reference Table, Signal Tags, Classification Guidance, Rule Generation, tier).
- facts.jsonl in the profile dir (one JSON record per line; schema at skills/nemawashi-collect/FACTS-SCHEMA.md). Read facts.md if it also exists.
- relationship.md in the profile dir if it exists.

Steps:

1. Behavioral signal extraction. Scan each fact entry. Tag every relevant signal with this framework's Signal Tags. Skip facts that surface no signal for this framework.

2. Tier check. Read the framework's `tier` frontmatter. If tier 2 and fewer than 2 signals were found, emit a Data Gap result (see Output) and stop.

3. Classification. Aggregate signals per the framework's Classification Guidance. Pick the dominant pattern (or patterns if the framework supports multiple, e.g. TKI mode-with-context).

4. Confidence assignment.
   - 3+ signals → Confirmed
   - 1-2 signals → Hypothesis
   - 0 signals → Data Gap

5. Rule generation. For the four situation categories (When Requesting, During Conflict, When Reporting, Routine Collaboration), derive DO/DON'T rules per the framework's Rule Generation section. Each rule must cite a signal tag and brief reasoning. Rules from Hypothesis classifications are tagged `(hypothesis)`. If no rule is applicable for a situation, write `- (no framework-specific rule for this situation)` rather than fabricating one.

Output (atomic write to PROFILE_DIR/<name>/frameworks/<slug>.md):

---
framework: <slug>
classification: <one-line classification text>
confidence: Confirmed | Hypothesis | Data Gap
last_updated: YYYY-MM-DD
---

# <Framework display name>

## Classification
<1-3 sentences explaining the classification.>

## Evidence
- [YYYY-MM-DD] <fact citation> → <signal explanation> [signal: <tag>]
- ...

## Rules

### When Requesting
**DO:**
- <Action> — <reasoning> [signal: <tag>]

**DON'T:**
- <Action> — <reasoning> [signal: <tag>]

### During Conflict
**DO:** ...
**DON'T:** ...

### When Reporting
**DO:** ...
**DON'T:** ...

### Routine Collaboration
**DO:** ...
**DON'T:** ...

If the classification is Data Gap, omit the Rules section entirely and add a "## Data Gap" section explaining what evidence would be needed.

Return one line to the orchestrator in this exact shape:

<slug>: <classification text> (Confidence)

Examples:
  defense-mechanisms: Information withholding + Intellectualization (Confirmed)
  attachment-style: Data Gap
```

The orchestrator collects the one-line summaries; the full content lives in each `frameworks/<slug>.md` file.

### Step 3: Wait for all agents, then synthesize

After every dispatched agent returns, the orchestrator runs the synthesis pass in the main session:

1. Read every `PROFILE_DIR/<name>/frameworks/*.md` just produced.
2. Write `profile.md` per the format in `OUTPUT-FORMAT.md`:
   - Preserve manual / non-analysis sections (Basic Info, Communication Patterns, Active Channels, Work Patterns) if they exist.
   - Replace the **Core Pattern** section with a fresh 1-3 sentence synthesis that unifies the framework files into a single behavioral explanation.
   - Replace the **Framework Summary** table — one row per framework, pulled from each file's frontmatter (`classification`, `confidence`) plus a relative link to the file.
   - Update the trailing `<!-- analyzed: YYYY-MM-DD, facts_count: N -->` comment.
3. Write `contradictions.md` (cross-framework inconsistencies — verbal contradictions, say-do gaps, audience-dependent behavior, temporal reversals). Cite 2+ facts per contradiction. If none are detected, write the empty-state template per `OUTPUT-FORMAT.md`.
4. Update `relationship.md` "Approach Strategy" section if it exists.

### Step 4: Report

Print to the user:

- The Core Pattern.
- A summary table (framework → classification → confidence → file path).
- Top 3 rules across frameworks (pick the highest-confidence + most actionable ones).
- Contradictions detected (count + most significant).
- Data Gaps and what to collect next.

## Output Format

See `OUTPUT-FORMAT.md` (relative to this skill) for full schemas:

- The new slim `profile.md` (Core Pattern + Framework Summary + preserved manual sections).
- The per-framework file at `frameworks/<slug>.md`.
- `contradictions.md` (unchanged).

## Re-analysis Rules

- Check `<!-- analyzed: YYYY-MM-DD, facts_count: N -->` in `profile.md`.
- If `facts.jsonl` / `facts.md` has new entries since last analysis, re-dispatch the per-framework agents.
- Re-analysis **replaces** each `frameworks/<slug>.md` atomically (write to temp, mv on success).
- Lines tagged `<!-- manual -->` are user additions — preserve them across re-analysis.
- The Core Pattern and Framework Summary are always regenerated (they depend on all frameworks).

## Key Principles

- **One framework per file.** Each `frameworks/<slug>.md` is independently analyzable, replaceable, and consumable. Cross-profile queries grep on a single path.
- **Parallel dispatch.** Wall-clock cost is bounded by the slowest framework + synthesis, not the sum.
- **Evidence-based.** Every classification and rule cites specific signals from facts. No speculation without evidence.
- **Non-judgmental framing.** Describe behaviors and patterns, not character.
- **Actionable.** Every Confirmed classification produces at least one situation-indexed DO/DON'T rule. If it can't, downgrade to Hypothesis or Data Gap.
- **Hypothesis transparency.** Low-data classifications are kept but clearly marked.
- **Framework reference consistency.** Always consult the definition under `frameworks/` — never rely on general knowledge alone.

## Multi-framework rules

Some rules naturally cite two frameworks (e.g. `[defense: info-withholding + TKI: competing]`). Place the rule under its **primary** framework's file and tag the secondary framework inline in the rule's bracket annotation. If the rule depends roughly equally on two, pick the one whose Signal Tags it references first. This keeps each file self-contained without duplicating rules.

---

## Framework File Contract

See `FRAMEWORK-CONTRACT.md` (relative to this skill) for the framework definition template and required fields.
