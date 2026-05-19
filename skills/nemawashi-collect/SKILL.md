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

**profile.md** — Write with this structure. These are the **manual sections** that `nemawashi-analyze` preserves verbatim across re-analyses; the synthesis pass adds `## Core Pattern` and `## Framework Summary` underneath without touching these.

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

## Active Channels
- [Slack channels, email threads, repos where this person is active]

## Work Patterns
- [Meeting cadence, focus hours, escalation patterns — fill what's observable]
```

Leave the analysis sections (`## Core Pattern`, `## Framework Summary`) to `nemawashi-analyze`; the synthesis pass writes them. Per-framework files at `frameworks/<slug>.md` are also produced by `nemawashi-analyze`, not here.

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

## Parallel Dispatch (Batch / multi-target Mode)

When you need to collect for multiple targets at once — invoked by `nemawashi-discover` Step 5, or directly by the user as "collect for X, Y, Z in parallel" — do not run the per-adapter recipes inline N times. Dispatch the `profile-collector` agent (defined at `agents/profile-collector.md`) once per target. Each agent runs in an isolated context and writes only that target's profile files.

The parent (this skill running in the main session) is responsible for:

1. **Resolving identity once.** Read `${PROFILE_DIR}/.identity.md`. If it is missing or the user passed `--refresh-identity`, run each available adapter's `## Identity Resolution` section to produce it (see `IDENTITY-SCHEMA.md` for the cache contract and lifecycle). Write atomically.
2. **Filtering adapters** by which MCP tools are available in this session.
3. **Composing a uniform prompt** per target — see the prompt template below.
4. **Dispatching N `profile-collector` agents in parallel** (one Agent tool invocation per target, all in a single message).
5. **Aggregating** the one-line reports each agent returns. Surface failures and skipped adapters in the final summary.

### profile-collector dispatch prompt template

```
target_name: <slug>
target_full_name: <Full Name>
target_role: <Role or "unknown">
profile_dir: ${PROFILE_DIR}/<slug>/
today: <YYYY-MM-DD>

identity:
- slack:    handle=<...>, user_id=<...>, email=<...>
- gmail:    primary_email=<...>, work_email=<...>
- calendar: primary_calendar_id=<...>, timezone=<...>
- github:   login=<...>, email=<...>

relationship_hint: <one-liner from the user, optional>

Adapters available in this session: <comma-separated slugs>

Read the adapter files at skills/nemawashi-collect/adapters/<slug>.md for the
above slugs (plus ADAPTER-CONTRACT.md and FACTS-SCHEMA.md). Follow each
adapter's Collection Recipe + Fact Extraction. Use the identity values
above wherever a recipe says "the user's handle / email / login" — do NOT
re-resolve identity.

Return one report block per the agent's documented output shape.
```

Sub-agents called this way perform zero identity-resolution MCP calls and zero re-reads of skill-internal files outside the adapter set they actually use. Recipe drift is impossible because the agent reads the adapter files at the canonical path.

## Key Principles

- **Collect, don't interpret** — This skill gathers raw data. Leave analysis to nemawashi-analyze.
- **Cite sources** — Every fact in facts.md must have a source tag ([slack], [gmail], etc.)
- **Ask about relationship** — Only the user knows their subjective relationship with the person. Always ask.
- **Respect privacy** — Only collect data from sources the user has MCP access to. Do not speculate beyond available data.
