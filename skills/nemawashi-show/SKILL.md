---
name: nemawashi-show
description: Use when user wants to view, show, list, or display profile data for one or more people - read-only display of profiles stored in PROFILE_DIR
---

# Profile Viewer

Display profile data so the user can quickly review what's been collected and analyzed about a person, or see who has been profiled.

## When to Use

- User says "show profile for X", "view X's profile", "Xを見せて", "Xのprofile"
- User says "list profiles", "who do I have profiles for?", "profile一覧", "誰のprofileある?"
- User wants a specific section: "X's DO/DON'T", "Xのfacts", "Xの矛盾", "X's contradictions"
- User wants to spot-check after running `nemawashi-collect` or `nemawashi-analyze`

**Not for:**
- Editing → `nemawashi-collect` (creates/updates raw data) or `nemawashi-analyze` (regenerates analysis)
- Staleness triage → `nemawashi-check`
- Crafting replies → `nemawashi-reply`

## Process

### Step 1: Parse the Request

Determine the operation from the user's phrasing:

| Operation | Trigger | Target |
|-----------|---------|--------|
| **List** | no name, or "list" / "一覧" / "誰がいる" | all profiles |
| **Person** | name only, or "show X" / "X見せて" | full profile for one person |
| **Section** | name + section keyword | one section for one person |

Section keywords (case-insensitive):

| Keyword | File / Section |
|---------|----------------|
| `profile` / no keyword | `profile.md` (default) |
| `relationship` / `関係` | `relationship.md` |
| `facts` / `事実` | `facts.md` |
| `contradictions` / `矛盾` | `contradictions.md` |
| `do/don't` / `strategy` / `戦略` | `## Communication Strategy` section of `profile.md` |
| `basic` / `info` | `## Basic Info` section of `profile.md` |
| `communication` / `話し方` | `## Communication Patterns` section of `profile.md` |
| `work` / `仕事` | `## Work Patterns` section of `profile.md` |
| `behavioral` / `frameworks` / `分析` | `## Behavioral Patterns` section of `profile.md` |

### Step 2: Resolve the Person (when applicable)

1. List directories in `PROFILE_DIR/` (ignore `README.md` and any non-directory entries).
2. **Exact match** (case-insensitive) → use it.
3. **Prefix match** → use it.
4. **Substring match** → if exactly one, use it. If multiple, list candidates and ask which.
5. **No match** → report "No profile for '<name>'. Did you mean: <closest>?" or suggest running `nemawashi-collect` if there are no close matches.

### Step 3: Execute

#### List operation

1. For each directory in `PROFILE_DIR/`:
   - Read frontmatter from `profile.md` (`name`, `role`, `last_updated`).
   - Read the `<!-- analyzed: YYYY-MM-DD, facts_count: N -->` comment if present.
   - Count lines in `facts.md` matching `- [YYYY-MM-DD]` for current fact count.
   - Note presence of `contradictions.md` and whether it has content beyond the header.
2. Display as a table:

```markdown
| Person | Role | Last Analyzed | Facts | Contradictions |
|--------|------|---------------|-------|----------------|
| alice | Acme Corp Eng | 2026-05-16 | 47 | 12 |
| bob | (n/a) | never | 23 | — |
```

3. After the table, list short hints:
   > Use `show <name>` to view a full profile, or `<name> facts` / `<name> DO/DON'T` for sections.

#### Person operation

1. Read `profile.md` and render it as-is. Do NOT summarize or paraphrase — the user wants to see the actual content.
2. After `profile.md`, append a short footer:
   > Also available: `<name> relationship`, `<name> facts`, `<name> contradictions`.
3. If `profile.md` is missing but `facts.md` exists, render `facts.md` and note "No analyzed profile yet — run `nemawashi-analyze` for <name>."

#### Section operation

1. If the section maps to a file (`relationship.md` / `facts.md` / `contradictions.md`): render the whole file.
2. If the section maps to a `## <heading>` inside `profile.md`: extract lines from that `## <heading>` up to (but not including) the next `## ` heading. Render that block.
3. If the section doesn't exist in the file: report "Section '<name>' not found in <person>'s profile."

### Step 4: Handle Empty / Missing States

- **No profiles at all**: "No profiles found in `PROFILE_DIR/`. Run `nemawashi-collect` or `nemawashi-discover` to start."
- **Profile dir exists but is empty**: same as above for that person.
- **`facts.md` is missing**: facts count = 0.
- **`contradictions.md` has only a header (no entries)**: report "—" in the list view; in section view, render it as-is so the user sees it's empty.

## Output Style

- **Render markdown as-is.** Profiles are written in markdown — display them directly so the user sees the source.
- **No paraphrasing or summarization.** This skill is a read tool, not an analysis tool. If the user wants analysis, route them to `nemawashi-analyze`.
- **Quote the path** at the top so the user can `vim` it if they want to edit:
  ```
  📄 ~/.local/share/supernemawashi/profiles/alice/profile.md
  ```
- **Keep footer hints short.** One line max.

## Edge Cases

- Profile name contains spaces or non-ASCII: use exact-match path resolution; do not URL-encode.
- User asks for a profile that exists but `profile.md` is missing (only `facts.md`): render `facts.md` and suggest running `nemawashi-analyze`.
- User asks for a section that doesn't exist (e.g., `alice strategy` when there's no Communication Strategy yet): report missing and suggest running `nemawashi-analyze`.
- Ambiguous fuzzy match: list candidates and ask. Do not guess.

## Key Principles

- **Read-only.** Never write or modify profile files. If the user wants to change something, route them to the appropriate skill.
- **No interpretation.** Show the data as written. The user is the analyst here — they want to see their own notes, not your summary of them.
- **Fast.** A "view" operation should resolve in one tool call (or two: list dirs, read file). Don't over-engineer.
