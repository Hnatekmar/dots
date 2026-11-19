---
description: Review the current change (read-only). Runs in build; may use explore for wide caller searches.
agent: build
---
Review the current change. Do not edit files.

1. Get the artifact: `git diff` for the working tree, or `git show HEAD` /
   `git diff <base>...HEAD` when a branch base is obvious.
2. Read the touched files and the callers of every changed function, including
   callers in files the diff does not touch.
3. Check correctness, security, and regressions in callers. When a quick command
   can settle a claim, run it.
4. Report each defect with file:line, severity, and the evidence. Say what you
   could not verify. Do not report style nits.

Extra focus, if any: $ARGUMENTS
