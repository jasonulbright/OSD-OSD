# ConfigMgr task sequence setup

This guide has the full setup procedure for OSD-OSD. You do not need a third-party guide to create the package or add the task sequence steps. The links at the end are optional source material.

OSD-OSD is a foreground Windows Forms display. Its launcher starts a separate PowerShell process and returns control to the task sequence. Keep the ConfigMgr progress window enabled until the pilot passes.

## Deployment plan

| Phase | Setup | Status |
|---|---|---|
| Windows PE | Add a **Run Command Line** step after the task sequence starts. | Optional pilot. Windows PE PowerShell components do not prove that Windows Forms is available. Test the exact boot image. |
| Windows Setup, specialize pass | Stage the package on the target volume. Add the sample command to `unattend.xml`. | Optional pilot. The process may not appear in the technician's desktop. |
| Full Windows | Add a **Run Command Line** step after **Setup Windows and ConfigMgr**. | Preferred first deployment. |

Add another launch step after each restart where technicians need the display again. A restart closes the current display process. The task sequence state is held in task sequence variables and is available when the launcher starts again.

The 2019 TSBackground article uses `winpeshl.ini` and `RunSynchronousCommand`. OSD-OSD is a PowerShell WinForms script. Do not replace the ConfigMgr Windows PE shell for the first OSD-OSD pilot. Use the task sequence launch step. Treat a custom shell as a separate integration that needs its own boot-image test.

## 1. Prepare the source folder

Create a source folder that the site server can read. For example:

```text
\\CM01\Sources$\OSD-OSD
```

Copy these files into it:

```text
OSD-OSD\
|-- osd-osdv2.ps1
|-- config.json
`-- tools\
    |-- Start-OSDBackground.cmd
    |-- Set-OSDBackgroundState.ps1
    `-- Exit-OSDBackgroundWithOriginalCode.ps1
```

Create `config.json` from `config.example.json`. Set the company name, department, support details, colors, logo, and step keywords. Put a logo file in the package root if you use one. Set `LogoPath` to its filename. Keep `config.example.json` in the repository as the clean starting point.

Remove old `DebugPassword` values from local configurations. The display does not use a password or start a command prompt. Do not put credentials, tokens, or passwords in this package.

Grant the site server computer account read access to the source folder and its files. The distribution point does not read the source share directly. The site server imports package content into the content library.

## 2. Create the ConfigMgr package

1. Open the ConfigMgr console.
2. Go to **Software Library** > **Application Management** > **Packages**.
3. On the **Home** ribbon, select **Create Package**.
4. Enter a name such as `OSD-OSD Background Display`.
5. Enter a description such as `Task sequence deployment display`.
6. Select **This package contains source files**.
7. Select **Browse** and choose the source folder from step 1.
8. Do not create a program. The task sequence uses the package as content.
9. Finish the wizard.

If your console requires a program page, choose **Do not create a program**. The task sequence **Run Command Line** step calls the package files directly.

## 3. Distribute the package

1. In **Packages**, select the OSD-OSD package.
2. On the **Home** ribbon, select **Distribute Content**.
3. Confirm that the OSD-OSD package is listed, then select **Next**.
4. On **Content Destination**, select **Add**.
5. Select **Distribution Point** or **Distribution Point Group**.
6. Select every distribution destination used by the target devices, then select **OK**.
7. Finish the wizard.
8. Open **Monitoring** > **Distribution Status** > **Content Status**.
9. Select the OSD-OSD package and confirm that distribution reports success for each required distribution point.

When you change a package file, update the package source and select **Update Distribution Points**. Wait for content status to report success before testing the task sequence.

## 4. Optional: prepare the boot image for Windows PE

