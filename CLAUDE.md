# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

supernemawashi is an interpersonal communication strategy toolkit for engineers, implemented as a Claude Code skill library (plugin). It helps users navigate workplace dynamics by collecting and analyzing psychological profiles of colleagues, crafting strategic replies, and preparing for meetings.

## Architecture

- **Plugin type**: Claude Code skill library (same pattern as [superpowers](https://github.com/obra/superpowers))
- **Skills**: Markdown files in `skills/<skill-name>/SKILL.md` with YAML frontmatter
- **Hooks**: Session-start hook injects `using-supernemawashi` skill into every session
- **Profile data**: Stored locally in `~/.local/share/supernemawashi/` (not in this repo)

## Skills

| Skill | Purpose |
|-------|---------|
| using-supernemawashi | Entry point — routes requests to appropriate skills |
| nemawashi-collect | Collects data from MCP sources, creates/updates profiles |
| nemawashi-analyze | Classifies behavioral patterns using psychological frameworks (defense mechanisms, TKI, TA, motivators, cognitive biases, attachment) and generates situation-indexed DO/DON'T rules |
| nemawashi-show | Read-only display of existing profiles — list all, show one person, or show a specific section |
| nemawashi-discover | Scans Slack channels and Gmail for people the user interacts with but hasn't profiled yet |
| nemawashi-check | Checks analysis staleness across all profiles and triages which need re-analysis |
| nemawashi-reply | Crafts profile-aware reply strategies and message drafts, maps user context to situation categories |

All non-entry skills are verb-first under the `nemawashi-` prefix.

## Key Conventions

- Skill frontmatter `description` field defines trigger conditions, not a summary
- Profile data is NEVER committed to git — it lives in `~/.local/share/supernemawashi/`
- Skills use MCP tools (Slack, Gmail, Calendar, GitHub, plus any source registered as an adapter — see `skills/nemawashi-collect/ADAPTER-CONTRACT.md`) but never send messages without explicit user confirmation
- Each skill is self-contained: process in `SKILL.md`, supporting docs (e.g., `OUTPUT-FORMAT.md`, `FRAMEWORK-CONTRACT.md`, `ADAPTER-CONTRACT.md`) alongside it
- MCP source recipes live in `skills/nemawashi-collect/adapters/<name>.md` and are consumed by both `nemawashi-collect` (Collection Recipe) and `nemawashi-discover` (Discovery Recipe)
- All documentation and skill files are written in English
- Use fictional names (e.g., "John", "Alice") in README and public-facing examples — never use real people's names
