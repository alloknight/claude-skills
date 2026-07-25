# superpowers (vendored)

Core engineering-workflow skills library for Claude Code, by
[Jesse Vincent (@obra)](https://github.com/obra).

- **Upstream:** https://github.com/obra/superpowers
- **Version:** 6.2.0
- **Vendored from commit:** `3dcbd5c`
- **License:** MIT — see [`LICENSE`](./LICENSE). Copyright (c) 2025 Jesse Vincent.

This is a partial copy. Only the `skills/` tree and the license were taken; the
upstream hooks, tests, release scripts, and the Claude/Codex/Cursor/Kimi/Gemini
plugin manifests were left behind. To get the full plugin experience, install it
from upstream instead of using this copy.

## Skills

| Skill | Use when |
|---|---|
| [using-superpowers](./skills/using-superpowers/SKILL.md) | Starting any conversation — establishes how to find and invoke the rest |
| [brainstorming](./skills/brainstorming/SKILL.md) | Before any creative work; explores intent and requirements ahead of implementation |
| [writing-plans](./skills/writing-plans/SKILL.md) | You have a spec for a multi-step task and haven't touched code yet |
| [executing-plans](./skills/executing-plans/SKILL.md) | Running a written plan in a separate session with review checkpoints |
| [subagent-driven-development](./skills/subagent-driven-development/SKILL.md) | Executing a plan of independent tasks, one fresh implementer subagent each |
| [dispatching-parallel-agents](./skills/dispatching-parallel-agents/SKILL.md) | 2+ independent tasks with no shared state or ordering |
| [test-driven-development](./skills/test-driven-development/SKILL.md) | Implementing any feature or bugfix, before writing implementation code |
| [systematic-debugging](./skills/systematic-debugging/SKILL.md) | Any bug, test failure, or unexpected behavior, before proposing fixes |
| [verification-before-completion](./skills/verification-before-completion/SKILL.md) | About to claim work is done — demands evidence before assertions |
| [requesting-code-review](./skills/requesting-code-review/SKILL.md) | Completing a feature or before merging; dispatches a reviewer subagent |
| [receiving-code-review](./skills/receiving-code-review/SKILL.md) | Handling review feedback with rigor rather than performative agreement |
| [using-git-worktrees](./skills/using-git-worktrees/SKILL.md) | Feature work that needs isolation from the current workspace |
| [finishing-a-development-branch](./skills/finishing-a-development-branch/SKILL.md) | Implementation is complete and you need to decide how to integrate |
| [writing-skills](./skills/writing-skills/SKILL.md) | Creating, editing, or verifying skills before deployment |
