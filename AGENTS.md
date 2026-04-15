# BeavisQoL Agent Rules

These repository rules exist so Codex-style agents load the BeavisQoL workflow
even when the local `.local` wrapper is not involved.

## Scope

These instructions apply to the entire repository.

## Core Rules

1. Do not commit or publish `.local/`, editor metadata, logs, temp files, or other local working remnants.
2. Do not copy code from other addons or third-party projects. Reimplement ideas independently.
3. Use proper German umlauts in German prose, comments, changelog entries, and localizations whenever the file is not constrained by a technical format. Do not rewrite stable identifiers just to force umlauts.
4. Keep performance in mind for hot paths such as `OnUpdate`, repeated UI refreshes, and large loops.
5. Document user-visible changes in `CHANGELOG.md`, and update `README.md` and metadata when release-visible behavior changes. Public changelog entries should be short and end-user-friendly rather than detailed technical change histories.
6. After every handled request, provide a concise feature checklist the user can run to verify the touched feature and confirm its core related functions still work.
7. Do not modify code outside the requested module without explicit user approval. If cross-module changes look necessary, stop and ask first.
8. Before making any change, create a local backup of the affected files. Keep that backup until the user confirms via the checklist that the change is good; after confirmation, archive it locally for at least 30 days before it may be removed.
9. Track user confirmations and non-confirmations explicitly in the local agent notes. Do not silently assume approval or successful verification; when a checklist confirmation, backup cleanup approval, or other validation is still open, follow up and ask again later until it is resolved.

## Commit Workflow

When the user says only `commit` in this repository, treat that as the default release-prep workflow unless they explicitly say otherwise:

1. Bump the version according to the versioning rules in `README.md`.
2. Update `CHANGELOG.md`.
3. For visible release changes, also update `README.md` and addon metadata such as `BeavisQoL.toc`.
4. Keep the local version state unified across the repository; `commit` is a local workspace action and does not imply any dev/prod target by itself.
5. Then commit the full current workspace state, not just a subset you selected yourself.

## Branch / Push Defaults

1. Do not infer a push target from `commit`.
2. Only push when the user explicitly asks for `push` and states where it should go; if the destination is missing, ask once briefly before pushing.
3. Before pushing, verify local branch, remote, and target branch.
