# Script review

Review date: 2026-11-27.

## Findings

### High: the debug password is a reusable plaintext secret

`OSD-OSD.ps1` reads `DebugPassword` from JSON. Ctrl+Shift+D opens a command prompt when the entered string matches. The command prompt inherits the script process security context, which is normally Local System when launched by a task sequence. A password in a package is not a reliable access-control boundary. Remove the feature or replace it with a controlled diagnostic mechanism before production use. Do not add a production password to `config.json` or a package.

### High: the modal display blocks a direct task sequence script action

The script ends with `ShowDialog()`. A **Run PowerShell Script** action that calls it directly waits for the display to close. The task sequence cannot progress to completion while that action waits. Start the process asynchronously from a command line action and validate the behavior in a pilot.

### High: the process does not persist across reboots

The script saves a start time and active step in task sequence variables. It does not arrange to start again after a reboot. A reboot ends the process. Add a launch step after every required reboot, or add and validate a separate relaunch mechanism.

### Medium: the progress percentage is not a stable measure of deployment work

The code divides `_SMSTSNextInstructionPointer` by `_SMSTSInstructionTableSize`. Task sequence branching, skipped actions, and other execution paths can make an instruction pointer differ from completed work. Label this as task sequence position or validate its meaning across the supported task sequences before presenting it as a percent-complete estimate.

### Medium: configuration errors can stop UI initialization

The script checks that the JSON file exists but does not validate required keys, color strings, or a non-empty step list. Invalid or incomplete configuration can fail later while building controls. Add schema and value checks before deployment.

### Low: step text and hardware queries have limited defensive handling

The code trusts configured step IDs and names. Duplicate or invalid IDs can replace controls or break the active step logic. Several WMI queries run on a timer or during initialization and only some calls are protected. Validate IDs and isolate failures so a missing hardware field does not interrupt the display.

### Low: the version shown in the window does not match the script header

The script header says `2611.27.001`, while the sidebar displays `v2.6.1`. Keep one version source so technicians can identify the running build.

## Positive observations

- The script keeps ASCII source text and constructs UI symbols from character codes.
- It reads task sequence state through the ConfigMgr `Microsoft.SMS.TSEnvironment` COM object.
- It records diagnostics to `%SystemRoot%\Temp\TSBackground-OSD.log`.
- It uses a named global mutex to avoid a second display instance in the same session.
- It has fallback text when some system data is unavailable.

## Review limits

This was a static review of the source. The Windows Forms application was not run on the dev PC. The SVG preview is a separate static mock with fake data. No ConfigMgr task sequence, Windows PE boot image, reboot flow, or package was exercised. Verify those flows in the ConfigMgr lab before production use.
