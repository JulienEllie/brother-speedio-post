# Brother Speedio Post Processor

Customized [Autodesk Fusion](https://cam.autodesk.com/hsmposts) post processor for the **Brother Speedio U500XD2-5AX** (CNC-D00v control, 16K RPM, CTS, 28-tool magazine, Renishaw probe).

The upstream post (`brother_speedio.cps`) is a generic post that covers the entire Speedio family — S, W, R, U, F, and H series. Its defaults target older controls (CNC-B00/C00) and the most conservative settings. This repo tracks a customized version tuned for the D00v control and the U500XD2-5AX's specific capabilities.

## What's changed

See [CUSTOMIZATIONS.md](CUSTOMIZATIONS.md) for the full list with rationale. In short:

- **M298 smoothing with Mode B fallback** — The D00 control uses the M298 Ln system for high-accuracy mode, not the legacy M260/M269 codes. Smoothing is set to automatic with L6 for finishing surfaces. Since M298 is incompatible with G43.4/G43.5 TCP, multi-axis sections automatically use Mode B (M280-M287) instead — the only smoothing mode the D00 allows during TCP.
- **G68.2 tilted workplane** — Required for [3+2 positional machining](https://plasticranger.com/g68-2-cnc-code/) on the 5-axis trunnion table.
- **Safe start block** — Outputs `M299` and `G69` at program start to cancel residual M298 machining mode and workplane rotation from previously aborted programs.
- **Washdown coolant** — Enabled between operations for chip management in the enclosed work area.
- **Clamp codes** — Outputs M443/M441 clamp commands for rigidity during indexed 3+2 work.
- **Double tap withdraw** — Takes advantage of the 16K spindle for faster G77 tapping cycles.
- **Safe probing** — All rapid moves with the probe active use G65 P8810 (protected positioning with G31 P2 skip-on-trigger) instead of bare G0. Stops with a PATH OBSTRUCTED alarm if the probe contacts anything during approach, preventing probe damage from wrong WCS.
- **Stuck chips detection** — Optional M318 output at program start to monitor Z-axis load during tool changes and detect debris between spindle face and tool holder.

## Options

These properties can be toggled in Fusion's post processor dialog:

| Property | Default | Description |
|---|---|---|
| Enable safe probing | ON | Uses protected positioning (O8810) for all probe approach moves instead of G0 rapid. Prevents probe damage if WCS is wrong. Disable for maximum speed in production when you trust your WCS. |
| Stuck chips detection | OFF | Outputs M318 at program start to enable Z-axis load monitoring during tool changes. Only useful once your magazine tool lineup is stable — frequent tool swaps cause false alarms against the learned baselines. |

## Updating to a new upstream version

```bash
bash update.sh
```

This downloads the latest post from the [Autodesk post library](https://cam.autodesk.com/hsmposts), extracts the JavaScript source, and saves it as `brother_speedio.cps`. After updating, review [CUSTOMIZATIONS.md](CUSTOMIZATIONS.md) and re-apply the changes.

## Disclaimer

This post processor is provided as-is, with no promises or guarantees of accuracy, safety, or fitness for any purpose. Use it at your own risk. You are responsible for verifying all G-code output before running it on your machine. I am not responsible for any damage to your machine, tooling, workpiece, or anything else — including but not limited to setting your machine on fire.

## Links

- [Autodesk post processor library](https://cam.autodesk.com/hsmposts) — upstream source
- [Post processor API reference](https://cam.autodesk.com/posts/reference/index.html) — .cps framework documentation
- [Post processor training guide (PDF)](https://cam.autodesk.com/posts/posts/guides/Post%20Processor%20Training%20Guide.pdf) — customization walkthrough
- [Brother U500XD2-5AX](https://machinetool.global.brother/en-us/all-products/uxd2/u500xd2-5ax) — machine product page
- [Brother CNC-D00 control](https://machinetool.global.brother/en-eu/cnc-d00) — control product page
- [G68.2 tilted workplane reference](https://plasticranger.com/g68-2-cnc-code/) — technical guide
