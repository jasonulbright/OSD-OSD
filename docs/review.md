# Script review

Review date: 2026-11-27.

The review covers `osd-osdv2.ps1` version 2611.27.002 and the version 3.0.0 UI shown in the file.

## Findings

### High: the debug password is a reusable plaintext secret

Ctrl+Shift+D prompts for `DebugPassword`. If the input matches the JSON value, the script starts `cmd.exe` in the script process security context. A task sequence commonly runs with Local System rights. A password in a package is not a reliable access-control boundary. Remove the feature or replace it with a controlled diagnostic mechanism before production use. The example config does not include a password.

### High: the modal display blocks a direct task sequence script action

The script ends with `ShowDialog()`. A **Run PowerShell Script** action that calls it directly waits for the display to close. The task sequence cannot progress while that action waits. Start the process asynchronously from a command line action and validate the behavior in a pilot.

### High: the process does not relaunch itself after a reboot

The script saves a start time and active step in task sequence variables. It does not arrange to start again after a reboot. A reboot ends the process. Add a launch step after every required reboot, or add and validate a separate relaunch mechanism.

### Medium: percentage and remaining-time values can mislead technicians

The code divides `_SMSTSNextInstructionPointer` by `_SMSTSInstructionTableSize`. Branches and skipped actions can make this value differ from completed work. The remaining-time estimate uses the change in percentage over elapsed time. Deployment speed can change. Keep the percentage as a position indicator and present the remaining-time value as an estimate.

### Medium: the example preview uses real machine details when run

`PreviewPercent` and `PreviewStep` set progress values when no task sequence is detected. The script still reads the current machine's serial number, model, BIOS, domain, IP address, and MAC address. The static image in `render/` uses fake values. Do not use the live script on a shared or recorded screen for a fake-data demonstration.

### Low: the file and UI show different version formats

The script header says `2611.27.002`. The footer shows `$AppVersion`, which is `3.0.0`. Keep one build identifier or show both labels clearly.

## Positive observations

- The v2 UI uses one custom-painted canvas and scales its layout from the screen dimensions.
- The code caches its background bitmap and fonts instead of rebuilding them every refresh.
- The step tracker shows completed, active, and pending phases with separate labels and descriptions.
- The remaining-time logic suppresses guesses during configured long steps.
- The script logs diagnostics to `%SystemRoot%\Temp\TSBackground-OSD.log` and limits repeated error messages with `Write-LogOnce`.
- The example config omits `DebugPassword`.

## Review limits

This was a static review. PSScriptAnalyzer with the shared settings reported warnings for unapproved internal verbs, legacy WMI cmdlets, empty catch blocks, the automatic variable `sender`, and the `WasVisible` assignment. It reported no errors. The Windows Forms application was not run on the dev PC. The SVG preview is a separate static render with synthetic values. No ConfigMgr task sequence, Windows PE boot image, reboot flow, or package was exercised. Verify those flows in the ConfigMgr lab before production use.
