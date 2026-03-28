---
name: profile-collector
description: Use when user wants to create or update a person's profile - collects data from MCP sources (Slack, Gmail, Calendar, GitHub) and writes to ~/.supernemawashi/profiles/
---

# Profile Collector

Collect data about a person from available MCP sources and create or update their profile in `~/.supernemawashi/profiles/`.

## When to Use

- User says "create a profile for X"
- User says "update X's profile"
- User says "collect info about X"
- Another skill (e.g., reply-strategist) detects a stale or missing profile

## Process

### Step 1: Identify the Target

Ask the user:
- Who is the target person?
- What is their role/team? (if not already known)
- Any specific MCP sources to prioritize? (default: all available)

### Step 2: Check Existing Profile

Read `~/.supernemawashi/profiles/<person-name>/profile.md` if it exists. Note what data is already collected and when it was last updated.

### Step 3: Collect Data from MCP Sources

Use available MCP tools to gather data. For each source:

**Slack:**
- Search for messages from/mentioning the person using `slack_search_public_and_private`
- Read recent channels they're active in using `slack_read_channel`
- Check their profile using `slack_read_user_profile`
- Look for patterns: response times, tone, frequent phrases, topics

**Gmail:**
- Search for email threads with the person using `gmail_search_messages`
- Read recent threads using `gmail_read_thread`
- Look for patterns: formality level, response time, decision-making style

**Calendar:**
- Check shared meetings using `gcal_list_events`
- Note meeting frequency, types of meetings they attend

**GitHub (if applicable):**
- PR review style, comment tone, approval/rejection patterns

### Step 4: Write Profile Files

Create the directory `~/.supernemawashi/profiles/<person-name>/` if it doesn't exist.

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
<!-- Left empty for profile-analyzer to fill -->
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
<!-- Populated after profile-analyzer runs -->
```

**facts.md** — Record notable statements found during collection:

```
## [Date]
- [source] [Notable statement or action]
```

### Step 5: Suggest Next Steps

After collection, suggest:
- "Profile created. Run profile-analyzer to identify behavioral patterns?"
- If the profile already existed: summarize what was updated

## Key Principles

- **Collect, don't interpret** — This skill gathers raw data. Leave analysis to profile-analyzer.
- **Cite sources** — Every fact in facts.md must have a source tag ([slack], [gmail], etc.)
- **Ask about relationship** — Only the user knows their subjective relationship with the person. Always ask.
- **Respect privacy** — Only collect data from sources the user has MCP access to. Do not speculate beyond available data.
