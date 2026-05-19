# supernemawashi

Interpersonal communication strategy toolkit for engineers.

A Claude Code plugin that helps you navigate workplace dynamics by building psychological profiles of the people you work with and using that data to craft better communication.

## How It Works

1. **Collect** data about a colleague from Slack, Gmail, Calendar, and other MCP sources
2. **Analyze** their behavioral patterns using psychological frameworks (defense mechanisms, conflict styles, ego states, motivators, cognitive biases)
3. **Generate** evidence-based DO/DON'T communication rules indexed by situation
4. **Apply** those rules when crafting replies, proposals, or navigating difficult conversations

All profile data stays local on your machine. Nothing is sent externally.

## Installation

Inside Claude Code, run:

```
/plugin marketplace add Kohei-Wada/supernemawashi
/plugin install supernemawashi@supernemawashi
```

Then restart your Claude Code session.

### Verify Installation

In the new session, try:

```
"What skills does supernemawashi have?"
```

## The Basic Workflow

1. **Create a profile** — "Create a profile for John"
2. **Review collected data** — Claude gathers facts from your Slack, Gmail, and Calendar
3. **Analyze** — "Analyze John" — generates psychological profile with communication rules
4. **Use it** — "How should I reply to John about the deadline?" — gets profile-informed draft messages

## What's Inside

### Skills

All operational skills are verb-first under the `nemawashi-` prefix.

| Skill | What it does |
|-------|-------------|
| `nemawashi-collect` | Gathers data from MCP sources (Slack, Gmail, Calendar, GitHub, and any source you add via the [adapter pattern](skills/nemawashi-collect/ADAPTER-CONTRACT.md)) and writes structured profiles |
| `nemawashi-analyze` | Dispatches one agent per psychological framework in parallel and writes a per-framework analysis file plus a slim profile index |
| `nemawashi-show` | Read-only view of profiles — list all, show one person, drill into a single framework, or get the aggregated DO/DON'T rules by situation |
| `nemawashi-discover` | Scans every adapter-supported source to find people you interact with but haven't profiled yet |
| `nemawashi-check` | Dashboard showing which profiles are stale and need re-analysis |
| `nemawashi-note` | Append a single observation to a profile from an off-MCP interaction (1:1, phone, hallway) — the channel for everything adapters can't see |
| `nemawashi-reply` | Crafts 2-3 draft messages tailored to the recipient's psychological profile, loading only the framework files relevant to the current situation |
| `nemawashi-migrate` | Upgrades legacy profile data to the current on-disk format. Self-discovering registry — drop a `.sh`/`.md` pair under `skills/nemawashi-migrate/migrations/` to add a new migration |
| `nemawashi-issue` | Turns free-form feedback or design ideas into a properly-formatted GitHub issue conforming to this repo's house style — searches for duplicates, previews, and files via `gh` only after explicit confirmation |
| `using-supernemawashi` | Entry point — routes requests to the appropriate skill |

### Psychological Frameworks

The `nemawashi-analyze` skill uses these established frameworks to move beyond surface-level observations:

| Framework | What it reveals |
|-----------|----------------|
| Defense Mechanisms | How someone behaves when threatened (avoidance, rationalization, passive aggression, etc.) |
| Thomas-Kilmann Conflict Modes | Their conflict style — competing, collaborating, compromising, avoiding, or accommodating |
| Transactional Analysis | Which ego state they use with whom (Critical Parent to subordinates, Adapted Child to superiors, etc.) |
| Core Motivators (SDT + McClelland) | What drives them — safety, autonomy, competence, achievement, affiliation, or power |
| Cognitive Biases | Decision-making patterns — status quo bias, authority bias, IKEA effect, etc. |
| Attachment Style | Trust and delegation patterns — secure, anxious, avoidant, or disorganized |

Each classification produces concrete rules: "This person defaults to rationalization under criticism. DO: validate their reasoning first, then redirect. DON'T: argue against the justification directly." Each framework's classification, evidence, and rules live in their own file (`frameworks/<slug>.md`), so adding a new signal to one framework rewrites one file rather than a monolithic profile.

### Profile Data Structure

All data is stored locally at `~/.local/share/supernemawashi/profiles/<person-name>/`:

```
profile.md                       # Slim index: Basic Info + Core Pattern + Framework Summary table
relationship.md                  # Your relationship context and approach strategies
facts.jsonl                      # Chronological record of observed behaviors (canonical)
facts.md                         # Same record in legacy format (older profiles, dual-read during migration)
contradictions.md                # Detected inconsistencies (useful for difficult conversations)
frameworks/                      # One file per psychological framework
  defense-mechanisms.md          #   - Classification + Evidence + DO/DON'T rules per situation
  thomas-kilmann-tki.md          #   - (same structure)
  transactional-analysis-ta.md
  core-motivators.md
  cognitive-biases.md
  attachment-style.md
```

The split layout means consumers load only what the situation needs. `nemawashi-reply` for a conflict reads `profile.md` + `frameworks/thomas-kilmann-tki.md` + `frameworks/defense-mechanisms.md`, not every framework. `nemawashi-show <name> tki` opens just the TKI file. Cross-profile queries (e.g. "everyone competing under stress") grep one path per framework.

The canonical JSONL schema is at [`skills/nemawashi-collect/FACTS-SCHEMA.md`](skills/nemawashi-collect/FACTS-SCHEMA.md). Both `facts.jsonl` and `facts.md` are read if both exist; new profiles only have `facts.jsonl`.

### Upgrading between versions

`nemawashi-migrate` orchestrates on-disk format upgrades. Each migration is a `.sh` (`--detect`, lists eligible profiles) + `.md` (LLM apply contract) pair under `skills/nemawashi-migrate/migrations/`. The filename prefix encodes phase: `01-89` for forward migrations (produce or extend the canonical format), `90-99` for cleanup (delete redundant legacy artifacts). Run `/supernemawashi:nemawashi-migrate` to see pending migrations; pass `--apply-all` to chain rounds to completion.

## Philosophy

- **Evidence over intuition** — Every behavioral classification cites specific data. No speculation without evidence.
- **Actionable over academic** — Frameworks are included only if they produce concrete DO/DON'T rules.
- **Non-judgmental** — Describes behaviors and patterns, not character. "Defaults to avoidance under conflict" not "is a coward."
- **User in control** — Never sends messages without explicit confirmation. Proposals only.

## Requirements

- [Claude Code](https://claude.ai/code)
- MCP connections to your communication tools (Slack, Gmail, Calendar, etc.)

## Contributing

Issues and PRs welcome at [github.com/Kohei-Wada/supernemawashi](https://github.com/Kohei-Wada/supernemawashi).

### Optional: local denylist for internal identifiers

If you author skills or examples that touch on private context (your colleagues' names, internal project / customer / channel names, etc.), it is easy to slip one of those into an example block by accident. A pre-commit hook scans staged additions against a per-user denylist and blocks the commit on a match.

The denylist itself stays out of the repo — it lives at `.local/denylist.txt`, which is gitignored. To opt in:

```sh
mkdir -p .local
cat > .local/denylist.txt <<'EOF'
# One term per line. Blank lines and lines starting with # are ignored.
# Matching is case-insensitive.
acme-internal-project
my-colleague-last-name
EOF
```

With pre-commit installed (`pip install pre-commit && pre-commit install`), staging a `+` line that matches any term will fail the commit and print which terms matched. If the denylist file is absent the hook is a silent no-op, so contributors who haven't opted in are not blocked.

## License

MIT
