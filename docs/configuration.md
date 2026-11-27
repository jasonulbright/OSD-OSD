# Configuration reference

OSD-OSD reads JSON from `config.json` beside the script by default. Use `-ConfigFile` to select another JSON filename. Relative filenames resolve from the script folder.

Start from `config.example.json`. Keep organization-specific configuration out of Git.

## Top-level keys

| Key | Type | Purpose |
|---|---|---|
| `CompanyName` | string | Organization name shown when no logo loads. |
| `DepartmentName` | string | Department name shown when no logo loads. |
| `Title` | string | Main display heading. |
| `SubTitle` | string | Supporting text below the heading. |
| `LogoPath` | string | Optional image filename relative to the script folder. |
| `HideSCCMProgress` | boolean | Enables the existing task sequence progress window hiding code. The key keeps its legacy name. |
| `AutoCloseOnCompletion` | boolean | Closes the display after the script detects that the task sequence environment has ended. |
| `DebugPassword` | string | Legacy plaintext password for the Ctrl+Shift+D command prompt. Do not configure this feature on production devices. |
| `Theme` | object | Window, card, text, and step colors. |
| `Steps` | array | Ordered step names and action keyword lists. |

## Theme keys

Colors use HTML hex strings such as `#0F172A`.

| Key | Purpose |
|---|---|
| `Background` | Main window background. |
| `SidebarBackground` | Step tracker background. |
| `CardBackground` | Progress bar track and system information card. |
| `AccentColor` | Main highlight and progress fill. |
| `TextPrimary` | Main text. |
| `TextSecondary` | Supporting text. |
| `StepPendingBg`, `StepPendingText` | Pending step colors. |
| `StepActiveBg`, `StepActiveText` | Active step colors. |
| `StepDoneBg`, `StepDoneText` | Completed step colors. |

## Steps

Each entry has an integer `Id`, a visible `Name`, and `Keywords`. Keep IDs in the order shown. The script orders steps by numeric ID and advances the active indicator when a configured keyword matches `_SMSTSCurrentActionName`.

`Keywords` can be a string separated by `|`, `;`, or `,`, or a JSON array of strings. Matching is case-insensitive and uses substring matching. Use specific phrases to reduce accidental matches. The active step moves forward and does not move backward during one process run.

Example:

```json
{
  "Id": 2,
  "Name": "Operating System Installation",
  "Keywords": "Apply Operating System|Apply Driver|WIM"
}
```

## Data shown by the script

The display reads task sequence values through `Microsoft.SMS.TSEnvironment`. It reads the current action, computer name, next instruction pointer, and instruction table size. It also queries local hardware and network information through WMI.

When no task sequence environment is available, the script displays a preview status. Device values that cannot be read show fallback text such as `Unknown` or `Detecting...`.

## Security

The legacy debug feature compares a typed value with `DebugPassword` in plaintext, then starts `cmd.exe` without alternate credentials. The configuration is not a safe access-control boundary. Do not use a shared password in a deployed package. See [the review](review.md).
