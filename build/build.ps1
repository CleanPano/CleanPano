# Builds CleanPano.exe and the installer on Windows.
# Requires: .NET Framework 4.8 (ships with Windows) and NSIS 3 (https://nsis.sourceforge.io).
# Usage: powershell -ExecutionPolicy RemoteSigned -File build\build.ps1      Output: dist\CleanPano-Setup.exe
$ErrorActionPreference = 'Stop'
$root = Split-Path $PSScriptRoot -Parent
Set-Location $root

# 1) WebView2 SDK (not kept in the repository): fixed version from NuGet, checked by SHA-256
$wv2 = '1.0.3856.49'
$dlls = 'Microsoft.Web.WebView2.Core.dll', 'Microsoft.Web.WebView2.WinForms.dll', 'WebView2Loader.dll'
if ($dlls | Where-Object { -not (Test-Path "app\$_") }) {
    $tmp = Join-Path $env:TEMP "wv2-$wv2"
    New-Item -ItemType Directory -Force $tmp | Out-Null
    Invoke-WebRequest "https://api.nuget.org/v3-flatcontainer/microsoft.web.webview2/$wv2/microsoft.web.webview2.$wv2.nupkg" -OutFile "$tmp\wv2.zip" -UseBasicParsing
    Expand-Archive "$tmp\wv2.zip" "$tmp\x" -Force
    Copy-Item "$tmp\x\lib\net462\Microsoft.Web.WebView2.Core.dll", "$tmp\x\lib\net462\Microsoft.Web.WebView2.WinForms.dll", "$tmp\x\runtimes\win-x64\native\WebView2Loader.dll" app\
    Remove-Item $tmp -Recurse -Force
}
foreach ($line in Get-Content build\webview2.sha256) {
    $h, $f = $line -split '\s+', 2
    if ((Get-FileHash $f -Algorithm SHA256).Hash -ne $h) { throw "SHA-256 mismatch: $f" }
}

# 2) launcher
$fx = Join-Path $env:WINDIR 'Microsoft.NET\Framework64\v4.0.30319'
& "$fx\csc.exe" /nologo /target:winexe /platform:anycpu /win32icon:art\CleanPano.ico `
    /r:"$fx\System.Windows.Forms.dll" /r:"$fx\System.Drawing.dll" /r:"$fx\System.Management.dll" `
    /r:app\Microsoft.Web.WebView2.Core.dll /r:app\Microsoft.Web.WebView2.WinForms.dll `
    /out:app\CleanPano.exe launcher\launcher.cs
if ($LASTEXITCODE) { throw 'Launcher build failed' }

$nsis = @("${env:ProgramFiles(x86)}\NSIS\makensis.exe", "$env:ProgramFiles\NSIS\makensis.exe") | Where-Object { Test-Path $_ } | Select-Object -First 1
if (-not $nsis) { Write-Host 'NSIS not found: CleanPano.exe was built, the installer was not.'; exit }

# 3) optional: key of the "Report a bug or suggestion" form (build\feedback.key, not in the repository)
$html = 'app\ui\index.html'
$orig = [IO.File]::ReadAllText((Resolve-Path $html))
try {
    if (Test-Path build\feedback.key) {
        $k = (Get-Content build\feedback.key -Raw).Trim()
        [IO.File]::WriteAllText((Resolve-Path $html), $orig.Replace("feedbackKey:''", "feedbackKey:'$k'"), (New-Object Text.UTF8Encoding $false))
    }
    # 4) installer
    New-Item -ItemType Directory -Force dist | Out-Null
    & $nsis /V2 build\installer.nsi
} finally { [IO.File]::WriteAllText((Resolve-Path $html), $orig, (New-Object Text.UTF8Encoding $false)) }
Write-Host 'Done: dist\CleanPano-Setup.exe'
