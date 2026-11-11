#!/bin/bash
# Builds CleanPano.exe and the installer on Linux (mono-mcs + nsis).
# Usage: bash build/build.sh      Output: dist/CleanPano-Setup.exe
set -e
cd "$(dirname "$0")/.."

# 1) WebView2 SDK (not kept in the repository): fixed version from NuGet, checked by SHA-256
WV2=1.0.3856.49
need=0
for f in Microsoft.Web.WebView2.Core.dll Microsoft.Web.WebView2.WinForms.dll WebView2Loader.dll; do [ -f "app/$f" ] || need=1; done
if [ $need = 1 ]; then
  tmp=$(mktemp -d)
  curl -fsSL -o "$tmp/wv2.zip" "https://api.nuget.org/v3-flatcontainer/microsoft.web.webview2/$WV2/microsoft.web.webview2.$WV2.nupkg"
  unzip -q -j "$tmp/wv2.zip" "lib/net462/Microsoft.Web.WebView2.Core.dll" "lib/net462/Microsoft.Web.WebView2.WinForms.dll" "runtimes/win-x64/native/WebView2Loader.dll" -d app
  rm -rf "$tmp"
fi
sha256sum -c build/webview2.sha256

# 2) launcher
A=/usr/lib/mono/4.8-api
mcs -nostdlib -noconfig -target:winexe -platform:anycpu -win32icon:art/CleanPano.ico \
  -r:$A/mscorlib.dll -r:$A/System.dll -r:$A/System.Core.dll -r:$A/System.Windows.Forms.dll -r:$A/System.Drawing.dll -r:$A/System.Management.dll \
  -r:app/Microsoft.Web.WebView2.Core.dll -r:app/Microsoft.Web.WebView2.WinForms.dll \
  -out:app/CleanPano.exe launcher/launcher.cs

# 3) optional: key of the "Report a bug or suggestion" form (build/feedback.key, not in the repository).
#    Without the file the button stays hidden.
H=app/ui/index.html
if [ -f build/feedback.key ]; then
  cp "$H" "$H.orig"; trap 'mv -f "$H.orig" "$H"' EXIT
  K=$(tr -d ' \r\n' < build/feedback.key)
  sed -i "s/feedbackKey:''/feedbackKey:'$K'/" "$H"
fi

# 4) installer
mkdir -p dist
makensis -V2 build/installer.nsi
ls -la dist
