# Change log

## Unreleased

- Replace legacy PowerShell WMI cmdlets with local `Get-CimInstance` queries. Remove all shared PSScriptAnalyzer findings from the display script.
- Replace the older interface with the updated v2 display.
- Add v2 configuration, task sequence setup guidance, and a fake-data preview.
- Add asynchronous launch and unattend launch guidance with helper scripts.
- Add explicit task sequence success and failure states.
- Replace the shared debug password and command prompt with read-only diagnostics.
- Keep task sequence connection loss in an unknown state instead of reporting false success.
- Label the task sequence position value as approximate progress.
- Rename the diagnostic log to `osd-osd.log` and list remaining review work.
- Add source attributions and linked CCMEXEC figures.
- Align the deployment status dot with the sidebar timeline markers and refresh the synthetic preview with Signal Ridge Labs and `contoso.com` data.
- Expand the task sequence guide with package creation, content distribution, boot image setup, launch steps, conditions, and pilot checks.
- Correct the success and error group order and document helper command lines.
- State that third-party setup references are optional; the repository guides contain the complete setup procedure.
