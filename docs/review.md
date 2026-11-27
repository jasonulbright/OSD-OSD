# Script review

Review date: 2026-11-27.

The review covers `osd-osdv2.ps1` build `2611.27.003`, the ConfigMgr task sequence patterns, helper scripts, and the static sample render.

## Findings and proposed fixes

| Finding | Impact | Proposed fix | Status |
|---|---|---|---|
| Shared plaintext debug password launched `cmd.exe` in the display process security context. | A package-level password is not an access control boundary. The command prompt may run with task sequence rights. | Remove password handling and the command prompt. Keep Ctrl+Shift+D as a read-only diagnostic summary. | Fixed in build `2611.27.003`. Remove old `DebugPassword` values from local configs. |
| The display uses `ShowDialog()`. | A direct **Run PowerShell Script** step waits for the form to close and blocks the task sequence. | Use `tools/Start-OSDBackground.cmd` from a **Run Command Line** step. It starts PowerShell as a separate process and returns. | Implemented. Confirm the action returns and the display appears in the target deployment session. |
| The display did not relaunch after a reboot. | The form process ends when the computer restarts. | Add launch steps after each reboot where the display must return. Use the optional specialize launch in `unattend.xml` for the early full Windows phase. | Documented. Validate every reboot boundary in a lab. |
| The display treated 20 failed task sequence polls as successful completion. | A connection loss can result from a failure or restart. Technicians could see a false success state. | Require `TSBackgroundState=Complete` or `TSBackgroundState=Failed`. Keep status unknown when the connection disappears without a signal. | Fixed. Add the success and error groups described in `docs/error-handling.md`. |
| Progress uses the next instruction pointer divided by the instruction table size. | Branches, skipped actions, and variable task durations make this a position indicator, not a measure of work completed. Remaining time can be inaccurate. | Label the percentage as approximate progress. Keep time as an estimate and avoid estimates in configured long steps. | Fixed in build `2611.27.003`; the UI says `APPROXIMATE PROGRESS`. The guide describes remaining time as an estimate. |
| Preview mode reads real local device and network details. | A live preview can expose a hostname, serial number, domain, IP address, or MAC address on a recorded or shared screen. | Use the synthetic static render for demonstrations. A future preview-data option could replace every hardware field with configured sample values. | Documented limit. `render/osd-osdv2-preview.png` uses fake values. |
| The script header and UI showed different version formats. | Operators could report different build identities for one file. | Keep one build identifier in the source header and UI footer. | Fixed in build `2611.27.003`. |
| There is no dedicated external stop action. | A display can remain open after an abnormal exit when no reboot occurs. | Add a tested cleanup step that targets this script path and process session. Never stop all PowerShell processes by name. | Not implemented. Pilot and define the target session before adding cleanup. |

## Task sequence design

The recommended pilot uses an asynchronous command-line launcher, explicit task sequence state, a success group, and an error group. The error group stores the failed action and return code before it runs other handler steps. This follows Microsoft's documented use of `_SMSTSLastActionSucceeded` and Jörgen Nilsson's 2016 OSDBackground example.

The optional early Windows launch uses `RunSynchronousCommand` during specialize. Microsoft documents this command as running in the system context and waiting for completion in that pass. The sample starts a detached process, but this repository has not validated whether the window is visible on each target Windows build. Use the normal post-setup launch if the form is not visible.

OSD-OSD is a foreground display. It does not replace `smsts.log`, the ConfigMgr task sequence progress UI, or an organization-approved recovery process.

## Positive observations

- The v2 UI uses one custom-painted canvas and scales its layout from screen dimensions.
- The script caches its background bitmap and fonts between refreshes.
- The step tracker shows completed, active, and pending phases with separate labels.
- The remaining-time logic suppresses guesses during configured long steps.
- The script logs diagnostics to `%SystemRoot%\Temp\TSBackground-OSD.log` and limits repeated error messages with `Write-LogOnce`.
- The repository preview is a static render with synthetic device data.

## Review limits

This is a static code and documentation review. The PowerShell parser accepted all three PowerShell files. The example JSON parsed. PSScriptAnalyzer reported 45 warnings in the main UI script and no findings in the two helper scripts. The warning groups are empty catch blocks, WMI cmdlets, unapproved internal verbs, assignments to the automatic variable `sender`, an unused visibility variable, and the `Write-Log` function name. No ConfigMgr task sequence, boot image, unattend deployment, reboot flow, or error path has been exercised. Validate these flows in the ConfigMgr lab before production use.
