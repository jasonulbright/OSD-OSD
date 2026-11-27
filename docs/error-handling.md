# Task sequence error handling

This guide adds explicit success and failure signals to OSD-OSD. It also shows how to keep the original task sequence failure code.

Do not treat a lost connection to the task sequence environment as success. A restart, a failure, or task sequence cleanup can end that connection. OSD-OSD reports success or failure only after it reads `TSBackgroundState` as `Complete` or `Failed`.

## Required task sequence layout

Use this order. Put the error-handler group directly after the deployment action group.

```text
Set Task Sequence Variable: TSBackgroundState = Running
Run Command Line: cmd.exe /c Start-OSDBackground.cmd (Start in: tools)
Group: Deployment actions (Continue on error enabled)
    Existing deployment steps
Group: OSD error handler
    Condition: _SMSTSLastActionSucceeded equals false
    Run Command Line: powershell.exe -NoProfile -ExecutionPolicy Bypass -File Set-OSDBackgroundState.ps1 -State Failed (Start in: tools)
    Optional: collect logs or run approved recovery actions
    Optional final step: powershell.exe -NoProfile -ExecutionPolicy Bypass -File Exit-OSDBackgroundWithOriginalCode.ps1 (Start in: tools)
Group: OSD success handler
    Conditions: _SMSTSLastActionSucceeded equals true AND TSBackgroundState equals Running
    Run Command Line: powershell.exe -NoProfile -ExecutionPolicy Bypass -File Set-OSDBackgroundState.ps1 -State Complete (Start in: tools)
```

Set **Continue on error** on the deployment wrapper group. Leave it cleared on the child deployment steps unless a specific step needs its own error behavior. When a child step fails, ConfigMgr skips the remaining child steps in that wrapper group and proceeds to the next sibling group. The error group then checks the failed group result. Do not put dependent deployment steps after a failure in a group that is configured to continue.

The error group must be first after the deployment group. The success handler follows it. If the deployment group succeeds, the error group condition is false. The success handler then sees the successful result and the `Running` state. If the deployment group fails, the error handler sets the state to `Failed`. This state check prevents the success handler from running after the error handler's own steps succeed. The optional exit helper returns the saved nonzero code and ends the task sequence with that failure.

Do not set **Continue on error** on the error handler's final exit helper. The failure code must stop the sequence.

## Set the running state

Add a **Set Task Sequence Variable** step before the first OSD-OSD launch.

| Field | Value |
|---|---|
| Task Sequence Variable | `TSBackgroundState` |
| Value | `Running` |

Keep this state during interim restarts. Add the OSD-OSD launch step after each restart where the technician needs the display again. Do not set `Complete` until the last required deployment and cleanup step finishes.

## Configure the error handler

1. Add a group directly after the `Deployment actions` group.
2. Name it `OSD error handler`.
3. On the group's **Options** tab, add the task sequence variable condition `_SMSTSLastActionSucceeded` equals `false`.
4. Add a **Run Command Line** step as the first action in the group.
5. Set the command line to:

```text
powershell.exe -NoProfile -ExecutionPolicy Bypass -File Set-OSDBackgroundState.ps1 -State Failed
```

6. Select the package that contains the OSD-OSD tools.
7. Set **Start in** to `tools`.
8. Add approved log collection or recovery actions after the state step.

The helper saves `_SMSTSLastActionName` in `TSBackgroundErrorAction` and `_SMSTSLastActionRetCode` in `TSBackgroundErrorCode`. OSD-OSD reads these values to show the failed action and return code.

To preserve the original failure code, add a final **Run Command Line** step to this group. Set the command line to:

```text
powershell.exe -NoProfile -ExecutionPolicy Bypass -File Exit-OSDBackgroundWithOriginalCode.ps1
```

Select the OSD-OSD package and set **Start in** to `tools`. The helper returns the saved nonzero code. Test this behavior with a controlled failure before production use.

Do not add an unprotected command prompt. Do not store a shared debug password in the package.

## Configure the success handler

1. Add a group after `OSD error handler`.
2. Name it `OSD success handler`.
3. On the group's **Options** tab, add the task sequence variable condition `_SMSTSLastActionSucceeded` equals `true`.
4. Add a second condition: task sequence variable `TSBackgroundState` equals `Running`.
5. Set the condition logic to **If all conditions are true**.
6. Add a **Run Command Line** step.
7. Set the command line to:

```text
powershell.exe -NoProfile -ExecutionPolicy Bypass -File Set-OSDBackgroundState.ps1 -State Complete
```

8. Select the OSD-OSD package.
9. Set **Start in** to `tools`.

Place this group after every step that can fail and after the last required restart. A later failure must not follow a `Complete` state.

## State behavior

| State | Task sequence signal | Display behavior |
|---|---|---|
| Running | `TSBackgroundState` is `Running` or is not set. | Shows live task sequence data. |
| Complete | The success group sets `TSBackgroundState` to `Complete`. | Shows 100 percent and closes after the configured delay when `AutoCloseOnCompletion` is true. |
| Failed | The error group sets `TSBackgroundState` to `Failed`. | Shows the failed action and code. The window stays open. |
| Unknown | The task sequence connection is lost without a terminal state. | Shows that status is unavailable. It does not claim success or close as complete. |

## Operating limits

- A hard power loss cannot run the error handler.
- The task sequence must reach the error handler for it to run.
- Keep the ConfigMgr progress UI enabled until technicians have a tested recovery path.
- `smsts.log` remains the detailed record for task sequence actions.
- The error and success paths need a lab test. A static review cannot prove task sequence condition behavior or returned exit codes.

## Optional references

The procedure above is complete without these links.

- [Microsoft: Detecting a failed task sequence](https://learn.microsoft.com/intune/configmgr/develop/osd/operating-system-deployment-task-sequences-overview#detecting-a-failed-task-sequence)
- [Microsoft: Task sequence variables](https://learn.microsoft.com/intune/configmgr/osd/understand/task-sequence-variables)
- [Jörgen Nilsson: Error handling in TS without MDT using OSDBackground](https://ccmexec.com/2016/12/error-handling-in-ts-without-mdt-using-osdbackground/)
