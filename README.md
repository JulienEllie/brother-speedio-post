# Brother Speedio Post Processor

Customized [Autodesk Fusion](https://cam.autodesk.com/hsmposts) post processor for the **Brother Speedio U500XD2-5AX** (CNC-D00v control, 16K RPM, CTS, 28-tool magazine, Renishaw probe).

The upstream post (`brother_speedio.cps`) is a generic post that covers the entire Speedio family — S, W, R, U, F, and H series. Its defaults target older controls (CNC-B00/C00) and the most conservative settings. This repo tracks a customized version tuned for the D00v control and the U500XD2-5AX's specific capabilities.

## What's changed

See [CUSTOMIZATIONS.md](CUSTOMIZATIONS.md) for the full list with rationale. In short:

- **M298 smoothing** — The D00 control uses the [M298 Ln system](https://cam.autodesk.com/posts/reference/index.html) for high-accuracy mode, not the legacy M260/M269 codes. Smoothing is set to automatic with L6 for finishing surfaces.
- **G68.2 tilted workplane** — Required for [3+2 positional machining](https://plasticranger.com/g68-2-cnc-code/) on the 5-axis trunnion table.
- **Safe start block** — Outputs `M298 L0` and `G69` at program start to cancel residual smoothing and workplane rotation from previously aborted programs.
- **Washdown coolant** — Enabled between operations for chip management in the enclosed work area.
- **Clamp codes** — Outputs M443/M441 clamp commands for rigidity during indexed 3+2 work.
- **Double tap withdraw** — Takes advantage of the 16K spindle for faster G77 tapping cycles.

## Updating to a new upstream version

```bash
bash update.sh
```

This downloads the latest post from the [Autodesk post library](https://cam.autodesk.com/hsmposts), extracts the JavaScript source, and saves it as `brother_speedio.cps`. After updating, review [CUSTOMIZATIONS.md](CUSTOMIZATIONS.md) and re-apply the changes.

## Links

- [Autodesk post processor library](https://cam.autodesk.com/hsmposts) — upstream source
- [Post processor API reference](https://cam.autodesk.com/posts/reference/index.html) — .cps framework documentation
- [Post processor training guide (PDF)](https://cam.autodesk.com/posts/posts/guides/Post%20Processor%20Training%20Guide.pdf) — customization walkthrough
- [Brother U500XD2-5AX](https://machinetool.global.brother/en-us/all-products/uxd2/u500xd2-5ax) — machine product page
- [Brother CNC-D00 control](https://machinetool.global.brother/en-eu/cnc-d00) — control product page
- [G68.2 tilted workplane reference](https://plasticranger.com/g68-2-cnc-code/) — technical guide
