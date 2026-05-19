---
name: nemawashi-issue
description: Use when the user wants to file a GitHub issue against this repo from free-form feedback or an idea surfaced in conversation — drafts a house-style body, surfaces duplicates, and files via gh after explicit confirmation.
---

# Issue Filer

Turn free-form feedback or design ideas into a properly-formatted GitHub issue conforming to this repo's house style (5-section spine: Context / Proposal / Acceptance / Out of scope / Relationship to other issues).

The skill never files an issue silently — it always previews the draft and asks for confirmation first.

## When to Use

- User says "this should be an issue" / "file that" / "issue にしといて" / "FB として残しといて".
- User describes a problem or improvement and you (the LLM) judge it is durable enough to capture as an issue rather than answer in conversation.

## Prerequisites

- `gh` CLI authenticated for this repo (`gh auth status`).
- Repo: defaults to `Kohei-Wada/supernemawashi`. Override with `--repo <owner>/<repo>` only if the user explicitly targets a different repo.

## Surface

```
nemawashi-issue <free-form text>            # most common
nemawashi-issue --type=feature <text>       # force the template
nemawashi-issue --repo=owner/repo <text>    # different repo (rare)
nemawashi-issue --dry-run <text>            # preview only, don't file
```

## Process

### Step 1: Pick the template

If `--type` is given, use it. Otherwise infer from the input text:

- "add a skill / feature / behavior" → `feature_request.md`
- "refactor / format contract / dependency bump / hygiene" → `chore.md`
- "X is broken / doesn't work / regression" → `bug_report.md`

State the chosen type explicitly to the user in Step 4 so they can override before confirming.

Read the template at `.github/ISSUE_TEMPLATE/<type>.md` to anchor the format. The frontmatter's `title:` prefix and `labels:` are the defaults; carry them through.

### Step 2: Search for duplicates

Run:

```bash
gh issue list --repo <repo> --state all --search "<key terms from input>" --limit 5 --json number,title,state
```

Pick 2–4 key noun phrases or skill names from the input as search terms. If results come back, show them to the user as a numbered list with `state` (OPEN/CLOSED) and `title`.

If a result is an obvious match, ask the user: "This looks like #NN — comment there instead, or file a new issue?" If they pick comment-on-existing, exit and tell them to run `gh issue comment <NN>` manually (commenting is out of scope for this skill).

### Step 3: Draft the body

Fill the template's 5 sections from the input:

- **Context** — the situation, motivation, surrounding history. If the input alludes to existing files, skills, or issues, name them explicitly and quote `#NN` references.
- **Proposal** — what's being proposed. Be concrete. If a feature, describe the surface (command, flags). If a chore, describe the change.
- **Acceptance** — concrete, verifiable criteria. Bullet list. "User can do X and observes Y."
- **Out of scope** — what this issue explicitly is NOT doing. Pull in any boundary the input drew.
- **Relationship to other issues** — link any `#NN` references and explain (depends on / supersedes / pairs with / touches).

If the input mentions known terms (e.g. "facts.jsonl format", "framework split", "temporal model"), auto-link the canonical issues you can verify exist via `gh issue list --search`. **Do NOT invent issue numbers** — verify each one before inserting it.

Pick a title following the template's prefix convention (`feat:`, `chore:`, `fix:`), under 70 chars.

### Step 4: Preview

Print to the user:

- Resolved `--type` and `--repo`.
- Title.
- Labels.
- Duplicate candidates surfaced in Step 2 (if any).
- Full body.

Ask: "create issue / edit draft / cancel".

### Step 5: File on confirmation

If `--dry-run`, stop after Step 4 and exit (no file is created).

Otherwise, on explicit confirmation, run:

```bash
gh issue create --repo <repo> --title "<title>" --body-file <body-tmpfile> --label "<label>"
```

Pass the body via a heredoc-written temp file (not `--body "..."`) to preserve markdown formatting. Strip the template's placeholder parenthetical hints from the final body — they should be replaced by real content, not shipped as-is.

Return the issue URL.

### Step 6: No further action

The skill does not:

- Auto-comment on related issues.
- Edit or close existing issues.
- Create PRs.
- Split one input into multiple issues — if the input is two ideas, say so and let the user re-invoke twice.

## Key Principles

- **Never file silently.** Preview and confirm are mandatory.
- **Verify every cross-reference.** Don't invent `#NN`. Use `gh issue list --search` to confirm before linking.
- **Template is the contract.** If you change the spine, edit `.github/ISSUE_TEMPLATE/*.md` first, then update this skill — not the other way around.
- **Minimal labels.** Default to what the template declares. Don't pile on `priority`, `milestone`, etc.

## Examples

User: "facts.jsonl の hot/cold split いるかも"
→ infer type=feature, search "facts.jsonl hot cold" / "facts.jsonl archive", surface #42 as the canonical issue if it's already filed, ask whether to comment there or file a new feature request.

User: "test-archive.sh の case 3 で .1, .2 でなく .a, .b にしたい"
→ infer type=chore, search "archive suffix" / "test-archive", draft a chore issue with Context describing the rationale.

User: "nemawashi-show が二人いるときどうするかわからん"
→ infer type=bug (or feature depending on framing), search "nemawashi-show ambiguous", draft accordingly.
