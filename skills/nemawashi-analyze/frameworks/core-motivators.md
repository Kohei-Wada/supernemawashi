---
framework: Core Motivators
tier: 1
output_label: Core Motivators
---

# Core Motivators (SDT + McClelland)

## Purpose

Identifies the underlying psychological needs that drive a person's behavior, drawing from Self-Determination Theory (SDT) and McClelland's Need Theory. Understanding their core motivators allows you to frame proposals and requests in terms that resonate with what they care about most.

## Classification Guidance

Scan facts.md entries for behavioral signals that indicate unmet or pursued needs. A person typically has 1-2 dominant motivators. Look for patterns across multiple situations rather than one-off behaviors. SDT motivators (safety, autonomy, competence, relatedness) tend to be more stable; McClelland motivators (achievement, affiliation, power) may be more context-dependent.

## Reference Table

| Motivator | Source | Observable Signals | Framing Strategy |
|---|---|---|---|
| Safety / Predictability | SDT | Resists change, seeks certainty, avoids risk | Lead with risk mitigation; emphasize stability |
| Autonomy | SDT | "I'd prefer my way", resists process mandates | Specify outcome, let them choose the path |
| Competence | SDT | Volunteers for expertise areas, avoids unfamiliar domains | Acknowledge expertise; provide clear specs for new areas |
| Relatedness | SDT | Social messages, team-building, personal questions | Build personal rapport before business asks |
| Achievement | McClelland | Tracks progress, references KPIs, competitive with self | Include metrics, timelines, visible success criteria |
| Affiliation | McClelland | Consensus-building, discomfort with disagreement | Frame as team benefit; avoid zero-sum framing |
| Power | McClelland | Directs others, frames ideas as impact/influence | Frame proposal as expanding their influence |

## Rule Generation

**Core motivators → Frame proposals to satisfy their need.** Safety-motivated person? Lead with risk mitigation. Power-motivated? Frame as expanding their influence. For each classified motivator, generate DO rules that frame actions in terms of the motivator and DON'T rules that threaten or ignore the underlying need.

## Signal Tags

Format: `[motivator: <type>]`

Valid tags: `motivator:safety`, `motivator:autonomy`, `motivator:competence`, `motivator:relatedness`, `motivator:achievement`, `motivator:affiliation`, `motivator:power`
