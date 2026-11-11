# Contributing to CleanPano

Thanks for helping. CleanPano is free software (GPLv3), with no ads, no telemetry and no paid features, and contributions must keep it that way.

## Reporting a bug or an idea

- Open an [issue](https://github.com/CleanPano/CleanPano/issues), or use **Report a bug or suggestion** in the app footer.
- For bugs, include the CleanPano version, your Windows version and what the **Activity** panel or the log shows.
- Security problems: see [SECURITY.md](SECURITY.md). Do not open a public issue.

## How the project is organised

| Folder | What it is |
|---|---|
| `app/CleanPano.ps1` | The engine: a PowerShell 5.1 script that runs the tasks and serves the interface on `127.0.0.1` |
| `app/ui/` | The interface (HTML, CSS, JavaScript). Texts for the 20 languages are in `js/i18n.js` and `js/lang.js` |
| `launcher/launcher.cs` | The window: a small C# WinForms program that hosts the interface in WebView2 |
| `build/` | Build scripts and the NSIS installer script |
| `art/` | Logo, icon and installer artwork |

## Building

See **Build from source** in the [README](README.md).

## Pull requests

- One change per pull request, with a short description of what it does and how you tested it.
- Test on Windows 10 or 11 (64-bit). Say which one you used.
- A new or changed text must be added for all 20 languages (English is fine as a placeholder; say so in the pull request).
- Do not add analytics, ads, accounts, network calls that are not needed for a feature, or binaries (`.exe`, `.dll`).
- By contributing you agree that your contribution is licensed under GPLv3.
