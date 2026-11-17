# Notes for certification (paste into Partner Center)

CleanPano is a free, open-source PC cleaner (GPLv3, source: https://github.com/CleanPano/CleanPano). No account, no ads, no telemetry, no in-app purchases. No login or demo account is needed.

**Why it asks for administrator rights (allowElevation):** cleaning Windows temp folders, the Windows Update cache, system logs, creating a restore point, flushing DNS and running DISM all require elevation. Without it the app cannot do its main job. The user sees the normal Windows UAC prompt and can cancel.

**Every system change is chosen by the user:**
- The "Optimize now" screen lists every step before it runs. Restore point, DNS, graphics driver and driver updates each have an on/off switch.
- Startup apps: only the apps the user unticks are disabled, using the same StartupApproved registry values that Task Manager uses. They can be turned back on in the app or in Task Manager.
- Optional start-with-Windows task: created only if the user turns it on, and removed on uninstall.
- NVIDIA driver: downloaded only from nvidia.com, only on PCs with an NVIDIA card, and only if that step is on.
- 7-Zip: the official 7zr.exe extractor is downloaded from 7-zip.org into the app's temp folder only to unpack the NVIDIA driver. It is not installed on the system.

**Local engine:** the UI talks to the app's own engine on 127.0.0.1. The engine accepts requests only from the app's window (host, origin and a private header are checked) and is never reachable from other machines.

**Data:** nothing is collected or sent anywhere. The optional "Report a bug" button sends only the message the user types plus the app version, Windows version and UI language, and only when the user clicks Send. Privacy policy: https://cleanpano.github.io/CleanPano/privacy-policy (also linked in the app footer).

**Requirements:** Windows 10/11, PowerShell (built in). Windows in S mode is not supported; the app shows a clear message there.

**Testing:** open the app, review the step list, click "Optimize now". The Cleaning, Network, Drivers and System tabs can each be used on their own.
