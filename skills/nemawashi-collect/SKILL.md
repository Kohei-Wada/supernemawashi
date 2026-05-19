---
name: nemawashi-collect
description: Use when user wants to create or update a person's profile - collects data from available MCP sources (Slack, Gmail, Calendar, GitHub, and any other discoverable sources via the adapter pattern) and writes to PROFILE_DIR
---

# Profile Collector

Collect data about a person from available MCP sources and create or update their profile in `PROFILE_DIR/`.

## When to Use

- User says "create a profile for X"
- User says "update X's profile"
- User says "collect info about X"
- Another skill (e.g., nemawashi-reply) detects a stale or missing profile

## Process

### Step 1: Identify the Target

Ask the user:
- Who is the target person?
- What is their role/team? (if not already known)
- Any specific MCP sources to prioritize? (default: all available)

### Step 2: Check Existing Profile

Read `PROFILE_DIR/<person-name>/profile.md` if it exists. Note what data is already collected and when it was last updated.

### Step 3: Collect Data from MCP Sources (Adapter-Driven)

Read all `*.md` files in the `adapters/` directory (relative to this skill). For each adapter:

1. Check the adapter's **MCP Tools Required** section against the tools available in this session.
2. If all required tools are present, follow the adapter's **Collection Recipe** and apply its **Fact Extraction** rules.
3. If any required tools are missing, skip the adapter and note the gap in the final report.

After running every known adapter, **scan for additional MCP servers** that look communication-relevant but are not covered by an adapter (e.g., Discord, Linear, Notion, Drive). For each uncovered source:

1. Identify search/read tools that can be queried by the target's identifiers (name, email, handles).
2. Perform best-effort collection following the same shape as the known adapters.
3. Tag fact entries with `[<slug>]` where `<slug>` is derived from the MCP server name (e.g., `[discord]`, `[linear]`).
4. If a source proves useful repeatedly, recommend writing a dedicated `adapters/<slug>.md` file for it (see `ADAPTER-CONTRACT.md`).

### Step 4: Write Profile Files

Create the directory `PROFILE_DIR/<person-name>/` if it doesn't exist.

**profile.md** — Write with this structure:

```
---
name: [Full Name]
role: [Role/Title]
team: [Team Name]
last_updated: [YYYY-MM-DD]
sources: [list of MCP sources used]
---

## Basic Info
- Title: [title]
- Reports to: [manager, if known]
- Tenure: [if known]

## Communication Patterns
- [Observed patterns from collected data]
- [Response time tendencies]
- [Preferred channels]
- [Tone and formality level]

## Behavioral Patterns (Level B)
<!-- Left empty for nemawashi-analyze to fill -->
```

**relationship.md** — Ask the user about their relationship:

```
---
person: [Full Name]
relation: [relationship description]
last_updated: [YYYY-MM-DD]
---

## Relationship with Me
- [User-provided context about their relationship]

## Approach Strategy
<!-- Populated after nemawashi-analyze runs -->
```

**facts.jsonl** — Append one observable behavior per line, following the canonical schema in `FACTS-SCHEMA.md`. New entries always go here; never modify a legacy `facts.md` if one is present (consumers read both).

**Entry format rules:**
- One JSON object per line (JSONL); no top-level metadata block — person info lives in `profile.md`.
- Required fields: `date` (`YYYY-MM-DD` or `YYYY-MM`), `source` (the adapter's `output_tag` or `manual` for user-provided facts), `content` (one observable behavior — what they said or did).
- Optional fields are adapter-specific — see `FACTS-SCHEMA.md` and each adapter file.
- Append-only. Don't read-modify-write the whole file just to add an entry.

**Examples:**
```jsonl
{"date":"2026-03-27","source":"slack","content":"Rear-guard criticism to subordinate about alert handling","url":"https://acme.slack.com/archives/C123/p456","channel":"#engineering"}
{"date":"2026-03-27","source":"gmail","content":"Accepted meeting invitation for design review as passive participant"}
{"date":"2026-03-26","source":"calendar","content":"Attended ops meeting organized by team lead","meeting_title":"Ops Weekly"}
```

### Step 5: Suggest Next Steps

After collection, suggest:
- "Profile created. Run nemawashi-analyze to identify behavioral patterns?"
- If the profile already existed: summarize what was updated

## Key Principles

- **Collect, don't interpret** — This skill gathers raw data. Leave analysis to nemawashi-analyze.
- **Cite sources** — Every fact in facts.md must have a source tag ([slack], [gmail], etc.)
- **Ask about relationship** — Only the user knows their subjective relationship with the person. Always ask.
- **Respect privacy** — Only collect data from sources the user has MCP access to. Do not speculate beyond available data.
