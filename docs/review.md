# Script review

Review date: 2026-11-27.

The review covers `osd-osdv2.ps1` build `2611.27.003`, the ConfigMgr task sequence patterns, helper scripts, and the static sample render.

## Findings and proposed fixes

| Finding | Impact | Proposed fix | Status |
|---|---|---|---|
| Shared plaintext debug password launched `cmd.exe` in the display process security context. | A package-level password is not an access control boundary. The command prompt may run with task sequence rights. | Remove password handling and the command prompt. Keep Ctrl+Shift+D as a read-only diagnostic summary. | Fixed in build `2611.27.003`. Remove old `DebugPassword` values from local configs. |
| The display uses `ShowDialog()`. | A direct **Run PowerShell Script** step waits for the form to close and blocks the task sequence. | Use `tools/Start-OSDBackground.cmd` from a **Run Command Line** step. It starts PowerShell as a separate process and returns. | Implemented. Confirm the action returns and the display appears in the target deployment session. |
| The display did not relaunch after a reboot. | The form process ends when the computer restarts. | Add launch steps after each reboot where the display must return. Use the optional specialize launch in `unattend.xml` for the early full Windows phase. | Documented. Validate every reboot boundary in a lab. |
| The display treated 20 failed task sequence polls as successful completion. | A connection loss can result from a failure or restart. Technicians could see a false success state. | Require `TSBackgroundState=Complete` or `TSBackgroundState=Failed`. Keep status unknown when the connection disappears without a signal. | Display behavior fixed. Add the success and error groups described in `docs/error-handling.md` to the task sequence. |
| Progress uses the next instruction pointer divided by the instruction table size. | Branches, skipped actions, and variable task durations make this a position indicator, not a measure of work completed. Remaining time can be inaccurate. | Label the percentage as approximate progress. Keep time as an estimate and avoid estimates in configured long steps. | Fixed in build `2611.27.003`; the UI says `APPROXIMATE PROGRESS`. The guide describes remaining time as an estimate. |
| Preview mode reads real local device and network details. | A live preview can expose a hostname, serial number, domain, IP address, or MAC address on a recorded or shared screen. | Use the synthetic static render for demonstrations. A future preview-data option could replace every hardware field with configured sample values. | Documented limit. `render/osd-osdv2-preview.png` uses fake values. |
| The script header and UI showed different version formats. | Operators could report different build identities for one file. | Keep one build identifier in the source header and UI footer. | Fixed in build `2611.27.003`. |
| The deployment status pill was aligned to the full canvas edge. | It looked offset from the step column in the sidebar. | Align the pill dot with the timeline markers. Keep the pill size and spacing intact. | Fixed in the current branch. The script and primary preview use the same timeline axis. |
| The setup steps were spread across source pages and needed more console detail. | An administrator could need another guide to create and distribute the package or add task sequence steps. | Add the full console workflow, field values, conditions, boot image instructions, and pilot checks to the repository. Keep source pages optional. | Fixed in `docs/task-sequence-setup.md` and `docs/error-handling.md`. |
| The static preview used `example.invalid` and a `NW-` hostname. | These values did not match the requested synthetic demo data and could imply another brand. | Use Signal Ridge Labs branding, `contoso.com`, and a Signal Ridge synthetic hostname. | Fixed in the static preview. |
| The error-handling guide placed the success group before the error group. | The error group should test the deployment wrapper result immediately after that group. | Put the error group directly after the wrapper. Put the success group after the error group. | Fixed in `docs/error-handling.md` using Microsoft's documented sequence. |
| The display has no external stop action. | An abnormal exit can leave a process until the technician closes the window or the device restarts. | Keep Escape as the supported close action. Add a separate stop action only if a lab proves it is needed and can target the exact process and session. | No external stop action is required for the documented pilot. The failure window remains open for technician review. |

## Task sequence design

The recommended pilot uses an asynchronous command-line launcher, explicit task sequence state, an error group immediately after the deployment wrapper, and a success group after the error group. The success group also checks that the OSD-OSD state is still `Running`, so a successful error-handler action cannot be mistaken for deployment success. The error group stores the failed action and return code before it runs other handler steps. This follows Microsoft's documented use of `_SMSTSLastActionSucceeded` and Jörgen Nilsson's 2016 OSDBackground example.

The optional early Windows launch uses `RunSynchronousCommand` during specialize. Microsoft documents this command as running in the system context and waiting for completion in that pass. The sample starts a detached process, but this repository has not validated whether the window is visible on each target Windows build. Use the normal post-setup launch if the form is not visible.

OSD-OSD is a foreground display. It does not replace `smsts.log`, the ConfigMgr task sequence progress UI, or an organization-approved recovery process.

## Positive observations

- The v2 UI uses one custom-painted canvas and scales its layout from screen dimensions.
- The script caches its background bitmap and fonts between refreshes.
- The step tracker shows completed, active, and pending phases with separate labels.
- The remaining-time logic suppresses guesses during configured long steps.
- The script logs diagnostics to `%SystemRoot%\Temp\osd-osd.log` and limits repeated error messages with `Write-LogOnce`.
- The repository preview is a static render with Signal Ridge Labs branding and synthetic device data, including `contoso.com`.

## Remaining work

- [ ] Run a ConfigMgr lab pilot for Windows PE, full Windows, and each required reboot boundary. Confirm that the asynchronous launch returns and the UI is visible in each intended phase.
- [ ] Test success and error group conditions. Confirm that the display shows both states and the error path returns the original failure code when enabled.
- [ ] Test the optional specialize-pass `unattend.xml` launch. Confirm that the form is visible in the technician's session and that the task sequence continues.
- [ ] Review the 45 PSScriptAnalyzer warnings in the main display script. Do not rename legacy drawing functions or change error handling without checking all callers and testing the UI. The two helper scripts have no findings.

## Review limits

This is a static code and documentation review. The PowerShell parser accepted all three PowerShell files. The example JSON parsed. PSScriptAnalyzer reported 45 warnings in the main UI script and no findings in the two helper scripts. The warning groups are empty catch blocks, WMI cmdlets, unapproved internal verbs, assignments to the automatic variable `sender`, an unused visibility variable, and the `Write-Log` function name. No ConfigMgr task sequence, boot image, unattend deployment, reboot flow, or error path has been exercised. Validate these flows in the ConfigMgr lab before production use.
