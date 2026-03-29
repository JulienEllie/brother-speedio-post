# Customizations for Brother Speedio U500XD2-5AX

Machine: **U500XD2-5AX** (CNC-D00v control, 16K RPM, CTS, 28-tool, Renishaw probe)

Last verified against upstream revision: **44214** (2026-02-17)

These changes should be re-applied each time `update.sh` pulls a new upstream version.
Update this revision number after verifying customizations against a new version.

---

## 1. Smoothing mode → M298

- **Where:** `smoothingMode` property definition (`grep 'smoothingMode'`)
- **From:** `value: "A"`
- **To:** `value: "M298"`
- **Why:** The CNC-D00v controller uses the M298 Ln smoothing system, not the legacy M260/M269 codes.

## 2. Enable high accuracy (automatic)

- **Where:** `useSmoothing` property definition (`grep 'useSmoothing'`)
- **From:** `value: "-1"` (Off)
- **To:** `value: "9999"` (Automatic)
- **Why:** High accuracy mode should always be active for milling on the D00 control.

## 3. Finishing smoothing level → L6 + Mode B fallback for TCP

- **Where:** `smoothingMode` switch inside `onOpen()` (`grep 'settings.smoothing.finishing'`)
- **Add:** a `case "M298":` block with:
  ```javascript
  settings.smoothing.finishing = 6; // M298 L6 = Finishing S
  settings.smoothing.modeBRoughing = 5;
  settings.smoothing.modeBSemi = 3;
  settings.smoothing.modeBSemifinishing = 1;
  settings.smoothing.modeBFinishing = 2;
  ```
