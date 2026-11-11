---
title: CleanPano Privacy Policy
---

# CleanPano Privacy Policy

Last updated: November 11, 2026

CleanPano is a free, open-source PC cleaner and optimizer for Windows 10 and 11. This policy explains what the app does with data. The source code is public at [github.com/CleanPano/CleanPano](https://github.com/CleanPano/CleanPano), so everything below can be checked.

## Summary

- CleanPano has **no telemetry, no analytics, no ads and no user accounts**.
- The developer does **not collect, sell or share** personal data.
- Cleaning, repair and hardware checks run **locally on your PC**.
- The app connects to the internet **only for the features listed below**, and only when you use them.

## Data stored on your PC

CleanPano keeps these files on your computer only. They are never uploaded.

- **Settings** (language, theme, options, startup programs you chose to keep).
- **Activity log**: a plain-text record of what the app did, in `C:\ProgramData\CleanPano\logs`. You can open it from the Activity panel and delete it at any time.

Uninstalling CleanPano removes the app and its interface settings. Two things are left so that a reinstall keeps your choices: the log folder above and the list of startup programs you chose to keep (registry key `HKLM\SOFTWARE\CleanPano`). You can delete both by hand.

## Internet connections the app makes

Any server you connect to can see your IP address, as with any website. CleanPano sends nothing else unless stated here.

| Feature | Connects to | What is sent | When |
|---|---|---|---|
| Public IP shown on the Network tab | `api.ipify.org` | A plain request; the service replies with your public IP address, which is shown to you and not stored or forwarded | When network details are loaded |
| Ping test | `1.1.1.1` (Cloudflare), `8.8.8.8` and `google.com` (Google) | Standard ping packets | When you run the test |
| Speed test | `speed.cloudflare.com` | A request for a test file | When you run the test |
| Driver updates | Microsoft Update Catalog and Windows Update (Microsoft) | Hardware and driver identifiers needed to find matching drivers | When you optimize or update drivers |
| NVIDIA graphics driver | NVIDIA's website | A request for the latest driver version and its download | When you optimize or update drivers on a PC with an NVIDIA card |
| Driver unpacking tool | `7-zip.org` | A download request for the 7-Zip extractor | Only when an NVIDIA driver needs to be unpacked |
| App updates | winget (Microsoft and the app publishers) | The list of installed apps is checked by winget, a Windows tool, under Microsoft's terms | When you optimize or update apps |
| DNS selector | Cloudflare or Google DNS, if you choose one | Your DNS lookups go to the provider you selected, like with any DNS server | After you change the DNS setting |
| Report a bug or suggestion | Web3Forms (`api.web3forms.com`), which delivers the message to the developer by email | The text you type, your email address **only if you enter it**, the report type, the CleanPano version, your Windows version and build, and the app language | Only when you press Send |

These services are run by third parties and have their own privacy policies.

CleanPano's window uses the Microsoft Edge WebView2 Runtime, a Windows component from Microsoft, to display its interface. The interface is loaded from your own PC, not from the internet.

## Bug reports and suggestions

Reports sent through the form are used only to fix problems and improve CleanPano. They are not sold or shared. If you gave an email address, it is used only to reply to you. To have a report deleted, ask through the same form or open an issue on GitHub.

## Donations

Donations are optional. The app only displays a Bitcoin address and a QR code; it does not send any data when you donate. Bitcoin transactions are public on the blockchain by design.

## Why CleanPano asks for administrator permission

Windows requires administrator rights to create a restore point, delete system temporary files and caches, run Windows repair tools (DISM and SFC), change DNS settings, manage startup programs and install driver and app updates. CleanPano uses the permission only for these tasks.

## Children

CleanPano is a general-purpose utility. It is not directed at children and does not knowingly collect data from anyone.

## Changes

If this policy changes, the new version will be published on this page with a new date. Past versions remain visible in the repository history.

## Contact

Questions about privacy: open an issue at [github.com/CleanPano/CleanPano/issues](https://github.com/CleanPano/CleanPano/issues) or use **Report a bug or suggestion** in the app.

---

## Português (Brasil) — resumo

- O CleanPano **não tem telemetria, análise de uso, anúncios nem conta de usuário**. O desenvolvedor **não coleta, não vende e não compartilha** dados pessoais.
- A limpeza, o reparo e a leitura de hardware rodam **no seu PC**. Configurações e o registro de atividades ficam só no computador.
- O app usa a internet **apenas nos recursos que precisam dela**: mostrar o IP público (ipify), teste de ping e de velocidade (Cloudflare e Google), busca e download de drivers (Microsoft e NVIDIA, com os identificadores de hardware necessários), extrator 7-Zip, atualização de programas pelo winget e o DNS que você escolher.
- **Reportar bug ou sugestão** envia, só quando você clica em Enviar, o texto digitado, seu e-mail (se informado), a versão do app, a versão do Windows e o idioma, pelo serviço Web3Forms.
- **Doações** são opcionais; o app apenas mostra um endereço Bitcoin e não envia dados.
- A **permissão de administrador** é usada só para limpar e reparar o sistema, criar ponto de restauração, mudar o DNS, gerenciar a inicialização e instalar atualizações.

A versão completa, em inglês, está acima e é a que vale em caso de dúvida.

## Español — resumen

- CleanPano **no tiene telemetría, analítica, anuncios ni cuentas de usuario**. El desarrollador **no recopila, no vende y no comparte** datos personales.
- La limpieza, la reparación y la lectura de hardware se ejecutan **en tu PC**. La configuración y el registro de actividad se guardan solo en el equipo.
- La app usa internet **solo en las funciones que lo necesitan**: mostrar la IP pública (ipify), pruebas de ping y de velocidad (Cloudflare y Google), búsqueda y descarga de controladores (Microsoft y NVIDIA, con los identificadores de hardware necesarios), extractor 7-Zip, actualización de programas con winget y el DNS que elijas.
- **Reportar error o sugerencia** envía, solo cuando pulsas Enviar, el texto escrito, tu correo (si lo indicas), la versión de la app, la versión de Windows y el idioma, mediante el servicio Web3Forms.
- **Las donaciones** son opcionales; la app solo muestra una dirección de Bitcoin y no envía datos.
- El **permiso de administrador** se usa solo para limpiar y reparar el sistema, crear un punto de restauración, cambiar el DNS, gestionar el inicio e instalar actualizaciones.

La versión completa, en inglés, está arriba y es la que prevalece en caso de duda.
