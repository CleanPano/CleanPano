<p align="center">
  <img src="images/logo.png" width="96" alt="CleanPano logo">
</p>

<h1 align="center">CleanPano</h1>

<p align="center">
  <b>Free PC cleaning and optimization for Windows, in one click.</b><br>
  Windows 10 and 11 (64-bit)
</p>

<p align="center">
  <a href="LICENSE"><img src="https://img.shields.io/badge/license-GPLv3-blue.svg" alt="License: GPL v3"></a>
</p>

<p align="center">
  <a href="https://github.com/CleanPano/CleanPano/releases/latest/download/CleanPano-Setup.exe"><b>⬇ Download CleanPano-Setup.exe</b></a>
  &nbsp;·&nbsp;
  <a href="https://github.com/CleanPano/CleanPano/releases">All versions</a>
  &nbsp;·&nbsp;
  <a href="https://x.com/CleanPano">Follow on X</a>
</p>

https://github.com/user-attachments/assets/aef2b0a6-ce59-44b8-8c04-bde85c22d87f

<p align="center">
  <img src="images/home-light.png" width="49%" alt="CleanPano home screen, light theme">
  <img src="images/home-dark.png" width="49%" alt="CleanPano home screen, dark theme">
</p>

---

## English

### What it does

Press **Optimize now** and CleanPano runs everything in order:

- Creates a restore point before touching the system
- Cleans temporary files, error logs and dumps
- Clears Chrome, Edge and Firefox caches
- Empties Windows caches (update, thumbnails, shaders) and the Recycle Bin
- Sets DNS back to automatic and flushes the DNS and ARP caches
- Checks for a newer graphics driver (NVIDIA from the official site)
- Updates other drivers from the Microsoft Update Catalog
- Updates installed programs through winget
- Runs the Windows component cleanup (DISM)

There is also:

- **Performance:** turn off third-party programs that start with Windows, and repair Windows (DISM + SFC)
- **Network:** IP and network details, ping and speed tests, switch DNS between Cloudflare, Google and automatic
- **System:** hardware details for enthusiasts, such as dual channel memory and CPU overclock compared with factory specs
- **PC health score**, light and dark themes, 20 languages, and an option to optimize automatically when Windows starts

<p align="center">
  <img src="images/optimizing.png" width="49%" alt="CleanPano while optimizing">
  <img src="images/system.png" width="49%" alt="CleanPano system and hardware page">
</p>

### How to install

1. Download **CleanPano-Setup.exe** from the link above.
2. Open the file.
3. Windows may show a blue **"Windows protected your PC"** notice. It appears for every new app that is not in the Microsoft Store yet, and it is not a virus alert. Click **More info** and then **Run anyway**. CleanPano is free, with no ads and no telemetry.
4. Click **Yes** when Windows asks for administrator permission.
5. Choose your language and follow the screens until **Finish**.

To remove: Windows Settings > Apps > CleanPano > Uninstall.

### Open source

CleanPano is free software under the [GNU GPL v3](LICENSE). The whole program is in this repository: the engine (`app/CleanPano.ps1`), the interface (`app/ui/`), the window (`launcher/launcher.cs`) and the installer script (`build/installer.nsi`). No ads, no telemetry, no account, no paid version. Third-party components are listed in [THIRD-PARTY-NOTICES.md](THIRD-PARTY-NOTICES.md).

### Build from source

The build produces `dist/CleanPano-Setup.exe`. The WebView2 SDK is downloaded from NuGet by the build script (fixed version, checked by SHA-256).

**Linux (Debian/Ubuntu)**

```bash
sudo apt install mono-devel mono-mcs nsis curl unzip
git clone https://github.com/CleanPano/CleanPano.git
cd CleanPano
bash build/build.sh
```

**Windows 10/11**

Needs [NSIS 3](https://nsis.sourceforge.io) installed. The C# compiler used is the one that ships with Windows (.NET Framework 4.8).

```powershell
git clone https://github.com/CleanPano/CleanPano.git
cd CleanPano
powershell -ExecutionPolicy RemoteSigned -File build\build.ps1
```

To run the app you need Windows 10 or 11 (64-bit) with the Microsoft Edge WebView2 Runtime, which Windows 11 already includes.

A build from source hides the **Report a bug or suggestion** button, because the key of the official form is not in the repository. Everything else is identical to the official release.

### Contributing

Bug reports, ideas and pull requests are welcome. See [CONTRIBUTING.md](CONTRIBUTING.md). For security problems, see [SECURITY.md](SECURITY.md).

### Feedback and support

Found a problem or have an idea? Open an [issue](https://github.com/CleanPano/CleanPano/issues) or use **Report a bug or suggestion** in the app footer.

News and updates: [@CleanPano on X](https://x.com/CleanPano).

### Support the project

CleanPano is free and stays free. Donations are optional:

- **GitHub Sponsors:** use the **Sponsor** button at the top of this page.
- **Bitcoin (BTC, Native SegWit):** `bc1qnkpm79xsymwn0w6gyq7hthrhd247r9pcysqs2w` (also shown in the app under **Support the project**). Send only Bitcoin to this address.

---

## Español

**Limpieza y optimización de PC para Windows, gratis y en un clic.** Para Windows 10 y 11 (64 bits).

1. Descarga **CleanPano-Setup.exe** con el enlace de arriba y ábrelo.
2. Windows puede mostrar el aviso azul "Windows protegió su PC". Aparece con toda app nueva que aún no está en Microsoft Store y no es una alerta de virus. Haz clic en **Más información** y luego en **Ejecutar de todas formas**. CleanPano es gratis, sin anuncios y sin telemetría.
3. Acepta el permiso de administrador, elige el idioma y sigue las pantallas.

Después, abre CleanPano y haz clic en **Optimizar ahora**. Para errores o ideas, usa **Reportar error o sugerencia** en el pie de la app.

**Código abierto:** CleanPano es software libre bajo la licencia [GNU GPL v3](LICENSE). Para compilarlo o contribuir, consulta las secciones *Build from source* y *Contributing* de arriba.

---

## Português (Brasil)

**Limpeza e otimização de PC para Windows, grátis e em um clique.** Para Windows 10 e 11 (64 bits).

1. Baixe o **CleanPano-Setup.exe** pelo link no topo e abra o arquivo.
2. O Windows pode mostrar o aviso azul "O Windows protegeu o computador". Ele aparece para todo app novo que ainda não está na Microsoft Store e não é alerta de vírus. Clique em **Mais informações** e depois em **Executar assim mesmo**. O CleanPano é gratuito, sem anúncios e sem telemetria.
3. Aceite a permissão de administrador, escolha o idioma e siga as telas.

Depois, abra o CleanPano e clique em **Otimizar agora**. Para bugs ou ideias, use **Reportar bug ou sugestão** no rodapé do app.

**Código aberto:** o CleanPano é software livre sob a licença [GNU GPL v3](LICENSE). Para compilar ou contribuir, veja as seções *Build from source* e *Contributing* acima.
