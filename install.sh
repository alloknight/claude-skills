#!/usr/bin/env bash
# Install this repo's skills into ~/.claude/skills as symlinks.
#
# Symlinks, not copies: the repo stays the single source of truth, so a
# `git pull` or a local edit takes effect immediately with no reinstall.
#
# Idempotent. Re-running refreshes links and prunes ones pointing at skills
# that no longer exist. Only touches symlinks this script created — a real
# directory in ~/.claude/skills is left alone and reported.
#
# Usage:
#   ./install.sh              install / refresh
#   ./install.sh --dry-run    show what would change
#   ./install.sh --uninstall  remove only the links pointing into this repo

set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SRC="$REPO/skills"
DEST="${CLAUDE_SKILLS_DIR:-$HOME/.claude/skills}"

DRY_RUN=0
UNINSTALL=0
for arg in "$@"; do
  case "$arg" in
    --dry-run)   DRY_RUN=1 ;;
    --uninstall) UNINSTALL=1 ;;
    -h|--help)   sed -n '2,18p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *) echo "unknown option: $arg" >&2; exit 2 ;;
  esac
done

run() { if [ "$DRY_RUN" = 1 ]; then echo "  would: $*"; else "$@"; fi; }

# Collect "name<TAB>path" for every installable skill.
# A skill is any directory containing a SKILL.md, at either:
#   skills/<name>/SKILL.md                     (skills authored or vendored here)
#   skills/<bundle>/skills/<name>/SKILL.md     (multi-skill bundles, e.g. superpowers)
collect() {
  local d
  for d in "$SRC"/*/; do
    [ -d "$d" ] || continue
    if [ -f "$d/SKILL.md" ]; then
      printf '%s\t%s\n' "$(basename "$d")" "${d%/}"
    elif [ -d "$d/skills" ]; then
      local n
      for n in "$d"skills/*/; do
        [ -f "$n/SKILL.md" ] || continue
        printf '%s\t%s\n' "$(basename "$n")" "${n%/}"
      done
    fi
  done
}

SKILLS="$(collect)"
[ -n "$SKILLS" ] || { echo "no skills found under $SRC" >&2; exit 1; }

if [ "$UNINSTALL" = 1 ]; then
  echo "Removing links into $REPO from $DEST"
  removed=0
  for link in "$DEST"/*; do
    [ -L "$link" ] || continue
    case "$(readlink "$link")" in
      "$REPO"/*) run rm "$link"; echo "  - $(basename "$link")"; removed=$((removed+1)) ;;
    esac
  done
  echo "Removed $removed link(s)."
  exit 0
fi

# Fail before touching anything if two skills claim the same name.
dupes="$(printf '%s\n' "$SKILLS" | cut -f1 | sort | uniq -d)"
if [ -n "$dupes" ]; then
  echo "error: duplicate skill names — install aborted:" >&2
  printf '  %s\n' $dupes >&2
  exit 1
fi

run mkdir -p "$DEST"
echo "Installing into $DEST"
echo

linked=0; skipped=0
while IFS=$'\t' read -r name path; do
  [ -n "$name" ] || continue
  target="$DEST/$name"
  if [ -e "$target" ] && [ ! -L "$target" ]; then
    echo "  ! $name — a real directory already exists here, leaving it alone"
    skipped=$((skipped+1))
    continue
  fi
  [ -L "$target" ] && run rm "$target"
  run ln -s "$path" "$target"
  echo "  + $name"
  linked=$((linked+1))
done <<< "$SKILLS"

# Prune links into this repo whose source is gone (e.g. a skill was removed).
pruned=0
for link in "$DEST"/*; do
  [ -L "$link" ] || continue
  case "$(readlink "$link")" in
    "$REPO"/*)
      if [ ! -e "$link" ]; then
        run rm "$link"; echo "  - $(basename "$link") (source gone)"; pruned=$((pruned+1))
      fi ;;
  esac
done

echo
echo "Linked $linked, pruned $pruned, skipped $skipped."
[ "$DRY_RUN" = 1 ] && echo "(dry run — nothing changed)"
echo "Restart Claude Code or start a new session to pick up changes."
