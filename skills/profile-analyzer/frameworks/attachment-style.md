---
framework: Attachment Style
tier: 2
output_label: Attachment Style
---

# Attachment Style

## Purpose

Classifies a person's interpersonal attachment pattern, which affects how they handle trust, communication cadence, and emotional responsiveness. This is a Tier 2 framework — only analyze if 2+ relevant signals exist in the data.

## Classification Guidance

Scan facts.md entries for patterns in how the person handles interpersonal trust, responsiveness expectations, and communication frequency. Attachment style is harder to classify from workplace data alone, which is why it requires 2+ signals before classification. Look for consistent patterns across multiple interactions rather than isolated events.

## Reference Table

| Style | Observable Signals | DO | DON'T |
|---|---|---|---|
| Secure | Proportionate responses, comfortable with feedback | Communicate directly; give honest feedback | Over-explain or over-manage |
| Anxious | Follow-up messages, "did you see?", emotional escalation when ignored | Acknowledge receipt promptly; set clear timelines | Leave messages unread; give vague timelines |
| Avoidant | Short replies, infrequent check-ins, "I'll handle it" | Use async channels; respect autonomy; minimal meetings | Schedule unnecessary check-ins; require emotional debriefs |
| Disorganized | Contradictory messages, hot/cold, unpredictable reactions | Be consistent and predictable yourself; don't mirror their inconsistency | Assume today's behavior predicts tomorrow's |

## Rule Generation

**Attachment style → Adjust communication cadence.** Anxious? Acknowledge receipt promptly and set clear timelines. Avoidant? Respect async communication and don't over-check-in. For each classified style, generate DO rules that match their trust pattern and DON'T rules that violate it.

## Signal Tags

Format: `[attachment: <style>]`

Valid tags: `attachment:secure`, `attachment:anxious`, `attachment:avoidant`, `attachment:disorganized`
