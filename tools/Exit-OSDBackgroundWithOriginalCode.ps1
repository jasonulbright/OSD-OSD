<#
.SYNOPSIS
    Ends the task sequence with the error code saved by Set-OSDBackgroundState.ps1.
.DESCRIPTION
    Place this as the last action in the task sequence error path when the
    original failed action return code must remain the task sequence result.
#>
$ErrorActionPreference = 'Stop'

try {
    $TaskSequence = New-Object -ComObject Microsoft.SMS.TSEnvironment
    $ReturnCode = [string]$TaskSequence.Value('TSBackgroundErrorCode')
    [int]$ParsedCode = 0
    [uint32]$UnsignedCode = 0
    $Parsed = [int]::TryParse($ReturnCode, [ref]$ParsedCode)

    if (-not $Parsed) {
        $HexCode = $ReturnCode -replace '^0[xX]', ''
        if ($ReturnCode -match '^0[xX]' -and [uint32]::TryParse($HexCode, [System.Globalization.NumberStyles]::HexNumber, [Globalization.CultureInfo]::InvariantCulture, [ref]$UnsignedCode)) {
            $ParsedCode = [BitConverter]::ToInt32([BitConverter]::GetBytes($UnsignedCode), 0)
            $Parsed = $true
        } elseif ([uint32]::TryParse($ReturnCode, [ref]$UnsignedCode)) {
            $ParsedCode = [BitConverter]::ToInt32([BitConverter]::GetBytes($UnsignedCode), 0)
            $Parsed = $true
        }
    }

    if (-not $Parsed -or $ParsedCode -eq 0) {
        Write-Error "The saved OSD-OSD failure code is missing or invalid: '$ReturnCode'."
        exit 1
    }

    exit $ParsedCode
} catch {
    Write-Error "Could not restore the task sequence failure code: $($_.Exception.Message)"
    exit 1
}
