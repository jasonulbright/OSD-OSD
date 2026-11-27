# Task sequence setup

This guide describes how to add OSD-OSD to a ConfigMgr operating system deployment task sequence. Validate the launch flow on a test collection before production use.

## Before you start

- Use a test task sequence and test device.
- Confirm that the display can run in each phase where you need it.
- Use a package source folder with `OSD-OSD.ps1`, `config.json`, and an optional logo file.
- Keep `config.json` in the package source. Do not put credentials in it.
- Distribute the package to every distribution point used by the deployment.

The task sequence `Run PowerShell Script` action waits for the script to finish. OSD-OSD shows a modal Windows Forms window until the user closes it or the task sequence is detected as complete. Start the UI from an asynchronous launcher so the task sequence can continue. The example below uses `cmd.exe` and `start` to return from the action while PowerShell owns the display. Confirm this behavior on your ConfigMgr version and boot image.

## Prepare the package

1. Create a source folder, for example `OSD-OSD`.
2. Copy `OSD-OSD.ps1` into the folder.
3. Copy `config.example.json` into the folder as `config.json`.
4. Edit the organization text, theme, steps, and keywords in `config.json`.
5. Copy an approved logo into the folder if you use one.
6. Set `LogoPath` to the logo filename.
7. Create a standard ConfigMgr package from this source folder.
8. Distribute the package to the required distribution points.

The package does not need a program. The task sequence command line references its files.

## Add an asynchronous launch step

1. Open the task sequence in the ConfigMgr console.
2. Add a **Run Command Line** step at the point where the display should start.
3. Select the OSD-OSD package.
4. Set **Command line** to:

```text
cmd.exe /c start "" "%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe" -NoProfile -ExecutionPolicy Bypass -File "OSD-OSD.ps1" -ConfigFile "config.json"
```

5. Set **Start in** to the package folder if the console offers that field for the action.
6. Keep **Disable this step** clear.
7. Do not select **Continue on error** until the launch behavior is validated.
8. Save the task sequence.

The command uses the package working directory to find both files. If your ConfigMgr action runs from another directory, use the full package path in `-File` and configure `LogoPath` accordingly.

## Place the launch step

Add a launch step after the device enters a phase that supports the display. Add another launch step after each reboot where the display must return. The current script does not relaunch itself after a reboot.

If you want a display during Windows PE, first confirm that the boot image has the required PowerShell, .NET, and Windows Forms support. A script that starts in full Windows does not prove that it can start in Windows PE.

Do not rely on this display as the only progress signal. Keep the ConfigMgr task sequence progress window enabled during the pilot until you confirm how the custom display behaves in WinPE and full Windows.

## Pilot checklist

1. Run a test deployment on a disposable device.
2. Confirm that the task sequence advances after the launch step returns.
3. Confirm that the display appears in the correct interactive desktop.
4. Confirm that the displayed computer name, task name, elapsed time, and progress values update.
5. Confirm that the display closes when the task sequence ends, if `AutoCloseOnCompletion` is enabled.
6. Confirm that the display returns after each reboot where you added a launch step.
7. Review `TSBackground-OSD.log` under `%SystemRoot%\Temp` and `smsts.log` for errors.
8. Record the tested ConfigMgr version, boot image, Windows version, and task sequence launch position.

## Remove the display

The pilot should include a tested stop step or cleanup action for any display process that remains after an abnormal task sequence exit. The current script has no dedicated external stop command. Do not terminate unrelated PowerShell processes by name. Identify the OSD-OSD process by its command line or process id in a controlled cleanup script.

## Microsoft references

- [Task sequence steps: Run PowerShell Script](https://learn.microsoft.com/intune/configmgr/osd/understand/task-sequence-steps#run-powershell-script)
- [How to use task sequence variables](https://learn.microsoft.com/intune/configmgr/osd/understand/using-task-sequence-variables)
- [How to use variables in a running task sequence](https://learn.microsoft.com/intune/configmgr/develop/osd/how-to-use-task-sequence-variables-in-a-running-task-sequence)
