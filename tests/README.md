# Regression testing

Runs the Autodesk post binary over a set of `.cnc` fixtures (3, 3+2, 5-axis milling + probing + drilling + coolant) to catch unintended changes in generated G-code when we bump upstream or change our customizations.

## How it works

Post processor versions live as committed files under:

- `upstream/<rev>_<date>.cps` — vanilla snapshots from Autodesk
- `modified/<rev>_<date>.cps` — our customized versions, one per upstream bump

NC outputs (generated when regression runs) live under `tests/runs/<upstream|modified>/<rev>_<date>/` — gitignored, always regenerable.

The two comparisons that matter:

- **Regression** — `modified/N` vs `modified/N-1` (same track, across an upstream bump). This is the signal we watch.
- **Sanity** — `upstream/N` vs `modified/N` (same point, different track). Tells you what our customizations actually produce in the NC output.

## Setup

1. Copy `post.env.example` to `post.env` and set `MACHINE_FILE` to your `.mch`. `POST_BIN` is auto-detected on macOS but can be overridden.
2. Fixtures are under `tests/fixtures/` (committed — see attribution below).

## Typical workflow — after an upstream bump

After `./update.sh` has saved the new `upstream/<new-label>.cps` and bootstrapped `modified/<new-label>.cps`, apply your customization merges into the new modified file, then:

```bash
./tests/regression.sh run upstream upstream/<prev-label>.cps
./tests/regression.sh run upstream upstream/<new-label>.cps
./tests/regression.sh run modified modified/<prev-label>.cps
./tests/regression.sh run modified modified/<new-label>.cps

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

The `.cnc` fixtures under `tests/fixtures/Milling` and `tests/fixtures/Probing` are copied from Autodesk's [cam-posteditor](https://github.com/Autodesk/cam-posteditor) VS Code extension (`vs-code-extension/res/CNC files/`), MIT-licensed. Copyright © 2017 Autodesk, Inc. The set has been pruned to what runs cleanly on the U500XD2-5AX machine configuration (A-axis-only, air/mist/suction coolant, and inspect-surface probing fixtures were removed as unsupported).
