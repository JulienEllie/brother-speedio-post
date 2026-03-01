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

## 3. Finishing smoothing level → L6

- **Where:** `settings.smoothing.finishing` in the `smoothingMode` switch inside `onOpen()` (`grep 'settings.smoothing.finishing'`)
- **From:** `settings.smoothing.finishing = 2`
- **To:** `settings.smoothing.finishing = 6`
- **Why:** M298 L6 ("Finishing S") is the optimal setting for 3D surface finishing on the D00 control. The default L2 is a legacy mapping for mode A/B and doesn't apply to M298.

## 4. Enable G68.2 (tilted workplane)

- **Where:** `useTiltedWorkplane` property definition (`grep 'useTiltedWorkplane'`)
- **From:** `value: false`
- **To:** `value: true`
- **Why:** Required for proper 3+2 positional machining. Without this, angled WCS setups won't generate G68.2 output.

## 5. Safe start block — cancel residual smoothing and rotation

- **Where:** `onOpen()` function, after the `writeBlock(gFeedModeModal.format(94) ...` line (`grep 'gFeedModeModal.format(94)'`)
- **Add these lines after the safe start block:**
  ```javascript
  writeBlock(mFormat.format(298), "L0"); // cancel smoothing
  writeBlock(gFormat.format(69));        // cancel tilted workplane
  ```
- **Why:** Cancels residual M298 smoothing and G68.2 rotation that may persist from previously aborted programs. Ensures a clean machine state at program start.

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

---

## Do NOT change

| Property | Keep as | Why |
|---|---|---|
| `useTrunnion` | `false` | 5-axis machine configuration comes from the CAM system's machine definition. Enabling this when a CAM machine config is present causes an error. |
| `hasAAxis` | `false` | Same reason — axis definitions come from the machine configuration in CAM. |
