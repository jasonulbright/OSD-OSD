# Implementation review

This page records the current task sequence design and the checks required before production use. ConfigMgr deployment behavior has not been validated in a lab.

## Current behavior

- OSD-OSD is a foreground Windows Forms display. `tools/Start-OSDBackground.cmd` starts a separate PowerShell process and returns control to the task sequence.
- The progress percentage is approximate. Task sequence branches, conditions, and variable step durations can make the instruction pointer differ from work completed.
- The display reads task sequence variables through `Microsoft.SMS.TSEnvironment`. It queries local device and network data with `Get-CimInstance`.
- `TSBackgroundState` controls terminal status. `Complete` and `Failed` are explicit signals. Loss of the task sequence connection without a terminal signal displays an unknown status.
- A restart closes the display process. Add a launch step after each restart where technicians need the display.
- The static preview uses synthetic Signal Ridge Labs data and `contoso.com`. Live preview mode reads the actual device and network values.
- Ctrl+Shift+D opens read-only diagnostics. The script writes diagnostics to `%SystemRoot%\Temp\osd-osd.log`.
- Escape closes the display. The package does not include an external stop action.

## Task sequence design

Use the asynchronous command-line launcher. Set `TSBackgroundState` to `Running` before launch. Place the deployment actions in a wrapper group with **Continue on error** enabled. Put the error handler directly after that group, then put the success handler after the error handler. The success handler checks both `_SMSTSLastActionSucceeded=true` and `TSBackgroundState=Running` before setting `Complete`. The error handler sets `Failed` before optional log collection or recovery. Its optional final helper returns the original failure code.

Microsoft documents the `_SMSTSLastActionSucceeded` pattern in [Detecting a failed task sequence](https://learn.microsoft.com/intune/configmgr/develop/osd/operating-system-deployment-task-sequences-overview#detecting-a-failed-task-sequence). See [task-sequence-setup.md](task-sequence-setup.md) and [error-handling.md](error-handling.md) for the complete procedure.

The normal launch point is after **Setup Windows and ConfigMgr**. The optional Windows PE launch requires the customized boot image to provide Windows PowerShell and its dependencies. The optional specialize-pass launch uses `RunSynchronousCommand` and starts a detached process. Its visibility in the technician's session is unverified. See [unattend-launch.md](unattend-launch.md).

OSD-OSD does not replace `smsts.log`, the ConfigMgr task sequence progress UI, or an approved recovery process. Keep the standard progress UI enabled until the deployment pilot passes.

## Lab validation required

- In the exact customized Windows PE boot image, confirm Windows PowerShell, `Get-CimInstance`, and the display UI work. Windows PowerShell support alone does not prove Windows Forms can run in that image.
- In full Windows, confirm the launcher returns to the task sequence and the display appears in the technician's session.
- Confirm the display launches after each required restart and reconnects to the active task sequence.
- Trigger a controlled failure. Confirm the error group runs, the display shows the failed action and code, and the optional exit helper returns the original nonzero code.
- Complete a successful deployment. Confirm the success group sets `TSBackgroundState=Complete` and the display follows `AutoCloseOnCompletion`.
- Test the optional specialize-pass launch separately. Confirm the window is visible, does not block Windows Setup, and does not prevent a later display launch.
- Confirm `osd-osd.log` and `smsts.log` remain available for support.
