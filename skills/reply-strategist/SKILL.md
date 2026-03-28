---
name: reply-strategist
description: Use when user needs help replying to someone, crafting a message, or deciding what to say - references profiles from ~/.supernemawashi/profiles/ to tailor communication strategy
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

### Step 2: Load Profile

Read the recipient's profile from `~/.supernemawashi/profiles/<person-name>/`:
- `profile.md` — Behavioral patterns and communication strategy
- `relationship.md` — User's relationship and approach strategy
- `facts.md` — Recent interactions (for context continuity)
- `contradictions.md` — Known contradictions (useful for difficult conversations)

**If no profile exists:** Tell the user and offer two options:
1. Run profile-collector first for a data-informed reply
2. Proceed without a profile (generic advice only)

**If profile is stale** (last_updated > 30 days): Suggest updating, but proceed with existing data if user wants a quick reply.

### Step 3: Analyze the Situation

Based on profile data, assess:
- **Recipient's likely reaction** — Given their behavioral patterns, how will they probably respond to this topic?
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
