# Before installing this skill — read this

Two things about `know-me` differ from every other skill in this repo. Both
matter at install time, not while it sits here in the repo.

## 1. It auto-activates

The frontmatter sets `auto-activate: true`. Once installed it fires on its own
whenever you share personal information, state a preference, or correct Claude.
There is no per-use opt-in. No other skill in this repo behaves this way.

## 2. It collides with Claude Code's built-in memory

This skill writes to:

```
~/.claude/projects/<project-path>/memory/
```

That is the same directory Claude Code's own file-based memory uses, but the
two use **incompatible layouts**:

| | Built-in memory | `know-me` |
|---|---|---|
| Unit | One fact per file | One topic per file |
| Frontmatter | YAML: `name`, `description`, `metadata.type` | None |
| Linking | `[[wiki-links]]` between memories | None |
| Files | Arbitrary, one per fact | Fixed set: `user-preferences.md`, `project-context.md`, `tech-stack.md`, `communication-style.md`, `corrections.md` |
| `MEMORY.md` | Index of one-line pointers | Index of one-line pointers (compatible) |

Running both against the same directory produces a hybrid where half the
entries carry frontmatter and half don't, and recall behavior depends on which
system wrote a given file.

## Pick one before installing

- **Use the built-in memory** — don't install this skill. It's kept here for
  reference and for the `what-to-track.md` signal taxonomy, which is useful
  reading regardless.
- **Use `know-me` instead** — install it, and expect it to take over the
  memory directory.
- **Run both** — first retarget this skill by changing the path in `SKILL.md`
  (line 32) and `memory-operations.md` (line 6) to something isolated, e.g.
  `~/.claude/projects/<project-path>/know-me/`.
