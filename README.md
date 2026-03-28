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

```bash
claude plugins marketplace add /path/to/supernemawashi
claude plugins install supernemawashi
```

### Verify Installation

After installing, start a new Claude Code session. You should see the supernemawashi skills available. Try:

```
"What skills does supernemawashi have?"
```

## The Basic Workflow

1. **Create a profile** — "Create a profile for Alice"
2. **Review collected data** — Claude gathers facts from your Slack, Gmail, and Calendar
3. **Analyze** — "Analyze Alice" — generates psychological profile with communication rules
4. **Use it** — "How should I reply to Alice about the deadline?" — gets profile-informed draft messages

## What's Inside

### Skills

| Skill | What it does |
|-------|-------------|
| `profile-collector` | Gathers data from MCP sources (Slack, Gmail, Calendar, GitHub) and writes structured profiles |
| `profile-analyzer` | Classifies behavioral patterns using 6 psychological frameworks and generates situation-indexed DO/DON'T rules |
| `reply-strategist` | Crafts 2-3 draft messages tailored to the recipient's psychological profile |
| `using-supernemawashi` | Entry point — routes requests to the appropriate skill |

### Psychological Frameworks

The `profile-analyzer` uses these established frameworks to move beyond surface-level observations:

| Framework | What it reveals |
|-----------|----------------|
| Defense Mechanisms | How someone behaves when threatened (avoidance, rationalization, passive aggression, etc.) |
| Thomas-Kilmann Conflict Modes | Their conflict style — competing, collaborating, compromising, avoiding, or accommodating |
| Transactional Analysis | Which ego state they use with whom (Critical Parent to subordinates, Adapted Child to superiors, etc.) |
| Core Motivators (SDT + McClelland) | What drives them — safety, autonomy, competence, achievement, affiliation, or power |
| Cognitive Biases | Decision-making patterns — status quo bias, authority bias, IKEA effect, etc. |
| Attachment Style | Trust and delegation patterns — secure, anxious, avoidant, or disorganized |

Each classification produces concrete rules: "This person defaults to rationalization under criticism. DO: validate their reasoning first, then redirect. DON'T: argue against the justification directly."

### Profile Data Structure

All data is stored locally at `~/.local/share/supernemawashi/profiles/<person-name>/`:

```
profile.md          # Basic info + psychological analysis + communication strategy
relationship.md     # Your relationship context and approach strategies
facts.md            # Chronological record of observed behaviors with sources
contradictions.md   # Detected inconsistencies (useful for difficult conversations)
```

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

## License

MIT
