# Attribution

OSD-OSD includes code adapted from the TSBackground-SCCM repository. It is separate from the TSBackground and OSDBackground projects discussed in the CCMEXEC articles.

## Code attribution

- [nouakader2006](https://github.com/nouakader2006), [TSBackground-SCCM](https://github.com/nouakader2006/TSBackground-SCCM). Portions of the OSD-OSD display implementation derive from this repository.
- The upstream repository uses the MIT License. Its copyright notice is `Copyright (c) 2026 NouacerAbdelkader`. The upstream copyright and MIT permission notice are included in [LICENSE](../LICENSE).

## Microsoft Learn

Microsoft Learn is the primary source for the ConfigMgr, Windows PE, Windows Setup, task sequence, and PowerShell behavior documented in this repository. The implementation and setup procedures use these Microsoft references:

- [Task sequence variables](https://learn.microsoft.com/intune/configmgr/osd/understand/task-sequence-variables) describes built-in and custom task sequence variables, including action status and log path values.
- [Using task sequence variables](https://learn.microsoft.com/intune/configmgr/osd/understand/using-task-sequence-variables) documents access to task sequence variables through the `Microsoft.SMS.TSEnvironment` object.
- [Operating System Deployment Task Sequences Overview: Detecting a Failed Task Sequence](https://learn.microsoft.com/intune/configmgr/develop/osd/operating-system-deployment-task-sequences-overview#detecting-a-failed-task-sequence) describes the error-handler group pattern using `_SMSTSLastActionSucceeded`.
- [Task sequence steps: Run Command Line](https://learn.microsoft.com/intune/configmgr/osd/understand/task-sequence-steps#run-command-line) documents command execution from a task sequence.
- [Create a package and program](https://learn.microsoft.com/intune/configmgr/apps/deploy-use/packages-and-programs#create-a-package-and-program) documents ConfigMgr package creation.
- [Distribute referenced content](https://learn.microsoft.com/intune/configmgr/osd/deploy-use/distribute-task-sequence-referenced-content) documents task sequence content distribution to distribution points.
- [Manage boot images with Configuration Manager](https://learn.microsoft.com/intune/configmgr/osd/get-started/manage-boot-images) documents boot image optional components, including WinPE-NetFX and WinPE-PowerShell.
- [WinPE: Add packages (Optional Components Reference)](https://learn.microsoft.com/windows-hardware/manufacture/desktop/winpe-add-packages--optional-components-reference?view=windows-11) documents Windows PE optional components and their dependencies.
- [WinPE: Adding Windows PowerShell support to Windows PE](https://learn.microsoft.com/windows-hardware/manufacture/desktop/winpe-adding-powershell-support-to-windows-pe?view=windows-11) documents the required package order for Windows PowerShell support.
- [Get-CimInstance for Windows PowerShell 5.1](https://learn.microsoft.com/powershell/module/cimcmdlets/get-ciminstance?view=powershell-5.1) documents the CIM cmdlet used for local hardware and network queries.
- [RunSynchronousCommand](https://learn.microsoft.com/windows-hardware/customize/desktop/unattend/microsoft-windows-deployment-runsynchronous-runsynchronouscommand) and [RunSynchronous](https://learn.microsoft.com/windows-hardware/customize/desktop/unattend/microsoft-windows-deployment-runsynchronous) document the optional Windows Setup launch method.
- [Apply Operating System Image](https://learn.microsoft.com/intune/configmgr/osd/understand/task-sequence-steps#apply-operating-system-image) documents answer-file selection for operating system deployment.
- [About log files](https://learn.microsoft.com/intune/configmgr/core/plan-design/hierarchy/about-log-files#locating-log-files) documents ConfigMgr log locations.

Each setup guide cites the Microsoft Learn pages related to its procedure. The setup is complete within this repository; administrators do not need an external guide to configure the documented package and task sequence steps.

## Related ConfigMgr guidance

- Jörgen Nilsson, ["Error handling in TS without MDT using OSDBackground"](https://ccmexec.com/2016/12/error-handling-in-ts-without-mdt-using-osdbackground/), December 15, 2016. The post describes a guarded task sequence group, success and error groups, and preserving the failed action return code.
- Johan Schrewelius, ["TSBackground for ConfigMgr"](https://ccmexec.com/2019/06/tsbackground-for-configmgr/), June 12, 2019. The post describes Windows PE startup and an unattend `RunSynchronousCommand` launch. Its byline is "Johan" and its summary credits Johan Schrewelius for TSBackground.
- Johan Arwidmark and Maik Koster, [*Stealing with Pride, Vol. 1: Advanced OSD Customizations for MDT 2013 and ConfigMgr 2012 R2*](https://www.deploymentresearch.com/books/). This project follows the book's practice of reusing deployment knowledge with attribution.

The setup guide links to figures hosted by CCMEXEC.COM. The figures are not stored in this repository. The authors and site retain their rights. Each figure caption links to its source post.
