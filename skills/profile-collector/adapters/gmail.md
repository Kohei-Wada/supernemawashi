---
adapter: gmail
output_tag: gmail
identifiers: [email, display_name]
---

# Adapter: Gmail

## Purpose
Captures email communication style: formality, decision-making style, response latency, and who the target involves in decisions (To/Cc patterns).

## MCP Tools Required
- `mcp__claude_ai_Gmail__search_threads` — find threads with the target
- `mcp__claude_ai_Gmail__get_thread` — read full thread content

If any of the above is unavailable, skip this adapter.

## Collection Recipe
1. Search recent threads to/from the target's email (`search_threads`), default window 30-90 days.
2. Sort by recency and thread length; pick the top 10-20 threads as a representative sample.
3. Read each thread (`get_thread`) to extract observable behaviors.

## Fact Extraction
Signals worth capturing:
- Formality level (greetings, sign-offs, sentence structure)
- Response latency
- Who they Cc (decision-makers vs. allies vs. broadcasts)
- Whether they reply inline, top-post, or summarize
- Length and structure of replies (one-liners vs. essays)
- Initiative pattern (do they start threads or only react?)

`facts.md` line format:

```
- [YYYY-MM-DD] [gmail] <observable behavior>
```

URLs are typically omitted for Gmail; reference the thread subject in the description when useful.

## Discovery Recipe
Used by profile-discovery to find unprofiled people the user interacts with.

1. Search threads in the scan window (default 14 days) — `search_threads` with date filter.
2. Sample recent threads (`get_thread`) and extract `From:` / `To:` / `Cc:` addresses with display names.
3. Exclude the user themselves and automated/system addresses (no-reply, notifications@, etc.).
4. Count thread participation per person.
5. Return a list of `{email, display_name, thread_count}` records.

## Pitfalls
- **Automated mail**: filter out newsletter / system / Calendar invite mail unless that is the signal you want.
- **Thread context**: reply tone often depends on the previous message. Read the full thread before judging tone.
- **Privacy**: only collect from threads the user is a participant in.
