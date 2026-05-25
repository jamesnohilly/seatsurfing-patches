# Patch Workflow

`apply.sh` clones an upstream Seatsurfing tag into a fresh directory and applies the patch files under `server/`, `i18n/`, and `ui/` as a commit series.

It can take a small manifest file to choose the tag for a given environment. The manifest is just a plain text file with `key=value` lines:

```text
development=v1.99.0
production=v1.99.0
```

Patch categories are split by concern:

- `server/` for backend changes
- `i18n/` for translation file updates
- `ui/` for frontend code changes

The patches were created against a specific upstream tag. When you update to a newer tag, the upstream files may have changed enough that one or more hunks no longer match exactly. In that case `git am` can stop on a conflict and leave the checkout in an in-progress patch state.

## Recommended Way To Update

1. Pick the new upstream tag.
2. Either pass the tag directly or point the script at a manifest:

   ```bash
   ./apply.sh -t vX.Y.Z
   ./apply.sh -m ./tags.txt -e production
   ```

3. If a patch fails, open the checkout that was created in the output directory.
4. Resolve the conflicted file(s) manually.
5. When the conflict is resolved, rerun the script from a clean checkout if you want to re-apply the full patch set.

## Manifest Precedence

The script resolves the tag in this order:

1. `-t <tag>` if provided.
2. `-m <manifest>` plus `-e <environment>`.
3. The built-in pinned default tag.

That means the manifest is a convenience layer for keeping development and production in sync without repeating the tag on every command.

## Easiest Conflict Recovery

The script uses `git am --3way` so Git can try a three-way merge when the exact patch no longer matches. This is usually the least painful option because:

- small upstream changes can often be merged automatically,
- conflicts are shown in the target files instead of failing silently,
- you can resolve them with normal Git conflict resolution tools.

The patch files are generated from commits with `git format-patch`. That keeps the commit messages aligned with the patch series and makes the maintenance workflow cleaner when upstream changes force you to refresh one patch.

When a conflict appears:

1. Run `git status` in the generated checkout to see the affected files.
2. Open the file and resolve the conflict markers.
3. Run `git am --continue` to finish applying the patch.
4. Verify the result with `git log --oneline` and `git diff`.

## When A Patch Needs To Be Refreshed

If a patch keeps failing against a new tag, the patch itself usually needs to be regenerated from the updated upstream version rather than edited by hand. The cleanest workflow is:

1. Create a temporary branch or worktree from the new upstream tag.
2. Re-apply the project changes there.
3. Create or update the commit that contains the fix.
4. Regenerate the patch file from that updated branch with `git format-patch`.
5. Replace the old patch in `server/`, `i18n/`, or `ui/`.

This keeps the patch files aligned with the current upstream code and reduces repeated conflict work on future updates.
