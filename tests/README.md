# Regression testing

Runs the Autodesk post binary over a set of `.cnc` fixtures (3, 3+2, 4, 5-axis milling + probing) to catch unintended changes in generated G-code when we bump upstream or change our customizations.

## How it works

Two axes of outputs are generated, both gitignored under `tests/runs/`:

- `runs/upstream/<rev>_<date>/...` — from a vanilla Autodesk snapshot (e.g. `brother_speedio_44220_2026-04-01.cps`)
- `runs/modified/<rev>_<date>/...` — from our customized post (`brother_speedio_microfactory.cps`)

The `<rev>_<date>` label is pulled automatically from the `.cps` header's `$Revision` / `$Date` lines, so a run is always tied to a specific upstream version.

The two comparisons that matter:

- **Regression** — `modified/N` vs `modified/N-1` (same track, across an upstream bump). This is the signal we watch.
- **Sanity** — `upstream/N` vs `modified/N` (same point, different track). Tells you what our customizations actually produce in the NC output.

NC output files are never committed. The `.cps` files are the committed source of truth; outputs are always regenerable.

## Setup

1. Copy `post.env.example` to `post.env` and set `POST_BIN` if auto-detection fails. The script looks for the post binary under `~/Library/Application Support/Autodesk/webdeploy/production/<hash>/Autodesk Fusion.app/Contents/Libraries/Applications/CAM360/post` on macOS.
2. Make sure fixtures are present under `tests/fixtures/` (they're committed — see attribution below).

## Typical workflow — after an upstream bump

Run the new version on both tracks:

```bash
./tests/regression.sh run upstream brother_speedio_44220_2026-04-01.cps
./tests/regression.sh run modified brother_speedio_microfactory.cps
```

Now run the previous version (fetch the prior `.cps` files from git — simplest is a worktree):

```bash
git worktree add /tmp/speedio-prev <prev-sha>
./tests/regression.sh run upstream /tmp/speedio-prev/brother_speedio_<prev-rev>_<prev-date>.cps
./tests/regression.sh run modified /tmp/speedio-prev/brother_speedio_microfactory.cps
git worktree remove /tmp/speedio-prev
```

Then:

```bash
./tests/regression.sh list
./tests/regression.sh diff modified <prev-label> <new-label>   # the regression check
./tests/regression.sh diff upstream <prev-label> <new-label>   # what upstream changed
./tests/regression.sh diff-pair <new-label>                    # what our customizations do
```

To see a full diff on one file:

```bash
diff -u "$(./tests/regression.sh show modified <labelA> Milling/3+2/b30)" \
        "$(./tests/regression.sh show modified <labelB> Milling/3+2/b30)"
```

## Fixture attribution

The `.cnc` fixtures under `tests/fixtures/Milling` and `tests/fixtures/Probing` are copied from Autodesk's [cam-posteditor](https://github.com/Autodesk/cam-posteditor) VS Code extension (`vs-code-extension/res/CNC files/`), MIT-licensed. Copyright © 2017 Autodesk, Inc.
