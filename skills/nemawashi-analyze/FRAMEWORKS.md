# Frameworks

Canonical registry of the psychological frameworks this plugin models. **This is the single source of truth for the set of framework slugs.** To add or rename one, edit this table and the matching definition file under `frameworks/<slug>.md`.

| Slug | Display name | Tier |
|------|--------------|------|
| `defense-mechanisms` | Defense Mechanisms | 1 |
| `thomas-kilmann-tki` | Conflict Mode (TKI) | 1 |
| `transactional-analysis-ta` | Ego States (TA) | 1 |
| `core-motivators` | Core Motivators | 1 |
| `cognitive-biases` | Cognitive Biases | 1 |
| `attachment-style` | Attachment Style | 2 |

- **Slug** matches the filename of the definition file (`frameworks/<slug>.md`), per-profile output files (`PROFILE_DIR/<name>/frameworks/<slug>.{md,jsonl}`), and the `framework` field inside each JSONL assertion.
- **Display name** matches the `output_label` frontmatter field in the definition file (rendered as the `# heading` of per-profile framework files and used as the row label in `profile.md`'s Framework Summary table).
- **Tier 1** = analyzed by default. **Tier 2** = analyzed only when signal density warrants it (a Data Gap classification is emitted otherwise).

For situation-to-framework loading priority used by `nemawashi-reply`, see [`skills/nemawashi-reply/SKILL.md`](../nemawashi-reply/SKILL.md) — that mapping intentionally lives next to the consumer because the priority is reply-specific, not a fact about the framework.

Drift between this registry and the actual `frameworks/<slug>.md` definitions is checked by [`scripts/check-frameworks.sh`](../../scripts/check-frameworks.sh).

## Adding a new framework

1. Add the row to the table above.
2. Create `frameworks/<slug>.md` following [`FRAMEWORK-CONTRACT.md`](FRAMEWORK-CONTRACT.md).
3. Update the situation→framework loading priority in `nemawashi-reply/SKILL.md` if applicable.
4. Run `scripts/check-frameworks.sh` — it confirms the registry and the definitions directory agree.
