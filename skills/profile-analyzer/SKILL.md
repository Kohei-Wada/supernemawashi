---
name: profile-analyzer
description: Use when user wants to analyze a person's behavioral patterns - reads profile data from ~/.supernemawashi/profiles/ and adds behavioral analysis
---

# Profile Analyzer

Analyze a person's collected profile data and identify behavioral patterns, communication tendencies, and effective strategies for interacting with them.

## When to Use

- User says "analyze X" or "what kind of person is X?"
- After profile-collector finishes (suggest this automatically)
- User wants to update analysis with new data

## Prerequisites

A profile must exist at `~/.supernemawashi/profiles/<person-name>/profile.md`. If it doesn't, tell the user to run profile-collector first.

## Process

### Step 1: Read All Profile Data

Read the following files for the target person:
- `~/.supernemawashi/profiles/<person-name>/profile.md`
- `~/.supernemawashi/profiles/<person-name>/facts.md` (if exists)
- `~/.supernemawashi/profiles/<person-name>/relationship.md` (if exists)

### Step 2: Level A Analysis — Fact-Based Summary

Summarize observable facts from the data:
- Communication frequency and preferred channels
- Response time patterns (fast/slow, time-of-day variation)
- Meeting behavior (punctual, cancels often, etc.)
- Topics they engage with vs. ignore

Update the "Communication Patterns" section of profile.md with findings.

### Step 3: Level B Analysis — Behavioral Patterns

Identify behavioral tendencies by looking across all collected data:

**Decision-making style:**
- Decisive vs. avoidant
- Data-driven vs. intuition-based
- Independent vs. consensus-seeking

**Communication tendencies:**
- Starts with rejection/criticism vs. supportive
- Direct vs. indirect
- Detailed vs. high-level

**Conflict behavior:**
- Confrontational vs. avoidant
- Blames others vs. takes responsibility
- Holds grudges vs. moves on

**Reliability patterns:**
- Follows through on commitments vs. forgets
- Consistent messaging vs. contradicts self
- Transparent vs. political

Write findings to the "Behavioral Patterns (Level B)" section of profile.md. Each pattern must cite specific evidence from facts.md.

### Step 4: Generate Communication Strategy

Based on Level A + B analysis, write actionable strategies to the "Communication Strategy" section of profile.md:

- Best channel and timing for communication
- How to frame proposals (data-first? story-first? ask for their opinion?)
- What to avoid (triggers, bad timing, sensitive topics)
- Who to involve or consult before approaching this person

Also update relationship.md "Approach Strategy" section if it exists.

### Step 5: Report to User

Present a summary of the analysis:
- Key behavioral patterns identified (with evidence)
- Recommended communication strategies
- Any gaps in data that more collection could fill

## Key Principles

- **Evidence-based** — Every behavioral pattern must cite specific data points. No speculation without evidence.
- **Non-judgmental framing** — Describe behaviors, not character. "Tends to start with rejection" not "is a negative person."
- **Actionable output** — Every pattern identified should lead to a concrete strategy.
- **Update, don't overwrite** — When re-analyzing, preserve manually added notes. Only update auto-generated sections.
