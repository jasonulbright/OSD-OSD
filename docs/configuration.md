# Configuration reference

`osd-osdv2.ps1` reads JSON from `config.json` beside the script by default. Use `-ConfigFile` to select another JSON filename. Relative filenames resolve from the script folder.

Start from `config.example.json`. The example includes `PreviewPercent` and `PreviewStep`. These values appear only when the script cannot connect to a task sequence. The script still reads real device and network information in this mode. Use the static preview image for synthetic data.

## Display text

| Key | Type | Purpose |
|---|---|---|
| `CompanyName` | string | Organization name shown beside the built-in brand mark. |
| `DepartmentName` | string | Department text shown below the organization name. The script displays it in uppercase. |
| `Headline` | string | One or two headline lines separated by `|`. |
| `OsName` | string | Operating system label below the headline. |
| `StatusPill` | string | Status text in the pill at the top right. |
| `InfoMessage` | string | Message in the information bar above the footer. |
| `SupportTitle` | string | Support heading in the footer. |
| `SupportText` | string | Support details in the footer. |
| `DomainName` | string | Optional fixed domain name. When empty, the script checks task sequence, domain membership, and DNS data. |
| `LogoPath` | string | Optional image filename relative to the script folder. A valid image replaces the built-in brand mark. |

## Behavior

| Key | Type | Purpose |
|---|---|---|
| `HideSCCMProgress` | boolean | Enables the existing code that hides the standard task sequence progress window. This key keeps its legacy name. |
| `AutoCloseOnCompletion` | boolean | Closes the display after the script detects that the task sequence environment has ended. |
| `NoEstimateSteps` | integer array | Step IDs where the script suppresses its remaining-time estimate. The default is `[2]`. |
| `PreviewPercent` | integer | Percentage shown only when no task sequence is detected. |
| `PreviewStep` | integer | Active step ID shown only when no task sequence is detected. |
| `DebugPassword` | string | Legacy plaintext password for the Ctrl+Shift+D command prompt. Do not configure this feature on production devices. |

The script starts the task sequence display with `PreviewPercent` and `PreviewStep` when no task sequence is detected. It does not replace the hardware and network values with synthetic values.

## Theme

Colors use HTML hex strings such as `#0B1220`.

| Key | Purpose |
|---|---|
| `Background` | Base background color. |
| `CardBackground` | Card background color. |
| `TextPrimary` | Main text color. |
| `TextSecondary` | Supporting text color. |
| `AccentColor` | Active and highlighted elements. |
| `SuccessColor` | Completed elements. |

The script uses built-in fallback colors when a theme value is empty or invalid.

## Steps

Each entry has an integer `Id`, `Name`, and `Keywords` value. The optional fields are `ShortName`, `TimelineName`, `Description`, `DoneText`, and `StatusText`.

The top segmented bar uses `ShortName` when set. Otherwise it uses `Name`. The sidebar uses the first non-empty value from `TimelineName`, `ShortName`, and `Name`.

`Keywords` can be a string separated by `|`, `;`, or `,`, or an array of strings. Matching is case-insensitive and uses substring matching against `_SMSTSCurrentActionName`. The active step moves forward and the script saves its ID in `TSBackgroundCurrentStep`.

## Data displayed

The script reads task sequence variables through `Microsoft.SMS.TSEnvironment`. It reads the current action, computer name, next instruction pointer, and instruction table size. It also queries local hardware and network information through WMI.

The overall percentage is calculated from the next instruction pointer and instruction table size. It is a position indicator. It may not represent the amount of work remaining in a task sequence with branches or skipped actions.

## Security

The legacy debug feature compares a typed value with `DebugPassword` in plaintext. It then starts `cmd.exe` without alternate credentials. The command prompt uses the script process security context. The configuration is not a safe access-control boundary. Do not put a shared password in a deployed package. See [the review](review.md).
