# Change log

## v2611.27.004 - 2026-11-27

### Display

- Show task sequence activity, approximate progress, device details, elapsed time, and deployment status.
- Use explicit task sequence signals for completion and failure; show unknown when connection is lost.
- Query local hardware and network information with `Get-CimInstance`.
- Align the status indicator with the installation step timeline.
- Keep diagnostics read-only and write to `osd-osd.log`.
- Clear all 45 shared PSScriptAnalyzer findings in the display script.

### Task sequence support

- Add an asynchronous launcher and helpers for state signaling and original failure codes.
- Document complete package setup, boot image support, launch steps, error handling, and optional unattend launch.

### Documentation and preview

- Add configuration and attribution guides with synthetic Signal Ridge Labs preview data.
- License the repository under the MIT License.
- Document GitHub's generated source ZIP as the release archive; no installer is provided.
