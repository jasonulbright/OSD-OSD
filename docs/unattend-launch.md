# Early full Windows launch with unattend.xml

Use this method when technicians need OSD-OSD during Windows Setup, before the task sequence reaches the normal post-setup launch step.

The pattern is based on Johan Schrewelius's TSBackground setup article. The sample here starts OSD-OSD from the local Windows drive. It does not copy TSBackground files or replace ConfigMgr boot image shell files.

## Stage the files

Before **Setup Windows and ConfigMgr**, copy these files to the offline Windows volume:

```text
%OSDTargetSystemDrive%\OSD-OSD\osd-osdv2.ps1
%OSDTargetSystemDrive%\OSD-OSD\config.json
%OSDTargetSystemDrive%\OSD-OSD\tools\Start-OSDBackground.cmd
```

Use a **Run Command Line** step after **Apply Operating System** to copy the package content into this location. Select the OSD-OSD package, set **Start in** to `.`, and run:

```text
cmd.exe /c xcopy . "%OSDTargetSystemDrive%\OSD-OSD" /E /I /Y
```

Confirm that the files exist on the target volume before setup begins. Replace any stale deployment config with the current approved config.

## Add the specialize command

Merge this component into the `unattend.xml` used by **Setup Windows and ConfigMgr**. In the **Apply Operating System Image** step, select **Use an unattended or sysprep answer file for a custom installation** and select the package and answer file path. Do not replace the full answer file with this fragment. Set `Order` to a value that does not conflict with other specialize commands. Set the processor architecture to match the deployed image.

The **Apply Windows Settings** step can overwrite answer file values that it manages. Review those settings when you merge the component into the answer file supplied by **Apply Operating System Image**. Do not let the standard `%SystemDrive%` token get resolved in Windows PE. ConfigMgr replaces `%OSDTargetSystemDrive%` in the answer file with the target OS drive letter.

```xml
<settings pass="specialize">
  <component name="Microsoft-Windows-Deployment"
             processorArchitecture="amd64"
             publicKeyToken="31bf3856ad364e35"
             language="neutral"
             versionScope="nonSxS"
             xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State"
             xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
    <RunSynchronous>
      <RunSynchronousCommand wcm:action="add">
        <Description>Start OSD-OSD display</Description>
        <Order>50</Order>
        <Path>cmd.exe /c start "OSD-OSD" "%OSDTargetSystemDrive%\OSD-OSD\tools\Start-OSDBackground.cmd"</Path>
        <WillReboot>Never</WillReboot>
      </RunSynchronousCommand>
    </RunSynchronous>
  </component>
</settings>
```

The `Path` command starts a separate process so the command can return to Windows Setup. `RunSynchronousCommand` itself runs in the system context during specialize and waits for the command to exit. This does not prove that the form appears in the technician's interactive desktop. Check the process session and visible window during the lab pilot.

If the display is not visible, remove this unattend entry and use the task-sequence launch step after **Setup Windows and ConfigMgr**. Do not use a custom `SetupComplete.cmd`; ConfigMgr uses that file to resume the task sequence.

## Validate the answer file merge

1. Use a test task sequence and a disposable device.
2. Check the answer file that ConfigMgr applies during deployment. Confirm that the `Microsoft-Windows-Deployment` component remains present after task sequence processing.
3. Check `%SystemRoot%\Panther\UnattendGC\setupact.log` for the specialize command.
4. Confirm the OSD-OSD process runs from `%OSDTargetSystemDrive%\OSD-OSD` on the deployed OS volume.
5. Confirm the window is visible to the technician.
6. Confirm that the task sequence continues into its ConfigMgr client setup actions.
7. Confirm the OSD-OSD display attaches to task sequence variables after the task sequence starts.
8. Confirm explicit `Complete` and `Failed` signals work as described in [error-handling.md](error-handling.md).

## References

- [Microsoft: RunSynchronousCommand](https://learn.microsoft.com/windows-hardware/customize/desktop/unattend/microsoft-windows-deployment-runsynchronous-runsynchronouscommand)
- [Microsoft: RunSynchronous](https://learn.microsoft.com/windows-hardware/customize/desktop/unattend/microsoft-windows-deployment-runsynchronous)
- [Microsoft: ConfigMgr OSD task sequence fails with error code 80070005](https://learn.microsoft.com/troubleshoot/mem/configmgr/os-deployment/osd-task-sequence-fails-error-80070005)
- [Microsoft: Apply Operating System Image task sequence step](https://learn.microsoft.com/intune/configmgr/osd/understand/task-sequence-steps#apply-operating-system-image)
- [Microsoft: Run Command Line task sequence step](https://learn.microsoft.com/intune/configmgr/osd/understand/task-sequence-steps#run-command-line)
- [Johan Schrewelius: TSBackground for ConfigMgr](https://ccmexec.com/2019/06/tsbackground-for-configmgr/)
