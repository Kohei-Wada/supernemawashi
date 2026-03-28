# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

supernemawashi is an interpersonal communication strategy toolkit for engineers, implemented as a Claude Code skill library (plugin). It helps users navigate workplace dynamics by collecting and analyzing profiles of colleagues, crafting strategic replies, and preparing for meetings.

## Architecture

- **Plugin type**: Claude Code skill library (same pattern as [superpowers](https://github.com/obra/superpowers))
- **Skills**: Markdown files in `skills/<skill-name>/SKILL.md` with YAML frontmatter
- **Hooks**: Session-start hook injects `using-supernemawashi` skill into every session
- **Profile data**: Stored locally in `~/.supernemawashi/` (not in this repo)

## Skills

| Skill | Purpose |
|-------|---------|
| using-supernemawashi | Entry point — routes requests to appropriate skills |
| profile-collector | Collects data from MCP sources, creates/updates profiles |
| profile-analyzer | Analyzes behavioral patterns from collected data |
| reply-strategist | Crafts profile-aware reply strategies and message drafts |

## Key Conventions

- Skill frontmatter `description` field defines trigger conditions, not a summary
- Profile data is NEVER committed to git — it lives in `~/.supernemawashi/`
- Skills use MCP tools (Slack, Gmail, Calendar, GitHub) but never send messages without explicit user confirmation
- Design specs go in `docs/supernemawashi/specs/`, plans in `docs/supernemawashi/plans/`
