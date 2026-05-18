---
framework: Cognitive Biases
tier: 1
output_label: Cognitive Biases
---

# Cognitive Biases (Workplace Subset)

## Purpose

Identifies which cognitive biases consistently appear in a person's decision-making. Understanding these biases allows you to frame proposals and information in ways that work with (rather than against) their natural decision patterns.

## Classification Guidance

Scan facts.md entries for decision-making patterns that match the biases in the Reference Table. Focus on recurring patterns rather than one-off instances. A person typically has 2-3 dominant biases. Look for biases that appear across different types of decisions (technical, organizational, interpersonal) as these are the most stable and actionable.

## Reference Table

| Bias | Observable Signals | Framing Strategy |
|---|---|---|
| Status Quo | "We've always done it this way", resists change proposals | Frame changes as extensions of current approach, not replacements |
| Anchoring | First number/option dominates their response | Strategically choose your opening number/proposal |
| Confirmation | Only engages with evidence supporting their position | Present idea as consistent with their existing beliefs |
| Sunk Cost | Refuses to abandon failing projects they invested in | Acknowledge investment before proposing alternatives |
| Authority | Defers to seniority over evidence | Get senior stakeholder buy-in first |
| Negativity | Focuses on risks and problems over opportunities | Lead with risk mitigation, not opportunity |
| IKEA Effect | Overvalues ideas they contributed to | Involve them in creating the solution |
| Loss Aversion | Reacts more strongly to losses than equivalent gains | Frame as "what we lose by not doing this" rather than "what we gain" |

## Rule Generation

**Cognitive biases → Frame to work with the bias.** Status quo bias? Present change as an extension of what exists. IKEA effect? Involve them in creating the solution. For each classified bias, generate DO rules that leverage the bias constructively and DON'T rules that fight against it.

## Signal Tags

Format: `[bias: <type>]`

Valid tags: `bias:status-quo`, `bias:anchoring`, `bias:confirmation`, `bias:sunk-cost`, `bias:authority`, `bias:negativity`, `bias:ikea-effect`, `bias:loss-aversion`