The task sequence launcher requires Windows PowerShell. The task sequence state helpers also use Windows PowerShell if the task sequence can fail in Windows PE. OSD-OSD uses [`Get-CimInstance`](https://learn.microsoft.com/powershell/module/cimcmdlets/get-ciminstance?view=powershell-5.1) for local hardware and network queries. Microsoft lists [WinPE-WMI](https://learn.microsoft.com/windows-hardware/manufacture/desktop/winpe-add-packages--optional-components-reference?view=windows-11) as a prerequisite for WinPE-PowerShell. The script does not use CIM remoting; it queries the local system. These components do not prove that the display's Windows Forms UI can run in that boot image. Treat the Windows PE display launch as an optional pilot and confirm that the CIM cmdlets are available in the exact customized boot image.

1. Go to **Software Library** > **Operating Systems** > **Boot Images**.
2. Select the boot image used by the task sequence, then open **Properties**.
3. Open **Optional Components**.
4. Add **WinPE-NetFX**.
5. Add **WinPE-PowerShell**.
6. Select **Apply** and close the properties.
7. Right-click the boot image and select **Update Distribution Points**.
8. Wait for the boot image content status to report success at each required distribution point.
9. Update the task sequence to use this boot image revision, if needed.

Do not select **Reload this boot image with the current Windows PE version** as a routine update. Reloading can remove customizations that are not managed by ConfigMgr. Record the boot image version and test this exact image on a disposable device. If Windows Forms is not visible and stable, omit the Windows PE launch and start the display in full Windows.

## 5. Add the Windows PE launch step (optional)

1. Go to **Software Library** > **Operating Systems** > **Task Sequences**.
2. Right-click the deployment task sequence and select **Edit**.
3. Select the step after which the display should start. Put it after the task sequence starts and after any wizard or prerequisite steps that need the normal ConfigMgr UI.
4. Select **Add** > **General** > **Run Command Line**.
5. Enter a name such as `Start OSD-OSD in Windows PE`.
6. Set **Command line** to:

```text
cmd.exe /c Start-OSDBackground.cmd
```

7. Select **Package**, then select the OSD-OSD package.
8. Set **Start in** to `tools`.
9. On the **Options** tab, add a task sequence variable condition: `_SMSTSInWinPE` equals `true`.
10. Select **OK**, then save the task sequence.

The **Start in** value is relative to the package folder. Do not enter a drive letter or a distribution point path.

## 6. Add the full Windows launch step

1. In the task sequence editor, find **Setup Windows and ConfigMgr**.
2. Add a **Run Command Line** step after this step, when the task sequence resumes in full Windows.
3. Enter a name such as `Start OSD-OSD in full Windows`.
4. Set **Command line** to:

```text
cmd.exe /c Start-OSDBackground.cmd
```

5. Select the OSD-OSD package.
6. Set **Start in** to `tools`.
7. On the **Options** tab, add a task sequence variable condition: `_SMSTSInWinPE` equals `false`.
8. Select **OK**, then save the task sequence.

Place the step at the first point after **Setup Windows and ConfigMgr** where the task sequence can run package commands. Add another copy after each later restart where the display must return. Set a condition on each step if the task sequence has more than one operating system path.

## 7. Add display state and failure handling

The task sequence must send an explicit state when it starts, completes, or fails. Follow [Task sequence error handling](error-handling.md) to add these steps:

- Set `TSBackgroundState` to `Running` before the first launch.
- Add an error-handler group directly after the deployment action group.
- Set `TSBackgroundState` to `Failed` as the first action in the error group.
- Add a success group after the error group. Set `TSBackgroundState` to `Complete` only after all required deployment and restart steps finish.
- Keep the error screen open for the technician. Do not hide the standard ConfigMgr progress window until the pilot passes.

The error helper stores `_SMSTSLastActionName` and `_SMSTSLastActionRetCode` in OSD-OSD variables. Add `Exit-OSDBackgroundWithOriginalCode.ps1` as the last step of the error group only when the task sequence must return the failed action's original code.

## 8. Optional: start during Windows Setup

Use the specialize-pass method only when the display must appear before the normal full Windows launch step. Follow [Early full Windows launch with unattend.xml](unattend-launch.md). Stage the package on the target Windows volume before **Setup Windows and ConfigMgr**. Add the sample `Microsoft-Windows-Deployment` component to the answer file used by **Apply Operating System Image**.

`RunSynchronousCommand` runs in the system context and waits for its command to finish. The sample starts a separate process so setup can continue. It does not prove that the form appears in the technician's interactive session. OSD-OSD allows only one process across Windows sessions. Confirm that the early process is visible or exits before a later launch step. If it remains open in an invisible session, it can block that later launch. Confirm visibility, task sequence variable access, and process lifetime in the lab. If these checks fail, remove this method and use the full Windows launch step.

Do not add a custom `SetupComplete.cmd`. ConfigMgr uses that file to resume the task sequence. A custom file can prevent the task sequence from continuing.

## 9. Pilot and monitor

Use a disposable device and a test task sequence. Record the ConfigMgr version, boot image version, Windows version, and task sequence revision.

1. Confirm package content is distributed to the correct distribution points.
2. Confirm the command step returns to the task sequence without waiting for the display to close.
3. Confirm the display appears in the intended technician session.
4. Confirm task sequence variables update the current action and progress display.
5. Confirm the display returns after every required restart.
6. Trigger a controlled task sequence failure. Confirm the display shows the failed action and code, remains open, and preserves the original code if that helper is enabled.
7. Complete a successful deployment. Confirm the success group sends the `Complete` state.
8. Confirm `smsts.log` and the normal ConfigMgr progress UI remain available for recovery.
9. Review `%SystemRoot%\Temp\osd-osd.log` and `smsts.log`.

The task sequence log moves during deployment. Use the read-only task sequence variable `%_SMSTSLogPath%` to find its current location. Common locations are:

| Phase | Common path |
|---|---|
| Windows PE before **Format and Partition Disk** | `X:\Windows\Temp\smstslog\smsts.log` |
| Windows PE after **Format and Partition Disk** | `X:\smstslog\smsts.log` |
| New Windows before the ConfigMgr client is installed | `C:\_SMSTaskSequence\Logs\smstslog\smsts.log` |
| Windows after the ConfigMgr client is installed | `C:\Windows\CCM\Logs\smstslog\smsts.log` |
| After the task sequence completes | `C:\Windows\CCM\Logs\smsts.log` |

Do not disable the normal progress UI until the display, restart behavior, and error path pass this pilot on the target boot image and Windows build.

## Stop or close the display

Escape closes the OSD-OSD window. The repository does not include an external stop action. Do not stop PowerShell by process name. If your deployment needs automatic cleanup, identify and validate the exact process and session in the lab before you add a cleanup step.

## Optional references and attribution

These references provide history and source examples. The steps above are complete without them.

- [Microsoft: Create a package and program](https://learn.microsoft.com/intune/configmgr/apps/deploy-use/packages-and-programs#create-a-package-and-program)
- [Microsoft: Manage boot images](https://learn.microsoft.com/intune/configmgr/osd/get-started/manage-boot-images)
- [Microsoft: Run Command Line task sequence step](https://learn.microsoft.com/intune/configmgr/osd/understand/task-sequence-steps#run-command-line)
- [Microsoft: Distribute content](https://learn.microsoft.com/intune/configmgr/core/servers/deploy/configure/deploy-and-manage-content#distribute-content)
- [Microsoft: Detect a failed task sequence](https://learn.microsoft.com/intune/configmgr/develop/osd/operating-system-deployment-task-sequences-overview#detecting-a-failed-task-sequence)
- [Microsoft: About log files and task sequence log paths](https://learn.microsoft.com/intune/configmgr/core/plan-design/hierarchy/about-log-files#locating-log-files)
- [Johan Schrewelius: TSBackground for ConfigMgr](https://ccmexec.com/2019/06/tsbackground-for-configmgr/)
- [Jörgen Nilsson: Error handling in TS without MDT using OSDBackground](https://ccmexec.com/2016/12/error-handling-in-ts-without-mdt-using-osdbackground/)

The figures below are optional source images. The setup procedure does not depend on them.

![Task sequence layout with TSBackground steps marked](https://ccmexec.com/wp-content/uploads/2019/06/Pic07.png)

Figure source: [Johan Schrewelius, “TSBackground for ConfigMgr”](https://ccmexec.com/2019/06/tsbackground-for-configmgr/). The post is published under the byline “Johan” and thanks Johan Schrewelius for creating TSBackground.

![Task sequence error handling groups](https://ccmexec.com/wp-content/uploads/2016/12/TS-error-handling.PNG)

Figure source: [Jörgen Nilsson, “Error handling in TS without MDT using OSDBackground”](https://ccmexec.com/2016/12/error-handling-in-ts-without-mdt-using-osdbackground/).
