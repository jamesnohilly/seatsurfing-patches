# Patch Workflow

`apply.sh` clones an upstream Seatsurfing tag into a fresh directory and applies the patch files under `server/` and `ui/` as a commit series. Translation files are rebuilt from the `i18n/` patch set after the code patches have been applied, and the rebuilt locale files are committed in the generated checkout as a dedicated i18n commit.

It can take a small manifest file to choose the tag for a given environment. The manifest is just a plain text file with `key=value` lines:

```text
development=v1.99.0
production=v1.99.0
```

Patch categories are split by concern:

- `server/` for backend changes
- `ui/` for frontend code changes
- `i18n/` for translation file updates, rebuilt by `rebuild-translations.py`

The patches were created against a specific upstream tag. When you update to a newer tag, the upstream files may have changed enough that one or more hunks no longer match exactly. In that case `git am` can stop on a conflict and leave the checkout in an in-progress patch state.

## Recommended Way To Update

1. Pick the new upstream tag.
2. Either pass the tag directly or point the script at a manifest:

   ```bash
   ./apply.sh -t vX.Y.Z
   ./apply.sh -m ./tags.txt -e production
   ```

3. The script applies `server/` and `ui/` patches with `git am`.
4. The script then rebuilds the translation JSON files from the `i18n/` patch set and commits the result in the generated checkout.
5. If a patch fails, open the checkout that was created in the output directory.
6. Resolve the conflicted file(s) manually.
7. When the conflict is resolved, rerun the script from a clean checkout if you want to re-apply the full patch set.

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

Translation patches are treated as a semantic input to `rebuild-translations.py`, which merges the added locale keys into the checked-out base tag and then commits the rebuilt locale files. This avoids line-position conflicts in the locale JSON files while still keeping the i18n changes in the patch series.

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
