# OSD-OSD

OSD-OSD means On Screen Display of Operating System Deployments. It is a Windows PowerShell display for ConfigMgr operating system task sequences. It shows task sequence activity, an overall progress bar, device details, elapsed time, and configurable deployment steps.

The display is intended for on-site technicians. It is not a replacement for `smsts.log` or the ConfigMgr task sequence progress UI.

## Current status

The repository contains the original script, an example configuration, operator documentation, and a static mock render with fake device data. The mock render does not run the script.

Review findings are in [docs/review.md](docs/review.md). The task sequence setup guide is in [docs/task-sequence-setup.md](docs/task-sequence-setup.md). Configuration keys are in [docs/configuration.md](docs/configuration.md).

## Preview

![OSD-OSD mock render with illustrative data](render/osd-osd-preview.png)

The preview uses fake data. It does not contain a real hostname, serial number, IP address, or deployment log.

## Requirements

- Windows PowerShell 5.1.
- Windows Forms and System.Drawing support in the phase where the display runs.
- A ConfigMgr task sequence when live task sequence variables are required.
- A ConfigMgr package that contains the script and the selected JSON configuration.

The existing script catches a missing task sequence COM object and shows a preview message. The live UI still uses Windows Forms and WMI calls. Windows PE support depends on the boot image components and has not been validated in this repository.

## Quick start

1. Copy `config.example.json` to `config.json`.
2. Set the organization name, department, title, subtitle, colors, and step keywords in `config.json`.
3. Optionally place an organization logo beside the script and set `LogoPath` to its filename.
4. Run `OSD-OSD.ps1` in an approved Windows test environment.
5. Follow [the task sequence setup guide](docs/task-sequence-setup.md) to package and launch it.

Do not commit `config.json`. It is ignored because it can contain organization-specific data and the current script can use a debug password from that file. The sample does not include a debug password.

## Files

| Path | Purpose |
|---|---|
| `OSD-OSD.ps1` | Windows Forms task sequence display. |
| `config.example.json` | Safe starter configuration. |
| `docs/task-sequence-setup.md` | ConfigMgr package and task sequence steps. |
| `docs/configuration.md` | Configuration key reference and keyword behavior. |
| `docs/review.md` | Review findings and known limits. |
| `render/osd-osd-preview.svg` | Static sample render with fake data. |

## Task sequence state

The script stores `TSBackgroundStartTime` and `TSBackgroundCurrentStep` through `Microsoft.SMS.TSEnvironment`. Those values preserve data only while the task sequence environment is available. The script does not install a startup task or relaunch itself after a reboot. See [the setup guide](docs/task-sequence-setup.md) and [the review](docs/review.md) before deployment.

## License

No license has been selected. Do not redistribute this project until the owner adds a license.
