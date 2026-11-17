# COMPLIANCE — CleanPano

Plataforma: **Windows / Microsoft Store** (MSIX). Tipo: utilitário de sistema (limpeza e otimização), roda como administrador.
Recursos: sem login, sem pagamento (doação BTC só exibida), sem anúncios, sem analytics, sem IA. Mercado: global, 20 idiomas.
Base: Microsoft Store Policies v7.20 (vigente 22/10/2026). Último scan: 17/11/2026, código 1.16.0 (branch store-edition).

## Placar

| Regra | Status | Item |
|---|---|---|
| Segurança do dispositivo (10.2) | ⛔ | Servidor local `127.0.0.1:8765` roda como administrador e aceita comandos sem checar origem nem token. Qualquer site aberto no navegador pode disparar tarefas (rede, DNS, drivers, inicialização, energia). Corrigir nas duas edições. |
| W14 / capabilities restritas | ⛔ | `allowElevation` é restrita e raramente aprovada na Store; a documentação de MSIX diz que apps que exigem elevação não são aceitos. Sem alternativa técnica sem mudar a função. |
| W4 / W5 (10.2.3, 10.2.4) | ⚠️ | Baixa e instala driver NVIDIA e baixa 7-Zip (`7zr.exe`). Declarar nas notas de certificação; risco alto de recusa. |
| Antivírus (10.2.3) | ⚠️ | VirusTotal 6/71 em 14/11 (Defender e Bitdefender já limpos). Reportar os restantes antes de enviar. |
| W8 (10.2.8) DNS | ⚠️ | "Otimizar agora" sempre volta o DNS para automático; não tem opção de desligar essa etapa. Adicionar opção (padrão ligada). |
| W8 (10.2.8) inicialização | ⚠️ | Desativa programas de inicialização pela chave `StartupApproved` (mesma do Gerenciador de Tarefas, sem API pública). Consentimento por item já existe. Explicar nas notas. |
| U4 / W11 privacy no app | ⚠️ | Política publicada (https://cleanpano.github.io/CleanPano/privacy-policy), mas sem link dentro do app. Adicionar no rodapé. |
| W2 (10.1.2/10.4.1) | ⚠️ | No Windows em modo S o PowerShell não roda; o app não detecta nem explica. Detectar no início e mostrar mensagem. |
| W7 (10.2.7) desinstalação | ✅ | Edição Store: dados no AppData do pacote; tarefa agendada se apaga sozinha (testado pelo usuário em 11/11). |
| W3 (10.2.2) código dinâmico | ✅ | `ScriptBlock::Create`/`AddScript` só executam código local do próprio motor; nada é baixado e executado como script. |
| W6 mineração / W8 APIs não documentadas | ✅ | Nenhum hit. |
| W11 privacy policy URL | ✅ | Publicada e coerente com o código. |
| W1 metadados | 🔲 manual | Título "CleanPano"; descrição sem prometer "PC mais rápido"; até 7 termos de busca. |
| W15 idiomas | 🔲 manual | Só declarar na Store os idiomas em que a descrição for traduzida. |
| W21 IARC | 🔲 manual | Questionário no Partner Center (esperado: Everyone / PEGI 3). |
| W10 notas de certificação | 🔲 manual | Sem login (não precisa conta demo); justificar `runFullTrust`, `allowElevation`, drivers e DNS. |

**Veredito: BLOQUEADO** (2 itens ⛔).

## Riscos aceitos
(nenhum)

## SDKs e coleta
| Componente | Coleta / envio |
|---|---|
| WebView2 Runtime (Microsoft) | Interface local; nada de rede pelo app |
| Web3Forms | Texto do report, e-mail opcional, versão do app/Windows, idioma — só ao clicar Enviar |
| ipify, Cloudflare, Google | IP público, ping, teste de velocidade — sob ação do usuário |
| Microsoft Update Catalog, NVIDIA, 7-zip.org, winget | Identificadores de hardware/driver; downloads |

## Re-scan — 1.16.0 (17/nov/2026, after Windows test)
- ✅ Local API protected (Host + Origin + X-CleanPano header, OPTIONS refused) — tested OK on Windows
- ✅ Privacy policy linked inside the app (footer, 20 languages)
- ✅ DNS step can be turned off (W8 consent)
- ✅ S mode detected with a clear message (W2)
- ✅ No secrets, personal paths or binaries in the repo; no dynamic code, mining or undocumented APIs
- ⛔→⏳ `allowElevation`: restricted capability; needs Microsoft approval at submission (explain in certification notes)
- ⚠️ Explain in certification notes: StartupApproved changes and boot task are user-confirmed; NVIDIA driver and 7-Zip are optional user-chosen steps
- ⚠️ Win32 direct-download listing would need Authenticode-signed .exe (W9); MSIX route is signed by the Store
Verdict: no open code blockers. Pending only Microsoft's decision on elevation + manual Partner Center items.