- **Why:** The framework default for finishing is L5. M298 L6 ("Finishing S") is the optimal setting for 3D surface finishing on the D00 control. The Mode B levels are fallback mappings used by `setSmoothing()` during multi-axis TCP operations (see #11).

## 4. Enable G68.2 (tilted workplane)

- **Where:** `useTiltedWorkplane` property definition (`grep 'useTiltedWorkplane'`)
- **From:** `value: false`
- **To:** `value: true`
- **Why:** Required for proper 3+2 positional machining. Without this, angled WCS setups won't generate G68.2 output.

## 5. Safe start block — cancel residual smoothing and rotation

- **Where:** `onOpen()` function, after the `writeBlock(gFeedModeModal.format(94) ...` line (`grep 'gFeedModeModal.format(94)'`)
- **Add these lines after the safe start block:**
  ```javascript
  writeBlock(mFormat.format(299)); // cancel M298 machining mode (required before TCP)
  writeBlock(gFormat.format(69));  // cancel tilted workplane
  ```
- **Why:** Cancels residual M298 machining mode and G68.2 rotation that may persist from previously aborted programs. Uses M299 (not M298 L0) because M299 fully exits M298 mode, which is required before G43.4/G43.5 TCP can activate. M298 L0 only sets the level to zero but leaves M298 mode selected, which blocks TCP.

## 6. Washdown coolant → end of operation

- **Where:** `washdownCoolant` property definition (`grep 'washdownCoolant'`)
- **From:** `value: "off"`
- **To:** `value: "operationEnd"`
- **Why:** Activates chip washdown between operations for better chip management in the enclosed work area.

## 7. Enable clamp codes

- **Where:** `useClampCodes` property definition (`grep 'useClampCodes'`)
- **From:** `value: false`
- **To:** `value: true`
- **Why:** Outputs M443/M444 (4th axis) and M441/M442 (5th axis) clamp/unclamp codes for improved rigidity during 3+2 indexed work.

## 8. Double tap withdraw speed

- **Where:** `doubleTapWithdrawSpeed` property definition (`grep 'doubleTapWithdrawSpeed'`)
- **From:** `value: false`
- **To:** `value: true`
- **Why:** Outputs an L value in G77 tapping cycles for faster withdrawal (up to 6000 RPM). Takes advantage of the 16K spindle's capability.

## 9. Stuck chips detection (optional, default OFF)

- **Where:** `useStuckChipsDetection` property definition (`grep 'useStuckChipsDetection'`)
- **Default:** `value: false`
- **To enable:** `value: true`
- **Why:** Outputs M318 at program start to enable Z-axis load monitoring during tool changes. The D00 compares each tool change load signature against a learned baseline to detect chips or debris stuck between the spindle face and tool holder. Only useful once your magazine is stable — the detection compares against previously recorded load profiles, so if you're frequently swapping tools in/out of the magazine, the baselines won't be meaningful and you'll get false alarms. Enable this for production runs where the tool lineup is settled.

## 10. Safe probing — protected approach moves

- **Where:** `useSafeProbing` property definition (`grep 'useSafeProbing'`) and `onRapid()` function (`grep 'function onRapid'`)
- **Default:** `value: true`
- **What:** Adds a `useSafeProbing` property and modifies `onRapid()` to use G65 P8810 (protected positioning with G31 P2 skip-on-trigger) for all rapid moves when the probe is active. Splits combined XYZ rapids into safe Z-up → XY → Z-down ordering.
- **Why:** The stock post only uses protected positioning during the probing cycle itself (`protectedProbeMove`). The initial approach rapids from the tool change position to the probing area use regular G0 — if WCS is wrong, the probe crashes into the part with no trigger detection. With this enabled, every rapid move with the probe in the spindle goes through O8810, which stops with a PATH OBSTRUCTED alarm on premature contact. Tradeoff: approach moves use F5000 instead of true G0 rapid, so disable for production when you trust your WCS and want maximum speed.

## 11. M298 / TCP incompatibility — automatic Mode B fallback for multi-axis

- **Where:** `setSmoothing()` function, `smoothing` state object, and `initializeSmoothing()` (`grep 'usedModeB'`)
- **What:** On the D00 control, M298 and G43.4/G43.5 TCP are mutually exclusive. Issuing M298 while TCP is active triggers `<<TCP under control>>`. Issuing G43.4 while M298 is selected triggers `<<TCP control command not possible>>`. Per the programming manual (Ch. 13 / 14.2), Mode B (M280-M287) is the only smoothing mode valid during TCP.

  The fix has four parts:

  1. **`setSmoothing()` rewired for M298 mode** — When enabling smoothing for a multi-axis/TCP section, outputs M280+level (Mode B) instead of M298 Ln. For non-TCP sections, M298 Ln is used as before. Cancellation outputs M299 (fully exits M298 mode) or M289 (Mode B cancel) depending on which was active, tracked by `smoothing.usedModeB`.

  2. **Level mapping** — M298 and Mode B use different level numbering. The M298 level (set by `initializeSmoothing`) is mapped to the equivalent Mode B level by category: roughing→5, semi→3, semifinishing→1, finishing→2. Mappings are stored in `settings.smoothing.modeB*` (see #3).

  3. **`setSmoothing` moved before tool call in `onSection()`** — Smoothing codes must be output before G100 (which activates G43.4 TCP internally). Moved from after coolant to before the `insertToolCall` block. Also moved before G100 in `onClose()`.

  4. **`initializeSmoothing()` TCP transition detection** — Forces smoothing re-output when switching between TCP and non-TCP sections. Without this, the `isDifferent` guard in `setSmoothing()` would skip output when the smoothing level is the same but the required M-code changes (M298 vs M280).

- **Why:** Without this, any program mixing 3-axis and 5-axis operations with smoothing enabled would alarm on the first multi-axis section. The D00 manual explicitly states M280-M287 is valid regardless of TCP state, making it the correct choice for 5-axis work.

- **NC output example (3-axis → 5-axis transition):**
  ```
  M299         (cancel M298 mode — required before TCP)
  ...
  M282         (Mode B finishing — compatible with TCP)
  G100 T08 ... G43.4 ...  (tool call activates TCP)
  ...
  M289         (cancel Mode B at section end)
  M298 L6      (back to M298 for next 3-axis section)
  ```

---

## Do NOT change

| Property | Keep as | Why |
|---|---|---|
| `useTrunnion` | `false` | 5-axis machine configuration comes from the CAM system's machine definition. Enabling this when a CAM machine config is present causes an error. |
| `hasAAxis` | `false` | Same reason — axis definitions come from the machine configuration in CAM. |
