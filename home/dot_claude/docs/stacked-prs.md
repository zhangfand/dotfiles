# Stacked PRs

A "child" PR is one whose base branch is another open PR (not `main`). Squash-merge of the parent rewrites its commits to a single new SHA on `main`, so a naive `git rebase main` on the child treats the parent's original commits as "missing" and produces massive false conflicts. The workflow below uses `git rebase --onto` with a stored old-base SHA to avoid this.

**Metadata, set on the child branch at creation:**
- `git config branch.<child>.stackParent <parent-branch>` — local, names the parent.
- `git config branch.<child>.stackParentSha <parent-tip-sha>` — local, the "old base" passed to `--onto` on every restack.
- `Stacked-on: <parent-branch>@<sha>` trailer in the child's first commit — pushed, survives worktree/machine changes and lost `.git/config`. Set once; do not amend later.

**Restack the child only when:**
- Parent was force-pushed (detect via `git log <stackParentSha>..origin/<parent>` lacking the stored SHA as ancestor).
- Child needs new code from parent.
- Child is about to be merged.
- Child CI fails because parent moved.
- Parent was squash-merged to `main` (special case: target is `origin/main`; clear the metadata after).

Routine fast-forward updates on parent do NOT trigger a child restack — GitHub's child-PR diff (base = parent-branch) auto-excludes parent's new commits, so reviewability is unaffected. Restacking eagerly just churns CI and notifies reviewers for nothing.

**Restack command:**

```bash
OLD=$(git config branch.<child>.stackParentSha)
NEW=$(git rev-parse origin/<parent-branch>)   # or origin/main when parent merged

git checkout <child>
git rebase --onto $NEW $OLD
git push --force-with-lease
git config branch.<child>.stackParentSha $NEW   # mandatory: keep metadata fresh
```

If `stackParentSha` is missing (different worktree, machine, fresh clone), recover from the child's first-commit trailer: `git log --format='%(trailers:key=Stacked-on)' <merge-base>..<child>`. Final fallback: `gh pr view <parent-PR> --json headRefOid -q .headRefOid`.

**On any branch that has a child stacked on it:** push new commits, never amend or rebase-rewrite history. Force-push is a child-restack trigger; new commits are not. Force-push is fine on branches with no children.
