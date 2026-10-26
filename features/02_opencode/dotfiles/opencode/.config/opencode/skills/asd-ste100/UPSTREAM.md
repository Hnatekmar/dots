# Upstream

Vendored from <https://github.com/danyuchn/asd-ste100-skill> at commit
`8da6b6340aa22faf46fd07db8efbdea010cd38d9`. MIT license, see `LICENSE`.

Changes made when vendoring:

- Left out `.claude-plugin/` and the upstream `README.md`: opencode reads
  `SKILL.md` and the files it links, and the plugin manifest is Claude Code
  marketplace metadata.
- `scripts/ste-lint.py` is committed mode 0755 so the `scripts/ste-lint.py`
  invocations in `SKILL.md` run as written, without a `python3` prefix.

To update, copy `SKILL.md`, `references/`, `examples/` and `scripts/` from the
new commit, restore the exec bit on `scripts/ste-lint.py`, and refresh the hash
above.
