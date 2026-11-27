# Task sequence error handling

This pattern follows the ConfigMgr variable behavior described by Microsoft and the completion and error groups shown by Jörgen Nilsson. It adds explicit state signals for OSD-OSD.

The display must not decide that the deployment succeeded because the task sequence COM object stopped responding. A failure, restart, or cleanup can also end that connection. The display shows **Deployment status unavailable** after a connection loss without a terminal signal. If the connection returns, the display returns to live task sequence data. It reports completion or failure only after it reads `Complete` or `Failed`.

## Task sequence layout

Use this shape. Keep the actual deployment steps inside the guarded group.

```text
Set Task Sequence Variable: TSBackgroundState = Running
Run Command Line: cmd.exe /c Start-OSDBackground.cmd (Start in: tools)
Group: Deployment actions (Continue on error enabled)
    Existing deployment steps
Group: OSD success
    Condition: _SMSTSLastActionSucceeded equals true
    Run PowerShell Script: Set-OSDBackgroundState.ps1 -State Complete
Group: OSD error
    Condition: _SMSTSLastActionSucceeded equals false
    Run PowerShell Script: Set-OSDBackgroundState.ps1 -State Failed
    Optional: collect logs or run approved recovery actions
    Optional: Exit-OSDBackgroundWithOriginalCode.ps1
```

The error group runs after the guarded deployment group. The **Continue on error** setting allows ConfigMgr to reach the handler. Do not apply this setting to unrelated steps or to a group that contains dependent actions after a failure. Review the sequence inside the guarded group so a failed disk, operating system, or security step does not trigger unsafe follow-on work.

The ConfigMgr variable is named `_SMSTSLastActionSucceeded` (note the underscore). Microsoft documentation gives examples that use this variable to run an error group after a group with **Continue on error** enabled. Verify the exact group condition in the task sequence editor.

## Configure each helper step

### Start state

Add a **Set Task Sequence Variable** step before the first display launch. Keep the state as `Running` during interim restarts. Do not send `Complete` before the final required reboot and cleanup actions.

| Field | Value |
|---|---|
| Task Sequence Variable | `TSBackgroundState` |
| Value | `Running` |

This resets a previous state if the task sequence relaunches the display after a reboot.

### Completion group

Add a group after the deployment action group. Set its condition to `_SMSTSLastActionSucceeded` equals `true`. This must be the last action in the successful path. Add a **Run PowerShell Script** step. Select the package that contains the tools folder, set the script name to `tools\Set-OSDBackgroundState.ps1`, and set the parameters to `-State Complete`.

### Error group

Add a group after the completion group. Set its condition to `_SMSTSLastActionSucceeded` equals `false`. Add a **Run PowerShell Script** step as the first action. Select `tools\Set-OSDBackgroundState.ps1` and set the parameters to `-State Failed`. The helper records `_SMSTSLastActionName` and `_SMSTSLastActionRetCode` in `TSBackgroundErrorAction` and `TSBackgroundErrorCode`.

Then add the error actions used by your environment. Examples include copying the task sequence log to an approved support share, showing the local log path, or running an approved recovery tool. Do not add an unprotected command prompt or store a shared debug password in the package.

If your error group must return the original failed action code, add a final **Run PowerShell Script** step that selects `tools\Exit-OSDBackgroundWithOriginalCode.ps1`. First confirm that the code is a decimal integer and that the failure group reaches this step. The helper exits with the saved code so ConfigMgr records the failure.

## Meaning of the display states

| State | Signal | Display behavior |
|---|---|---|
| Running | `TSBackgroundState` is `Running`, or is not set | Shows live task sequence data. |
| Complete | A success group sets `TSBackgroundState` to `Complete` | Shows 100% and closes after the configured delay when `AutoCloseOnCompletion` is true. |
| Failed | An error group sets `TSBackgroundState` to `Failed` | Shows the failed action and return code. It stays open. |
| Unknown | The task sequence connection is lost without a terminal signal | Shows that status is unknown. It does not claim success or close as complete. |

## Operational limits

- The handler runs only if task sequence control reaches it. A power loss or hard reset cannot run the handler.
- An action that cannot be continued may prevent the sequence from reaching the handler. Validate the exact failure behavior in a lab.
- Do not disable the ConfigMgr progress UI until technicians can still identify and recover from a task sequence failure.
- `smsts.log` remains the source for detailed task sequence diagnostics.

## References

- [Microsoft: Detecting a failed task sequence](https://learn.microsoft.com/intune/configmgr/develop/osd/operating-system-deployment-task-sequences-overview#detecting-a-failed-task-sequence)
- [Microsoft: Task sequence variables](https://learn.microsoft.com/intune/configmgr/osd/understand/task-sequence-variables)
- [Jörgen Nilsson: Error handling in TS without MDT using OSDBackground](https://ccmexec.com/2016/12/error-handling-in-ts-without-mdt-using-osdbackground/)
