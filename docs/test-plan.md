# Test plan

This plan defines the tests that OSD-OSD must pass before production use. Most of the tests are automated. A Hyper-V lab can run the full ConfigMgr deployment. A short test on physical hardware covers the items that a virtual machine cannot show.

## Test levels

| Level | Scope | Where it runs | Automated |
|---|---|---|---|
| L0 | Parse, PSScriptAnalyzer, configuration file checks | GitHub Actions, Windows runner | Yes |
| L1 | Display state logic and helper scripts with a fake task sequence environment | GitHub Actions | Yes |
| L2 | One rendered frame for each state and screen size | GitHub Actions | Yes |
| L3 | Full operating system deployment of a virtual machine | Hyper-V lab with ConfigMgr | Yes, after setup |
| L4 | One deployment on physical hardware with the production boot image | Production site | No |

## Risks to test first

These items come from a code and procedure review. No test has run yet.

| Id | Risk | Basis | Test |
|---|---|---|---|
| R1 | The display can be invisible in full Windows. The setup guide names this launch point as the preferred one. | Windows services run in [session 0](https://learn.microsoft.com/windows/win32/services/interactive-services), and a service window is not visible to the console user. Microsoft states that a [Run Command Line](https://learn.microsoft.com/intune/configmgr/osd/understand/task-sequence-steps#run-command-line) command should not interact with the desktop. The expected failure is an inference until L3 shows it. | S1. The `START` line in `osd-osd.log` records the session number. A console capture shows what the technician sees. |
| R2 | If the display cannot read the task sequence environment, it shows sample progress as if a deployment runs. | `config.example.json` sets `PreviewPercent` and `PreviewStep`. The script uses them when it never connects, and it keeps the running status text. | L1 |
| R3 | The display can miss the `Complete` state. | The display reads the state one time each second. The success step is the last step, and the environment ends after it. | S1, repeated |
| R4 | A failed deployment can report success to ConfigMgr. | The error group handles the failure. The helper that returns the original exit code is optional in the setup guide. | S2 and S3 |
| R5 | The Windows PE log is lost at the restart. | The log is in `%SystemRoot%\Temp`. In Windows PE, that folder is on the RAM disk. | S1 |
| R6 | The open display can keep package files in use. | The process runs from the package folder. It also keeps the logo file open. | S1, `smsts.log` |
| R7 | Writes from the separate display process can fail to persist. The timer and step position depend on them. | Microsoft documents [variable access from a command-line step](https://learn.microsoft.com/intune/configmgr/develop/osd/how-to-use-task-sequence-variables-in-a-running-task-sequence). The display continues after that step returns. | S1, timer and step position after each restart |

If R1 fails, change the launch method before you run the other L3 scenarios. Do not use `ServiceUI.exe` from Microsoft Deployment Toolkit. [Microsoft Deployment Toolkit is retired](https://learn.microsoft.com/troubleshoot/mem/configmgr/mdt/mdt-retirement).

## L0 to L2

L1 and L2 need two small changes to `osd-osd.ps1`:

- Put all task sequence reads and writes behind one function that a test can replace.
- Add a switch that draws one frame to a PNG file and then exits.

L1 covers these cases:

- Keyword matching. The step position only moves forward.
- `Running`, `Complete`, `Failed`, and a lost connection.
- A change from `Failed` or `Complete` back to `Running`.
- The restore of the start time and step position after a restart.
- No task sequence environment (R2).
- Missing, partial, and invalid configuration files.
- `Set-OSDBackgroundState.ps1` for each state.
- `Exit-OSDBackgroundWithOriginalCode.ps1` with decimal, hexadecimal, unsigned, zero, empty, and text values.
- The three exit codes of `Start-OSDBackground.cmd`.

L2 draws the running, complete, failed, and unknown states at 1024x768, 1280x1024, 1920x1080, 2560x1440, and 3840x2160. It includes long organization names, long step names, a wide logo, and a configuration with eight steps. The test fails if a draw section writes an error to the log. A person or an agent reviews the images for overlap and cut text.

## L3 lab setup

| Item | Setup |
|---|---|
| Test virtual machine | Generation 2, Secure Boot, virtual TPM, static MAC address, new empty virtual disk for each run, 4 GB of memory |
| Network | An internal virtual switch. A DHCP server on that switch only. |
| Network boot | The [PXE responder without Windows Deployment Services](https://learn.microsoft.com/intune/configmgr/core/servers/deploy/configure/install-and-configure-distribution-points#configure-a-distribution-point) on the distribution point |
| Boot image | A test copy with WinPE-WMI, WinPE-NetFX, WinPE-Scripting, and WinPE-PowerShell, in the [documented order](https://learn.microsoft.com/windows-hardware/manufacture/desktop/winpe-add-packages--optional-components-reference). Command support (F8) on. |
| Task sequence | A test copy that includes the steps in [task-sequence-setup.md](task-sequence-setup.md) and [error-handling.md](error-handling.md), and at least two restarts |
| Deployment | A required deployment to a collection that contains only the test virtual machine |
| Scenario selection | A collection variable that selects the controlled failure, so that one task sequence runs all scenarios |

### One automated run

1. Delete the old virtual disk and attach a new one. Do not use checkpoints.
2. Set the scenario variable.
3. Run [Clear-CMPxeDeployment](https://learn.microsoft.com/powershell/module/configurationmanager/clear-cmpxedeployment) for the test collection.
4. Start the virtual machine.
5. On the Hyper-V host, save a console image at a fixed interval with [GetVirtualSystemThumbnailImage](https://learn.microsoft.com/windows/win32/hyperv_v2/getvirtualsystemthumbnailimage-msvm-virtualsystemmanagementservice). This method needs no software in the guest.
6. Send keys with [Msvm_Keyboard](https://learn.microsoft.com/windows/win32/hyperv_v2/msvm-keyboard) for the Escape and Ctrl+Shift+D tests.
7. Add task sequence steps that copy `osd-osd.log` and `smsts.log` to a lab share before each restart, at the end, and in the error group.
8. Read the step results and exit codes from ConfigMgr.
9. Compare the results with the pass criteria. Write one report with the console images.

## L3 scenarios

| Id | Scenario | Pass criteria |
|---|---|---|
| S1 | Successful deployment with launch steps in Windows PE and full Windows | Console images show the display in each phase with a launch step. The task sequence does not wait for the display. The timer and step position continue after each restart. The display shows `Complete` and then closes. ConfigMgr reports success. |
| S2 | Controlled failure in Windows PE, with the exit code helper | The display shows the failed step and code and stays open. ConfigMgr reports the same code. |
| S3 | Controlled failure in full Windows, with the exit code helper | Same as S2 |
| S4 | `HideSCCMProgress` set to `true` | The standard progress window does not cover the display. The failure result stays visible to the technician. |
| S5 | `AutoCloseOnCompletion` set to `false` | The display stays open after `Complete`. |
| S6 | Escape and Ctrl+Shift+D | Diagnostics open and close. Escape closes the display. The deployment continues. |
| S7 | Early launch from `unattend.xml` | The display is visible or its process exits. A later launch step still opens the display. Setup continues. |
| S8 | Network adapter disconnected and connected during a download | The display stays responsive and shows no false completion. |

S7 applies only if you keep the early launch method. If it fails, remove the method from the documentation.

## L4 physical hardware

Run one successful deployment and one controlled failure. Use the production boot image and a copy of the production task sequence. Use one device for each screen type in your hardware fleet.

- The display is readable at the native screen size and scale in Windows PE and full Windows.
- The keywords match the step names in the production task sequence.
- The model, serial number, BIOS version, and network values are correct.
- The display returns after each restart, including restarts for drivers, firmware, or BitLocker.
- `Ctrl+Shift+D`, Escape, and the F8 support process work on the physical keyboard.

## Done criteria

1. L0, L1, and L2 pass in GitHub Actions on the release commit.
2. R1 to R7 each have a recorded result. Each confirmed defect is fixed, or the documentation states the limit.
3. S1 passes five times in a row. R3 depends on timing, so one pass is not enough.
4. S2 to S8 each pass one time on the release commit.
5. L4 passes on the production site.
6. [review.md](review.md) states what was tested, with the ConfigMgr, boot image, and Windows versions.

After a later change, run L0 to L2 and S1. Also run the L3 scenarios that cover the changed code.
