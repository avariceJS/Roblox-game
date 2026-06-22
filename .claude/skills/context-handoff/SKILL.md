---
name: context-handoff
description: Manual /compact handoff when context >60%
---

# Context Handoff Playbook

## When to use

- `/context` shows 60% or higher
- Multi-step task spanning many files
- Before switching to unrelated task in same session

## Manual /compact prompt

```
/compact preserve the handoff strictly in this format:

Goal: one line describing the current task.
Changed files: path -> what changed.
Decisions: options rejected and why.
Current failure: Studio step, error summary, hypothesis.
Verification: test steps already run and results.
Next step: one next file or one Studio test.

Remove: style chatter, failed prompt drafts, generic reasoning.
```

## When /clear instead

- Same bug corrected twice without success
- Claude contradicts earlier decisions
- Phase drift (implementing Phase 4 while Phase 2 incomplete)

After `/clear`, new prompt with: ROADMAP phase, goal, constraints, Studio test, verification steps.
