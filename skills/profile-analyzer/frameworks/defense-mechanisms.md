---
framework: Defense Mechanisms
tier: 1
output_label: Defense Mechanisms
---

# Defense Mechanisms

## Purpose

Identifies which defense/coping mechanisms a person defaults to under stress or threat. Understanding these patterns allows you to route around triggers and avoid escalating defensive behavior.

## Classification Guidance

Scan facts.md entries for observable signals listed in the Reference Table. Tag each matching behavior. The dominant mechanism is the one with the most signals. If multiple mechanisms appear with similar frequency, list all dominant ones. Track whether different mechanisms activate in different contexts (e.g., avoidance with peers, displacement with subordinates).

## Reference Table

| Mechanism | Definition | Observable Signals | DO | DON'T |
|---|---|---|---|---|
| Avoidance | Evading threatening topics or decisions | Non-response, topic change, delayed reply on contentious topics only | Lower the stakes; break into small asks | Chase in the avoided channel; send long messages |
| Passive Aggression | Indirect resistance while appearing compliant | "Sure, I'll do it" + no action; backhanded compliments; strategic delays | Name the specific behavior neutrally | Call out "you're being passive-aggressive" |
| Rationalization | Post-hoc justification to protect self-image | Long explanations for failures; "because..." chains | Validate reasoning, then redirect to future | Argue against the justification directly |
| Projection | Attributing own behavior to others | Accusing others of their own patterns | Address the projected behavior factually | Mirror the accusation back |
| Displacement | Redirecting frustration to safe targets | Harsh to juniors after pressure from above | Don't engage when freshly stressed; revisit later | Confront during displacement episode |
| Info Withholding | Keeping information as leverage or defense | Reveals info only after others commit | Present all your info first; leave no gaps | Share info incrementally (invites reciprocal withholding) |
| Venting | Extended emotional discharge | Long emotional messages, escalation | Let them finish before problem-solving | Jump to solutions mid-vent |
| Rumination | Returning to past grievances repeatedly | Repeated references to old incidents | Acknowledge the past issue proactively | Dismiss or minimize the old incident |
| Suppression | Flat affect masking emotional accumulation | Minimal emotional expression, then eventual explosion | Check in periodically; don't assume calm = fine | Pile on requests assuming they're handling it |

## Rule Generation

**Defense mechanisms → Avoid triggers.** Identify what activates the defense, and route around it. For each classified mechanism, generate DO rules that circumvent the trigger and DON'T rules that name the trigger to avoid.

## Signal Tags

Format: `[defense: <mechanism>]`

Valid tags: `defense:avoidance`, `defense:passive-aggression`, `defense:rationalization`, `defense:projection`, `defense:displacement`, `defense:info-withholding`, `defense:venting`, `defense:rumination`, `defense:suppression`
