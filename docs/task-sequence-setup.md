# ConfigMgr task sequence setup

This guide shows a staged rollout for OSD-OSD. It keeps the normal task sequence progress UI enabled until each launch point has passed a pilot.

OSD-OSD is a foreground Windows Forms process. Start it as a separate process so a task sequence action does not wait for the display to close. The included launcher returns control to ConfigMgr after it starts PowerShell.

## Choose a launch plan

| Phase | Launch method | Status |
|---|---|---|
| Windows PE, after the task sequence starts | Run `cmd.exe /c Start-OSDBackground.cmd` from a **Run Command Line** step with **Start in** set to `tools`. Add another launch after every task sequence reboot where the display must return. | Preferred pilot path. WinPE Windows Forms support is not validated. |
| Windows Setup, specialize pass | Stage the package on the installed OS drive before **Setup Windows and ConfigMgr**. Add the sample `RunSynchronousCommand` from [unattend-launch.md](unattend-launch.md) to the answer file. It starts the launcher in a detached process. | Optional early launch. Visibility and session behavior must pass a lab pilot. |
| Full Windows, after **Setup Windows and ConfigMgr** | Use a **Run Command Line** step to call the launcher. | Preferred full OS path. Add a launch after every later reboot where the display must return. |

The 2019 TSBackground article recommends a custom `winpeshl.ini` in the boot image and a `RunSynchronousCommand` in `unattend.xml`. OSD-OSD is a PowerShell WinForms script, not TSBackground. Do not replace ConfigMgr's WinPE shell with a custom `winpeshl.ini` for OSD-OSD unless you have a tested shell configuration that preserves the ConfigMgr launch flow. Use the task-sequence launch step for the first pilot.

## Prepare the package

1. Create a package source folder.
2. Copy `osd-osdv2.ps1` and `config.example.json` to its root.
3. Rename `config.example.json` to `config.json` in the package source.
4. Edit the organization name, branding, support text, theme, and step keywords.
5. Add an approved logo and set `LogoPath` to its filename when needed.
6. Copy the `tools` folder into the package source. Keep `Start-OSDBackground.cmd` in that folder.
7. Remove any `DebugPassword` entry from the local `config.json`. The current script has no password-based command prompt.
8. Create a standard ConfigMgr package from the source folder.
9. Distribute the package to the distribution points used by the task sequence.

Do not put passwords, tokens, or other secrets in `config.json`. Keep the example config in source control. Keep an organization-specific config out of source control unless it contains only approved public values.

## Launch in Windows PE

1. Confirm that the boot image has Windows PowerShell, .NET, and Windows Forms support. The standard ConfigMgr PowerShell component alone does not prove that WinForms is present or works.
2. Add a **Run Command Line** step after the task sequence starts and after any wizard or prerequisite steps that need the normal ConfigMgr UI.
3. Select the OSD-OSD package.
4. Set the command line to:

```text
cmd.exe /c Start-OSDBackground.cmd
```

5. Set **Start in** to `tools`. This path is relative to the package folder. The launcher uses paths relative to its own location.
6. Keep the normal task sequence progress UI enabled during the pilot.
7. Add the same launch step after each reboot in WinPE where technicians need the display again.

The 2019 article's `winpeshl.ini` method can relaunch TSBackground each time WinPE starts. It changes the WinPE shell startup. Treat it as a separate, advanced integration for OSD-OSD and test it with the exact boot image and startup chain before use.

## Launch in full Windows

### Standard launch after Windows setup

1. Add a **Run Command Line** step after **Setup Windows and ConfigMgr**.
2. Select the OSD-OSD package.
3. Set the command line to:

```text
cmd.exe /c Start-OSDBackground.cmd
```
4. Set **Start in** to `tools`.
5. Add another launch step after each later reboot where the display must return.
6. Keep the ConfigMgr progress UI enabled until the pilot confirms that the OSD-OSD window is visible and that the task sequence continues.

### Early launch from unattend.xml

Use the optional method in [unattend-launch.md](unattend-launch.md) when the display must start during Windows Setup. Stage `osd-osdv2.ps1`, `config.json`, and `tools\\Start-OSDBackground.cmd` on the offline Windows volume before **Setup Windows and ConfigMgr**. The sample runs from the installed OS drive during the specialize pass.

