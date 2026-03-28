# supernemawashi

Interpersonal communication strategy toolkit for engineers.

A Claude Code plugin that helps you navigate workplace dynamics by building profiles of the people you work with and using that data to craft better communication.

## Features

- **Profile Collection** — Automatically gather data about colleagues from Slack, Gmail, Calendar, and other MCP-connected sources
- **Behavioral Analysis** — Identify communication patterns, decision-making styles, and behavioral tendencies
- **Reply Strategy** — Get profile-informed suggestions for how to reply to someone or bring up a topic

## Install

```bash
claude plugins marketplace add /path/to/supernemawashi
claude plugins install supernemawashi
```

## Usage

### Create a profile

Ask Claude to collect data about someone:

```
"Create a profile for Alice Smith"
"Collect info about my manager"
```

This runs the `profile-collector` skill, which gathers data from your connected MCP sources (Slack, Gmail, Calendar, GitHub) and saves it to `~/.supernemawashi/profiles/<person-name>/`.

### Analyze behavioral patterns

Once a profile exists, ask Claude to analyze it:

```
"Analyze Alice Smith"
"What kind of person is my manager?"
```

The `profile-analyzer` skill identifies communication tendencies, decision-making style, and generates actionable strategies.

### Get reply help

When you need to respond to someone:

```
"How should I reply to Taro about the API redesign?"
"What's the best way to bring up the deadline with my manager?"
```

The `reply-strategist` skill loads the recipient's profile and proposes 2-3 draft messages tailored to their behavioral patterns.

### Profile data

All profile data is stored locally at `~/.supernemawashi/` and is never committed to git.

```
~/.supernemawashi/profiles/<person-name>/
├── profile.md          # Objective data and behavioral analysis
├── relationship.md     # Your relationship and approach strategies
├── facts.md            # Chronological record of statements
└── contradictions.md   # Detected contradictions
```

## Requirements

- [Claude Code](https://claude.ai/code)
- MCP connections to your communication tools (Slack, Gmail, etc.)
