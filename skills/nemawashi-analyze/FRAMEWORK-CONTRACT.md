# Framework File Contract

Each `*.md` file in the `frameworks/` directory defines one psychological framework. To add a new framework, create a file following this template:

```markdown
---
framework: [Name]
tier: 1 or 2
output_label: [Label for Framework Classifications table]
---

# [Name]

## Purpose
[1-2 sentences: what this framework measures and why it matters for communication strategy]

## Classification Guidance
[How to aggregate signals into a classification for this framework]

## Reference Table
[Lookup table with types, observable signals, and DO/DON'T actions]

## Rule Generation
[Principle for deriving DO/DON'T rules from this framework's classifications]

## Signal Tags
[Tag format and enumerated list of valid tags]
```

**Required fields:** All sections above are mandatory. `tier: 1` frameworks are always analyzed. `tier: 2` frameworks are analyzed only when 2+ relevant signals exist. The `output_label` value appears in the Framework Classifications table in profile.md.
