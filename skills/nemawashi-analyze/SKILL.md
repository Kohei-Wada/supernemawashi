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

### Step 1.5: Archive existing output files

Before agent dispatch (Step 2) and synthesis writes (Step 3), invoke `archive.sh` (a sibling of this SKILL.md) once per output file that may already exist. The script is a no-op when the target is missing, so call it unconditionally — no need to check existence first.

For each framework slug enumerated in Step 1:

- Run: `bash <this-skill-dir>/archive.sh PROFILE_DIR/<name>/frameworks/<slug>.md`

For the top-level files updated by the synthesis pass:

- Run: `bash <this-skill-dir>/archive.sh PROFILE_DIR/<name>/profile.md`
- Run: `bash <this-skill-dir>/archive.sh PROFILE_DIR/<name>/relationship.md`

`archive.sh` moves each existing file to `<dir>/_archive/<stem>.<date>.<ext>` where `<date>` is taken from the file's `last_updated:` frontmatter (fallback: mtime). Same-day collisions are suffixed `.1`, `.2`, etc.

`contradictions.md` is intentionally NOT archived — it is regenerated each time but the loss is minor and the file is small.

### Step 2: Dispatch one framework-analyzer agent per framework

For each framework definition file, dispatch the `framework-analyzer` agent (defined at `agents/framework-analyzer.md`) in parallel. Each agent runs in an isolated context, reads its framework definition + the profile inputs, and writes one `PROFILE_DIR/<name>/frameworks/<slug>.md` file. The agent's full contract — input parameters, apply steps, output schema, return shape — lives in `agents/framework-analyzer.md`; do not duplicate it here.

#### Dispatch prompt per agent

```
framework_slug:              <slug>
framework_definition_path:   <absolute path to skills/nemawashi-analyze/frameworks/<slug>.md>
profile_dir:                 PROFILE_DIR/<name>/
output_path:                 PROFILE_DIR/<name>/frameworks/<slug>.md
today:                       YYYY-MM-DD
```

Issue all 6 dispatches in a single message (parallel). Each agent returns ONE line: `<slug>: <classification text> (<Confidence>)`. The orchestrator collects the lines; full content lives in each `frameworks/<slug>.md` file.

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
- **Archive before overwrite.** Prior versions of `profile.md`, `relationship.md`, and `frameworks/<slug>.md` are moved to a sibling `_archive/` directory before the new version is written (see Step 1.5). This is a stop-gap until #41 (append-only assertion log) lands.

## Multi-framework rules

Some rules naturally cite two frameworks (e.g. `[defense: info-withholding + TKI: competing]`). Place the rule under its **primary** framework's file and tag the secondary framework inline in the rule's bracket annotation. If the rule depends roughly equally on two, pick the one whose Signal Tags it references first. This keeps each file self-contained without duplicating rules.

---

## Framework File Contract

See `FRAMEWORK-CONTRACT.md` (relative to this skill) for the framework definition template and required fields.
