---
name: nemawashi-reply
description: Use when user needs help replying to someone, crafting a message, or deciding what to say - references profiles to tailor communication strategy
---

# Reply Strategist

Help the user craft optimal replies and messages by leveraging profile data about the recipient.

## When to Use

- User says "how should I reply to X?"
- User says "what should I say to X about Y?"
- User asks for help writing a Slack message, email, or any communication
- User is dealing with a difficult conversation

## Process

### Step 1: Identify Context

Determine:
- **Who** is the recipient?
- **What** is the topic/situation?
- **Where** will this be sent? (Slack, email, in-person, etc.)
- **What outcome** does the user want?

### Step 2: Load Profile (selective)

Read the recipient's profile from `PROFILE_DIR/<person-name>/`. The profile is split into a slim index (`profile.md`) plus per-framework files (`frameworks/<slug>.md`). Load only what the current situation needs:

**Always load:**
- `profile.md` — Basic Info, Core Pattern, Framework Summary (the synthesis).
- `relationship.md` — User's relationship and approach strategy.
- `contradictions.md` — Known contradictions (relevant for difficult conversations; cheap to load).

**Conditionally load** (per Step 3's situation mapping). The framework slugs referenced below are the canonical set registered in [`skills/nemawashi-analyze/FRAMEWORKS.md`](../nemawashi-analyze/FRAMEWORKS.md); add a row + a mapping entry below whenever a new framework lands there:

| Situation | Always load | Add if signals suggest |
|---|---|---|
| **When Requesting** | `frameworks/core-motivators.md`, `frameworks/cognitive-biases.md` | `frameworks/transactional-analysis-ta.md` (status-charged ask) |
| **During Conflict** | `frameworks/thomas-kilmann-tki.md`, `frameworks/defense-mechanisms.md` | `frameworks/transactional-analysis-ta.md` (CP↔AC dynamic), `frameworks/attachment-style.md` (trust rupture) |
| **When Reporting** | `frameworks/defense-mechanisms.md`, `frameworks/core-motivators.md` | `frameworks/cognitive-biases.md` (loss-aversive recipient) |
| **Routine Collaboration** | `frameworks/transactional-analysis-ta.md`, `frameworks/core-motivators.md` | `frameworks/attachment-style.md` (delegation/trust question) |

If a `frameworks/<slug>.md` does not exist or its frontmatter says `confidence: Data Gap`, skip it.

**Recent facts.** Read only the most-recent fact entries (last ~10) for context continuity — the framework files already encode the analysis. Read `facts.jsonl` (newer) / `facts.md` (legacy); if both exist, read both and merge.

**If no profile exists:** Tell the user and offer two options:
1. Run `nemawashi-collect` first for a data-informed reply.
2. Proceed without a profile (generic advice only).

**If `frameworks/` is missing but `profile.md` exists** (pre-split profile): tell the user to run `nemawashi-analyze` (or `/supernemawashi:nemawashi-migrate` to bulk-upgrade), then proceed loading `profile.md` only.

**If profile is stale** (`last_updated` > 30 days): suggest updating, but proceed with existing data if the user wants a quick reply.

### Step 3: Analyze the Situation

**Map to situation category.** Determine which of the 4 categories defined in [using-supernemawashi → Situation Categories](../using-supernemawashi/SKILL.md#situation-categories) applies.

Read the DO/DON'T rules for that situation category **from each loaded `frameworks/<slug>.md` file's `## Rules → ### <situation>` block**. These rules are backed by psychological framework analysis (defense mechanisms, conflict modes, ego states, motivators, cognitive biases) — use the per-rule `[signal: ...]` tags to explain your reasoning to the user. The cross-framework synthesis is in `profile.md → Core Pattern`.

Based on profile data, also assess:
- **Recipient's likely reaction** — Given their behavioral patterns and framework classifications, how will they probably respond to this topic?
- **Timing** — Is now a good time based on their patterns? (e.g., avoid mornings if they're irritable early)
- **Channel fit** — Is the chosen channel optimal for this person and topic?
- **Political context** — Should anyone else be consulted or CC'd first?

### Step 4: Propose Strategy

Present the user with:

**Recommended approach:**
- Tone (direct/indirect, formal/casual)
- Structure (lead with data? ask a question? frame as their idea?)
- Key phrases to use or avoid
- Timing recommendation

**Risks and mitigations:**
- What could go wrong
- How to handle likely pushback
- Fallback positions

### Step 5: Draft Message

Write 2-3 draft variations:

1. **Safe option** — Minimal risk, conventional approach
2. **Strategic option** — Optimized for the desired outcome based on profile analysis
3. **Direct option** — Straightforward, when the situation calls for it

For each draft, annotate WHY specific choices were made based on profile data. Example:
> "Leading with the data point because profile indicates this person responds better to numbers than narratives."

### Step 6: User Selects and Refines

Let the user pick a draft or mix elements. Refine until they're satisfied.

**Do NOT send the message.** The user decides when and whether to send. If asked to send, use the appropriate MCP tool (Slack, Gmail, etc.) only with explicit user confirmation.

## Handling Difficult Situations

For conflict, criticism, or high-stakes conversations:

- Reference contradictions.md if the person has a history of inconsistent statements
- Suggest de-escalation language when tension is detected
- Recommend involving allies (from relationship.md approach strategy)
- Propose waiting/cooling-off if the situation is heated

## Key Principles

- **Profile-informed, not profile-dependent** — Useful even without a profile, exceptional with one.
- **User has final say** — Never send without explicit confirmation. Proposals only.
- **Explain the reasoning** — Every suggestion should reference specific profile data so the user understands WHY.
- **Multiple options** — Always provide choices. Don't prescribe a single "right" answer.
- **Context-aware** — Consider the full situation: timing, channel, audience, political dynamics.
