<#
.SYNOPSIS
    Reports task sequence state to the OSD-OSD display.
.DESCRIPTION
    Use at the end of the successful deployment path or at the start of the
    task sequence error path. The display reads these task sequence variables.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [ValidateSet('Running', 'Complete', 'Failed')]
    [string]$State
)

$ErrorActionPreference = 'Stop'

try {
    $TaskSequence = New-Object -ComObject Microsoft.SMS.TSEnvironment
    $TaskSequence.Value('TSBackgroundState') = $State

    if ($State -eq 'Failed') {
        $TaskSequence.Value('TSBackgroundErrorAction') = [string]$TaskSequence.Value('_SMSTSLastActionName')
        $TaskSequence.Value('TSBackgroundErrorCode') = [string]$TaskSequence.Value('_SMSTSLastActionRetCode')
    } elseif ($State -eq 'Running') {
        $TaskSequence.Value('TSBackgroundErrorAction') = ''
        $TaskSequence.Value('TSBackgroundErrorCode') = ''
    }

    exit 0
} catch {
    Write-Error "Could not update OSD-OSD task sequence state: $($_.Exception.Message)"
    exit 1
}
