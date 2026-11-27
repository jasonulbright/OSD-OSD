# Change log

## v2611.27.004

### Display

- Show running, complete, failed, and unknown task sequence states.
- Present approximate progress, device details, elapsed time, and installation steps.
- Query local device and network details with `Get-CimInstance`.
- Align the status indicator with the installation step timeline.
- Write diagnostic entries to `osd-osd.log`.

### Task sequence setup

- Start the display asynchronously while the task sequence continues.
- Preserve the original failure code after error handling when enabled.
- Document package, distribution, boot image, reboot, and unattend setup.

### Documentation

- Include synthetic Signal Ridge Labs preview data.
- Credit Microsoft Learn and related ConfigMgr guidance.
- License the source under MIT.
