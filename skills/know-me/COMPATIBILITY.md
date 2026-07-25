# Before installing this skill — read this

## It auto-activates

The frontmatter sets `auto-activate: true`. Once installed it fires on its own
whenever you share personal information, state a preference, or correct Claude.
There is no per-use opt-in, and no other skill in this repo behaves this way.

## Its write path has been retargeted (modified from source)

As shipped, this skill wrote to `~/.claude/projects/<project-path>/memory/` —
the same directory Claude Code's own file-based memory uses, but with an
incompatible layout:

| | Built-in memory | `know-me` |
|---|---|---|
| Unit | One fact per file | One topic per file |
| Frontmatter | YAML: `name`, `description`, `metadata.type` | None |
| Linking | `[[wiki-links]]` between memories | None |
| Files | Arbitrary, one per fact | Fixed set: `user-preferences.md`, `project-context.md`, `tech-stack.md`, `communication-style.md`, `corrections.md` |

Sharing the directory would produce a hybrid where half the entries carry
frontmatter and half don't, and recall behavior depends on which system wrote
a given file. Both `MEMORY.md` indexes would also fight over the same filename.

So the path here is changed to an isolated directory:

```
~/.claude/projects/<project-path>/know-me/
```

The two systems now coexist without touching each other's files.

### One consequence of the retarget

Only the built-in `memory/MEMORY.md` gets auto-loaded into context at session
start. At the new path, nothing loads automatically — so `memory-operations.md`
was also updated to say that `know-me/MEMORY.md` must be **read explicitly** at
the start of a session. Without that read, this skill will save happily and
recall nothing.

### Reverting

To restore upstream behavior, change the path back in `SKILL.md` (line 32) and
`memory-operations.md` (lines 6, 16, and the recall checklist), and accept that
it will share a directory with the built-in memory.
