# Identity Cache

A small file holding the user's own identifiers across every MCP source they use. Resolved once, reused by every collect / discover subagent so the same MCP calls don't run N times.

## Location

```
${PROFILE_DIR}/.identity.md
```

Lives next to the profile directories rather than inside any one, because identity is cohort-level data (it's about the user, not about a profiled person). The dot-prefix keeps it out of `ls` listings and outside the `*/` glob that `nemawashi-show` uses to enumerate profiles.

## Schema

```markdown
---
last_resolved: YYYY-MM-DD
sources: [list of adapter slugs the identity covers]
---

# User Identity Cache

This file is auto-managed. Edit only via `nemawashi-discover --refresh-identity` or by deleting the file (next run will re-resolve).

## slack
- handle: <handle>
- user_id: <U…>
- display_name: <name>
- email: <email>

## gmail
- primary_email: <email>
- work_email: <email>
- display_name: <name>

## calendar
- primary_calendar_id: <id>
- timezone: <tz>

## github
- login: <login>
- email: <email>

# (One section per adapter that publishes Identity Tags — see ADAPTER-CONTRACT.md.)
```

Adapters that don't have user-identity-relevant identifiers (e.g. an adapter that reads anonymous logs) simply don't contribute a section.

## Lifecycle

| Event | Action |
|---|---|
| File missing | Resolve from MCP sources, write atomically (temp + mv). |
| `last_resolved` is today's date | Reuse verbatim; no MCP calls. |
| `last_resolved` is older than today AND user invoked `--refresh-identity` | Re-resolve, overwrite. |
| `last_resolved` is older than today AND user did NOT request refresh | Reuse. Stale identity is acceptable; identities rarely change day-to-day. |
| Adapter reports its resolved value differs from cache | Surface the mismatch, prompt user, refresh only if confirmed. |

The "stale identity is acceptable" rule is deliberate. Identities (handles, emails, github logins) change on the order of months or years, not days. Daily auto-refresh would defeat the cache's purpose.

## Resolution

When the cache is being built (first run or `--refresh-identity`):

1. For each adapter under `adapters/*.md`, read its **Identity Resolution** section if present (see ADAPTER-CONTRACT.md). This section names which MCP calls to make and which fields to record.
2. Run those calls. Each adapter returns a key/value map for its section in the cache.
3. Write the result atomically to `${PROFILE_DIR}/.identity.md`.

Adapters without an explicit Identity Resolution section contribute nothing — they don't need the user's identifiers to function (or they look them up inline at use-time, which is fine for low-frequency calls).

## Consumption — subagent dispatch

When the parent skill (collect / discover) dispatches N subagents in parallel, it reads `.identity.md` **once** in the parent session and inlines the resolved identity in each subagent's prompt:

```
## User identity (resolved by parent — do NOT re-resolve)
- Slack: handle=<...>, user_id=<...>, email=<...>
- Gmail: primary_email=<...>, work_email=<...>
- Calendar: primary_calendar_id=<...>, timezone=<...>
- GitHub: login=<...>

Use these values verbatim wherever a recipe says "the user's <handle/email/login>".
Do NOT call MCP tools to resolve any of the above.
```

Subagents that follow this contract perform zero identity-resolution MCP calls. With N parallel subagents, the savings are N-fold.

## Direct invocation

When the user invokes `nemawashi-collect` or `nemawashi-discover` directly in the main session (no subagent dispatch), the skill still consults `.identity.md` first and only resolves on miss. The performance win is smaller (no parallel N) but the code path is unified — same behavior, same cache.
