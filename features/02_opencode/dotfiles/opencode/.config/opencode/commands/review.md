---
description: Review the current diff with reviewer and adversarial-reviewer in parallel, then merge the findings.
agent: lead
---
Run a two-lens review of the current change.

1. Get the artifact: `git diff` for the working tree, or `git diff <base>...HEAD`
   when a branch base is obvious.
2. Launch @reviewer and @adversarial-reviewer in parallel with the same brief:
   the diff, the stated intent, and the paths touched. Do not send one agent a
   summary of the other.
3. Merge the returns. Keep their severities, drop duplicates, and where they
   disagree name the evidence that wins.
4. Report what is broken, what was verified, and what neither agent could settle.

Do not edit files during the review.

Extra focus, if any: $ARGUMENTS
