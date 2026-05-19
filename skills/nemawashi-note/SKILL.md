---
name: nemawashi-note
description: Use when the user wants to manually add a single observation about a profiled person — typically something that happened off-MCP (in-person conversation, phone call, hallway exchange, lunch comment) that the collect adapters can't see. Appends one fact entry to `facts.jsonl` with `source: manual`.
---

# Manual Fact Entry

Append a single observed-behavior fact to a profile's `facts.jsonl`. All other facts come from MCP adapters (Slack, Gmail, Calendar, GitHub) — this skill is the channel for everything else: 1:1s, phone calls, hallway remarks, lunch comments, on-site visits. Off-MCP signal is often the most diagnostic, so this skill closes the loop with minimal friction.

> **Note on format:** the original feature request (issue #8) described appending to `facts.md` in the legacy bullet format. The JSONL migration happened after the issue was filed; `FACTS-SCHEMA.md` is now canonical and explicitly lists `"source":"manual"` as valid. This skill writes JSONL accordingly; legacy `facts.md` is never modified.

## When to Use

- User says "note that <name> said/did X"
- User says "メモっといて <name> が…"
- User had a 1:1, hallway chat, lunch, phone call and wants to capture an observation
- User wants to backdate a fact (`--date YYYY-MM-DD`)

**Not for:**
- Bulk fact import from MCP → `nemawashi-collect`
- Editing existing facts → open `facts.jsonl` directly
- Writing a journal entry / commentary → those belong in the user's own notes, not the profile

## Invocation

```
nemawashi-note <name> "<observable behavior>"
nemawashi-note <name> "<observable behavior>" --date 2026-05-18
```

Or natural language: "Note that alice said in our 1:1 she wants to move teams."

## Process

### Step 1: Parse the input

Extract:
- `name` — the target person (directory name in `PROFILE_DIR/`)
- `content` — the observation, one observable behavior. Plain string, will be JSON-encoded.
- `date` — optional, default today (YYYY-MM-DD).

If the input is natural language ("note that alice said …"), extract name from the user's phrasing and quote the rest as content. Confirm both before writing if there's any ambiguity.

### Step 2: Resolve the target

Same direct-read-first protocol as `nemawashi-show`:

1. **Direct read** — attempt to read `PROFILE_DIR/<name>/profile.md` to confirm the profile exists. If it does, proceed in **one tool call**.
2. **On miss**, fall back to fuzzy resolution (exact → prefix → substring match against directories in `PROFILE_DIR/`). On ambiguous match, ask the user.
3. **No match** — report "No profile for '<name>'. Run `nemawashi-collect <name>` first, or did you mean: <closest>?"

### Step 3: Build the JSONL record

```json
{"date":"<YYYY-MM-DD>","source":"manual","content":"<content>"}
```

- Use a JSON encoder (jq, Python, etc.) to handle escapes in `content` correctly. Do not hand-build JSON strings — quotes, backslashes, and newlines must round-trip cleanly.
- `source` is always `"manual"` for this skill.
- No other fields by default. (The user can edit `facts.jsonl` directly to add `channel`, `participants`, etc. if they want richer structure.)

### Step 4: Append atomically

The append must not corrupt `facts.jsonl` on a crash, and must preserve trailing-newline conventions.

Recipe:

1. Read the existing `facts.jsonl` (if it exists) into a variable.
2. Build the new content: existing content + one JSONL line (with trailing newline).
3. Write to a temp file in the same directory.
4. `mv` the temp file over `facts.jsonl`.

If `facts.jsonl` does not yet exist (e.g. a brand-new profile that has only `profile.md`), create it with just the one record.

### Step 5: Confirm to the user

Report:

```
📄 ~/.local/share/supernemawashi/profiles/<name>/facts.jsonl
+ {"date":"2026-05-19","source":"manual","content":"在宅勤務希望と昼休みに漏らした"}

Tip: run `nemawashi-analyze <name>` to fold this fact into the framework analysis.
```

Always show the resolved path so the user can `vim` it if they need to correct anything.

## Edge Cases

- **Profile doesn't exist**: don't auto-create. Tell the user to run `nemawashi-collect <name>` first. Manual notes without an existing profile have no anchor.
- **Empty content** (just whitespace): refuse and ask for the observation.
- **Future date**: warn the user once but allow it (sometimes you note a planned commitment); don't block.
- **Content contains the person's name in third person**: leave it as-is. The user wrote what they wrote.
- **`facts.md` legacy file is present** (mid-migration profile): always write to `facts.jsonl`, never modify `facts.md`. Consumers read both during the dual-read transition.

## Output Style

- One confirmation block per append. No commentary.
- Quote the path so the user can edit it.
- Suggest `nemawashi-analyze` once at the end. Do not nag.

## Key Principles

- **One observation per call.** This skill writes exactly one record. Bulk import is `nemawashi-collect`'s job.
- **Observable behavior, not interpretation.** "Said he wants to move teams" — yes. "Seems frustrated with management" — only if backed by a quote or specific behavior.
- **Atomic append.** Temp file + `mv`. A crash mid-append leaves the prior `facts.jsonl` intact.
- **The user is the source.** `source: manual` is not less valuable than `slack` or `gmail` — it's the signal MCP cannot see.

## Out of Scope

- Re-running `nemawashi-analyze` automatically after each note (issue mentions `--analyze` as future). Keep this skill single-purpose; the user explicitly calls analyze when they want to refresh.
- Multi-line entry via `$EDITOR` (also future v2). One-shot text is enough for the common case.
- Editing or deleting facts. That's an out-of-skill operation (open the jsonl, edit).
