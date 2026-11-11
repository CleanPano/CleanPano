# Third-party notices

CleanPano is licensed under the GNU General Public License v3.0 (see [LICENSE](LICENSE)).
It uses the components below. Full texts are in [docs/LICENSES.txt](docs/LICENSES.txt) and [docs/licenses/](docs/licenses/).

| Component | Where | License | In this repository? |
|---|---|---|---|
| [three.js](https://threejs.org) r170 | `app/ui/vendor/three.module.min.js` | MIT | Yes |
| [Inter](https://rsms.me/inter) typeface | `app/ui/fonts/` | SIL Open Font License 1.1 | Yes |
| [Microsoft Edge WebView2 SDK](https://www.nuget.org/packages/Microsoft.Web.WebView2) 1.0.3856.49 | `Microsoft.Web.WebView2.*.dll`, `WebView2Loader.dll` | BSD-style license from Microsoft | No. The build script downloads it from NuGet. |
| [NSIS](https://nsis.sourceforge.io) 3 | Installer engine and language files in `build/lang/` (adapted from the NSIS language files) | zlib/libpng (compression modules: bzip2 license and CPL 1.0 with the NSIS exception) | Language files only |
| [7-Zip](https://www.7-zip.org) `7zr.exe` | Downloaded on demand by the app to unpack NVIDIA drivers | GNU LGPL | No |

Drivers are downloaded at run time from the Microsoft Update Catalog and from NVIDIA's website, and remain under their publishers' own licenses. They are not part of CleanPano.

The CleanPano name, the cat logo and the artwork in `art/` and `images/` identify the official project. If you publish a modified version, please use a different name and logo so users can tell them apart.