`RunSynchronousCommand` runs in the system context during specialize and waits for its command to finish. The sample calls `cmd.exe` with `start` so the launcher can return. Windows Setup may run this process outside the interactive desktop that a technician sees. A lab pilot must confirm display visibility, task sequence variable access, and process lifetime. If the window is not visible, use the standard launch after **Setup Windows and ConfigMgr**.

Do not add a custom `SetupComplete.cmd`. ConfigMgr uses this file to resume the task sequence, and a custom file can prevent the task sequence from continuing.

## Add explicit completion and error signaling

The display does not infer success when the task sequence environment disappears. Add the state steps in [error-handling.md](error-handling.md):

- Set `TSBackgroundState` to `Running` before starting the display.
- Set it to `Complete` in the success path.
- Set it to `Failed` in the error path. Save the failed action name and return code before other error-handler actions run.
- Keep the error path visible for technicians. The display does not close automatically on failure.

The helper scripts are in `tools`. The error handler can save logs or run organization-specific recovery actions. Do not automatically continue dependent deployment actions after a critical failure.

## Pilot checklist

1. Use a disposable device and a test task sequence.
2. Record the ConfigMgr version, boot image version, Windows version, and task sequence revision.
3. Confirm that the launcher returns control to the task sequence.
4. Confirm that the display appears in the technician's visible desktop in each tested phase.
5. Confirm that task sequence variables update the action name and progress display.
6. Force a controlled test failure. Confirm that the display reports failure and stays open.
7. Complete a successful deployment. Confirm that the success group sets the explicit completion state.
8. Test every reboot boundary where the display must return.
9. Confirm that the normal progress UI and `smsts.log` remain available for recovery.
10. Review `TSBackground-OSD.log` under `%SystemRoot%\Temp` and the task sequence log.

Do not hide the ConfigMgr progress window until the display and the error path pass these checks on the target boot image and Windows build.

## Remove or stop the display

The current script has no external stop command. Escape closes the display. Do not stop PowerShell by process name because another task sequence action may use it. A production cleanup action should identify the process by its script path and run only after confirming that the process belongs to this display.

## Source images and attribution

The following images come from the source posts. The image files stay on CCMEXEC.COM. The repository does not copy them.

![Task sequence layout with TSBackground steps marked](https://ccmexec.com/wp-content/uploads/2019/06/Pic07.png)

Figure source: [Johan Schrewelius, “TSBackground for ConfigMgr”](https://ccmexec.com/2019/06/tsbackground-for-configmgr/). The post is published under the byline “Johan” and thanks Johan Schrewelius for creating TSBackground.

![Task sequence error handling groups](https://ccmexec.com/wp-content/uploads/2016/12/TS-error-handling.PNG)

Figure source: [Jörgen Nilsson, “Error handling in TS without MDT using OSDBackground”](https://ccmexec.com/2016/12/error-handling-in-ts-without-mdt-using-osdbackground/).

## Microsoft references

- [Task sequence variables](https://learn.microsoft.com/intune/configmgr/osd/understand/task-sequence-variables)
- [Run PowerShell Script task sequence step](https://learn.microsoft.com/intune/configmgr/osd/understand/task-sequence-steps#run-powershell-script)
- [Run Command Line task sequence step](https://learn.microsoft.com/intune/configmgr/osd/understand/task-sequence-steps#run-command-line)
- [Operating System Deployment Task Sequences Overview: detecting a failed task sequence](https://learn.microsoft.com/intune/configmgr/develop/osd/operating-system-deployment-task-sequences-overview#detecting-a-failed-task-sequence)
- [RunSynchronousCommand](https://learn.microsoft.com/windows-hardware/customize/desktop/unattend/microsoft-windows-deployment-runsynchronous-runsynchronouscommand)
- [ConfigMgr OSD task sequence fails with error code 80070005](https://learn.microsoft.com/troubleshoot/mem/configmgr/os-deployment/osd-task-sequence-fails-error-80070005)
