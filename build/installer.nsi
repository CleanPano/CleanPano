Unicode true
Target amd64-unicode
; Instalador do CleanPano (NSIS). Gerar com build\build.ps1 (Windows) ou build/build.sh (Linux).
; Versão: mude VER aqui e AppInfo.Version em launcher\launcher.cs.
!include "MUI2.nsh"
!include "x64.nsh"
!define APP "CleanPano"
!define VER "1.15.1"
!define PUB "CleanPano"
!define UNKEY "Software\Microsoft\Windows\CurrentVersion\Uninstall\CleanPano"
Name "${APP}"
OutFile "..\dist\CleanPano-Setup.exe"
InstallDir "$PROGRAMFILES64\${APP}"
InstallDirRegKey HKLM "${UNKEY}" "InstallLocation"
RequestExecutionLevel admin
SetCompressor /SOLID lzma
BrandingText " "
ManifestDPIAware true
ManifestSupportedOS all
SetFont "Segoe UI" 9
XPStyle on
VIProductVersion "1.15.1.0"
VIAddVersionKey /LANG=0 "ProductName" "${APP}"
VIAddVersionKey /LANG=0 "FileDescription" "${APP} Setup"
VIAddVersionKey /LANG=0 "FileVersion" "${VER}"
VIAddVersionKey /LANG=0 "ProductVersion" "${VER}"
VIAddVersionKey /LANG=0 "CompanyName" "${PUB}"
VIAddVersionKey /LANG=0 "LegalCopyright" "(c) 2026 ${PUB}"

!define MUI_ICON "..\art\CleanPano.ico"
!define MUI_UNICON "..\art\CleanPano.ico"
!define MUI_WELCOMEFINISHPAGE_BITMAP "..\art\welcome.bmp"
!define MUI_UNWELCOMEFINISHPAGE_BITMAP "..\art\welcome.bmp"
!define MUI_HEADERIMAGE
!define MUI_HEADERIMAGE_RIGHT
!define MUI_HEADERIMAGE_BITMAP_STRETCH "FitControl"
!define MUI_WELCOMEFINISHPAGE_BITMAP_STRETCH "FitControl"
!define MUI_UNWELCOMEFINISHPAGE_BITMAP_STRETCH "FitControl"
!define MUI_BGCOLOR "FFFFFF"
!define MUI_TEXTCOLOR "111412"
!define MUI_INSTFILESPAGE_COLORS "111412 F7F7F3"
!define MUI_INSTFILESPAGE_PROGRESSBAR "smooth"
!define MUI_WELCOMEPAGE_TITLE_3LINES
!define MUI_FINISHPAGE_TITLE_3LINES
!define MUI_COMPONENTSPAGE_SMALLDESC
!define MUI_HEADERIMAGE_BITMAP "..\art\header.bmp"
!define MUI_ABORTWARNING
!define MUI_LANGDLL_ALLLANGUAGES

!define MUI_CUSTOMFUNCTION_GUIINIT HqHeader
!define MUI_CUSTOMFUNCTION_UNGUIINIT un.HqHeader
!define MUI_PAGE_CUSTOMFUNCTION_SHOW HqWelcome
!insertmacro MUI_PAGE_WELCOME
!insertmacro MUI_PAGE_LICENSE "..\docs\LICENSES.txt"
!insertmacro MUI_PAGE_COMPONENTS
!insertmacro MUI_PAGE_DIRECTORY
!insertmacro MUI_PAGE_INSTFILES
!define MUI_FINISHPAGE_RUN
!define MUI_FINISHPAGE_RUN_TEXT "$(RunNow)"
!define MUI_FINISHPAGE_RUN_FUNCTION RunApp
!define MUI_PAGE_CUSTOMFUNCTION_SHOW HqFinish
!insertmacro MUI_PAGE_FINISH
!insertmacro MUI_UNPAGE_CONFIRM
!insertmacro MUI_UNPAGE_INSTFILES

; idiomas do instalador: PT, EN e ES primeiro; depois os mais falados (mesma lista do programa)
; os 6 sem tradução oficial do NSIS ficam em build\lang (textos principais traduzidos)
!insertmacro MUI_LANGUAGE "PortugueseBR"
!insertmacro MUI_LANGUAGE "English"
!insertmacro MUI_LANGUAGE "Spanish"
!insertmacro MUI_LANGUAGE "SimpChinese"
!insertmacro MUI_LANGUAGE "Hindi"
!insertmacro MUI_LANGUAGE "Arabic"
!insertmacro MUI_LANGUAGE "French"
!insertmacro MUI_LANGUAGEEX "lang" "Bengali"
!insertmacro MUI_LANGUAGE "Russian"
!insertmacro MUI_LANGUAGE "Indonesian"
!insertmacro MUI_LANGUAGEEX "lang" "Urdu"
!insertmacro MUI_LANGUAGE "German"
!insertmacro MUI_LANGUAGE "Japanese"
!insertmacro MUI_LANGUAGEEX "lang" "Punjabi"
!insertmacro MUI_LANGUAGEEX "lang" "Marathi"
!insertmacro MUI_LANGUAGEEX "lang" "Telugu"
!insertmacro MUI_LANGUAGE "Turkish"
!insertmacro MUI_LANGUAGEEX "lang" "Tamil"
!insertmacro MUI_LANGUAGE "Vietnamese"
!insertmacro MUI_LANGUAGE "Korean"
!insertmacro MUI_RESERVEFILE_LANGDLL

LangString RunNow ${LANG_PORTUGUESEBR} "Abrir o CleanPano agora"
LangString RunNow ${LANG_ENGLISH} "Open CleanPano now"
LangString RunNow ${LANG_SPANISH} "Abrir CleanPano ahora"
LangString RunNow ${LANG_SIMPCHINESE} "立即打开 CleanPano"
LangString RunNow ${LANG_HINDI} "CleanPano अभी खोलें"
LangString RunNow ${LANG_ARABIC} "افتح CleanPano الآن"
LangString RunNow ${LANG_FRENCH} "Ouvrir CleanPano maintenant"
LangString RunNow ${LANG_BENGALI} "এখনই CleanPano খুলুন"
LangString RunNow ${LANG_RUSSIAN} "Открыть CleanPano"
LangString RunNow ${LANG_INDONESIAN} "Buka CleanPano sekarang"
LangString RunNow ${LANG_URDU} "ابھی CleanPano کھولیں"
LangString RunNow ${LANG_GERMAN} "CleanPano jetzt öffnen"
LangString RunNow ${LANG_JAPANESE} "今すぐ CleanPano を開く"
LangString RunNow ${LANG_PUNJABI} "ਹੁਣੇ CleanPano ਖੋਲ੍ਹੋ"
LangString RunNow ${LANG_MARATHI} "आता CleanPano उघडा"
LangString RunNow ${LANG_TELUGU} "ఇప్పుడే CleanPano తెరవండి"
LangString RunNow ${LANG_TURKISH} "CleanPano'yu şimdi aç"
LangString RunNow ${LANG_TAMIL} "இப்போது CleanPano திற"
LangString RunNow ${LANG_VIETNAMESE} "Mở CleanPano ngay"
LangString RunNow ${LANG_KOREAN} "지금 CleanPano 열기"
LangString SecApp ${LANG_PORTUGUESEBR} "CleanPano (obrigatório)"
LangString SecApp ${LANG_ENGLISH} "CleanPano (required)"
LangString SecApp ${LANG_SPANISH} "CleanPano (obligatorio)"
LangString SecApp ${LANG_SIMPCHINESE} "CleanPano（必需）"
LangString SecApp ${LANG_HINDI} "CleanPano (आवश्यक)"
LangString SecApp ${LANG_ARABIC} "CleanPano (مطلوب)"
LangString SecApp ${LANG_FRENCH} "CleanPano (obligatoire)"
LangString SecApp ${LANG_BENGALI} "CleanPano (আবশ্যক)"
LangString SecApp ${LANG_RUSSIAN} "CleanPano (обязательно)"
LangString SecApp ${LANG_INDONESIAN} "CleanPano (wajib)"
LangString SecApp ${LANG_URDU} "CleanPano (لازمی)"
LangString SecApp ${LANG_GERMAN} "CleanPano (erforderlich)"
LangString SecApp ${LANG_JAPANESE} "CleanPano（必須）"
LangString SecApp ${LANG_PUNJABI} "CleanPano (ਲਾਜ਼ਮੀ)"
LangString SecApp ${LANG_MARATHI} "CleanPano (आवश्यक)"
LangString SecApp ${LANG_TELUGU} "CleanPano (తప్పనిసరి)"
LangString SecApp ${LANG_TURKISH} "CleanPano (gerekli)"
LangString SecApp ${LANG_TAMIL} "CleanPano (அவசியம்)"
LangString SecApp ${LANG_VIETNAMESE} "CleanPano (bắt buộc)"
LangString SecApp ${LANG_KOREAN} "CleanPano (필수)"
LangString SecDesk ${LANG_PORTUGUESEBR} "Atalho na Área de Trabalho"
LangString SecDesk ${LANG_ENGLISH} "Desktop shortcut"
LangString SecDesk ${LANG_SPANISH} "Acceso directo en el escritorio"
LangString SecDesk ${LANG_SIMPCHINESE} "桌面快捷方式"
LangString SecDesk ${LANG_HINDI} "डेस्कटॉप शॉर्टकट"
LangString SecDesk ${LANG_ARABIC} "اختصار على سطح المكتب"
LangString SecDesk ${LANG_FRENCH} "Raccourci sur le Bureau"
LangString SecDesk ${LANG_BENGALI} "ডেস্কটপ শর্টকাট"
LangString SecDesk ${LANG_RUSSIAN} "Ярлык на рабочем столе"
LangString SecDesk ${LANG_INDONESIAN} "Pintasan di desktop"
LangString SecDesk ${LANG_URDU} "ڈیسک ٹاپ شارٹ کٹ"
LangString SecDesk ${LANG_GERMAN} "Desktop-Verknüpfung"
LangString SecDesk ${LANG_JAPANESE} "デスクトップのショートカット"
LangString SecDesk ${LANG_PUNJABI} "ਡੈਸਕਟਾਪ ਸ਼ਾਰਟਕੱਟ"
LangString SecDesk ${LANG_MARATHI} "डेस्कटॉप शॉर्टकट"
LangString SecDesk ${LANG_TELUGU} "డెస్క్‌టాప్ షార్ట్‌కట్"
LangString SecDesk ${LANG_TURKISH} "Masaüstü kısayolu"
LangString SecDesk ${LANG_TAMIL} "டெஸ்க்டாப் குறுக்குவழி"
LangString SecDesk ${LANG_VIETNAMESE} "Lối tắt trên màn hình"
LangString SecDesk ${LANG_KOREAN} "바탕 화면 바로 가기"
LangString Need64 ${LANG_PORTUGUESEBR} "O CleanPano precisa do Windows 10 ou 11 de 64 bits."
LangString Need64 ${LANG_ENGLISH} "CleanPano requires 64-bit Windows 10 or 11."
LangString Need64 ${LANG_SPANISH} "CleanPano requiere Windows 10 u 11 de 64 bits."
LangString Need64 ${LANG_SIMPCHINESE} "CleanPano 需要 64 位 Windows 10 或 11。"
LangString Need64 ${LANG_HINDI} "CleanPano के लिए 64-बिट Windows 10 या 11 ज़रूरी है।"
LangString Need64 ${LANG_ARABIC} "يتطلب CleanPano نظام Windows 10 أو 11 بإصدار 64 بت."
LangString Need64 ${LANG_FRENCH} "CleanPano nécessite Windows 10 ou 11 64 bits."
LangString Need64 ${LANG_BENGALI} "CleanPano-এর জন্য ৬৪-বিট Windows 10 বা 11 দরকার।"
LangString Need64 ${LANG_RUSSIAN} "Для CleanPano нужна 64-битная Windows 10 или 11."
LangString Need64 ${LANG_INDONESIAN} "CleanPano memerlukan Windows 10 atau 11 64-bit."
LangString Need64 ${LANG_URDU} "CleanPano کے لیے 64-بٹ Windows 10 یا 11 ضروری ہے۔"
LangString Need64 ${LANG_GERMAN} "CleanPano benötigt Windows 10 oder 11 (64 Bit)."
LangString Need64 ${LANG_JAPANESE} "CleanPano には 64 ビット版 Windows 10 または 11 が必要です。"
LangString Need64 ${LANG_PUNJABI} "CleanPano ਲਈ 64-ਬਿੱਟ Windows 10 ਜਾਂ 11 ਲਾਜ਼ਮੀ ਹੈ।"
LangString Need64 ${LANG_MARATHI} "CleanPano साठी 64-बिट Windows 10 किंवा 11 आवश्यक आहे."
LangString Need64 ${LANG_TELUGU} "CleanPano కు 64-బిట్ Windows 10 లేదా 11 అవసరం."
LangString Need64 ${LANG_TURKISH} "CleanPano 64 bit Windows 10 veya 11 gerektirir."
LangString Need64 ${LANG_TAMIL} "CleanPano க்கு 64-பிட் Windows 10 அல்லது 11 தேவை."
LangString Need64 ${LANG_VIETNAMESE} "CleanPano cần Windows 10 hoặc 11 bản 64-bit."
LangString Need64 ${LANG_KOREAN} "CleanPano에는 64비트 Windows 10 또는 11이 필요합니다."
LangString LangCode ${LANG_PORTUGUESEBR} "pt"
LangString LangCode ${LANG_ENGLISH} "en"
LangString LangCode ${LANG_SPANISH} "es"
LangString LangCode ${LANG_SIMPCHINESE} "zh"
LangString LangCode ${LANG_HINDI} "hi"
LangString LangCode ${LANG_ARABIC} "ar"
LangString LangCode ${LANG_FRENCH} "fr"
LangString LangCode ${LANG_BENGALI} "bn"
LangString LangCode ${LANG_RUSSIAN} "ru"
LangString LangCode ${LANG_INDONESIAN} "id"
LangString LangCode ${LANG_URDU} "ur"
LangString LangCode ${LANG_GERMAN} "de"
LangString LangCode ${LANG_JAPANESE} "ja"
LangString LangCode ${LANG_PUNJABI} "pa"
LangString LangCode ${LANG_MARATHI} "mr"
LangString LangCode ${LANG_TELUGU} "te"
LangString LangCode ${LANG_TURKISH} "tr"
LangString LangCode ${LANG_TAMIL} "ta"
LangString LangCode ${LANG_VIETNAMESE} "vi"
LangString LangCode ${LANG_KOREAN} "ko"

; ---- imagens nítidas: o Windows estica os bitmaps do instalador sem suavizar; aqui a arte em 4x
; ---- é reduzida com filtro de qualidade (HALFTONE) para o tamanho exato do controle, em qualquer escala.
; ---- Se algo falhar, fica valendo a imagem padrão (welcome.bmp / header.bmp).
ReserveFile "..\art\welcome-hq.bmp"
ReserveFile "..\art\header-hq.bmp"
!macro HQIMG UN
Function ${UN}HqImage   ; $R0 = controle, $R1 = arquivo .bmp, $R2 x $R3 = tamanho do arquivo
  Push $0
  Push $1
  Push $2
  Push $R4
  Push $R5
  Push $R6
  Push $R7
  Push $R8
  Push $R9
  StrCpy $R5 0
  System::Call '*(i 0, i 0, i 0, i 0) p .R4'
  System::Call 'user32::GetClientRect(p R0, p R4)'
  System::Call '*$R4(i, i, i .R5, i .R6)'
  System::Free $R4
  System::Call 'user32::LoadImage(p 0, t R1, i 0, i 0, i 0, i 0x2010) p .R7'
  ${If} $R7 P<> 0
  ${AndIf} $R5 > 0
  ${AndIf} $R6 > 0
    System::Call 'user32::GetDC(p R0) p .R8'
    System::Call 'gdi32::CreateCompatibleDC(p R8) p .R9'
    System::Call 'gdi32::CreateCompatibleDC(p R8) p .R4'
    System::Call 'gdi32::CreateCompatibleBitmap(p R8, i R5, i R6) p .r0'
    System::Call 'gdi32::SelectObject(p R9, p R7) p .r1'
    System::Call 'gdi32::SelectObject(p R4, p r0) p .r2'
    System::Call 'gdi32::SetStretchBltMode(p R4, i 4)'
    System::Call 'gdi32::SetBrushOrgEx(p R4, i 0, i 0, p 0)'
    System::Call 'gdi32::StretchBlt(p R4, i 0, i 0, i R5, i R6, p R9, i 0, i 0, i R2, i R3, i 0x00CC0020)'
    System::Call 'gdi32::SelectObject(p R9, p r1)'
    System::Call 'gdi32::SelectObject(p R4, p r2)'
    System::Call 'gdi32::DeleteDC(p R9)'
    System::Call 'gdi32::DeleteDC(p R4)'
    System::Call 'user32::ReleaseDC(p R0, p R8)'
    System::Call 'gdi32::DeleteObject(p R7)'
    ${If} $0 P<> 0
      SendMessage $R0 0x0172 0 $0
    ${EndIf}
  ${EndIf}
  Pop $R9
  Pop $R8
  Pop $R7
  Pop $R6
  Pop $R5
  Pop $R4
  Pop $2
  Pop $1
  Pop $0
FunctionEnd
Function ${UN}HqHeader
  InitPluginsDir
  File "/oname=$PLUGINSDIR\header-hq.bmp" "..\art\header-hq.bmp"
  GetDlgItem $R0 $HWNDPARENT 1046
  StrCpy $R1 "$PLUGINSDIR\header-hq.bmp"
  StrCpy $R2 600
  StrCpy $R3 228
  Call ${UN}HqImage
FunctionEnd
!macroend
!insertmacro HQIMG ""
!insertmacro HQIMG "un."
Function HqSide
  InitPluginsDir
  IfFileExists "$PLUGINSDIR\welcome-hq.bmp" +2
  File "/oname=$PLUGINSDIR\welcome-hq.bmp" "..\art\welcome-hq.bmp"
  StrCpy $R1 "$PLUGINSDIR\welcome-hq.bmp"
  StrCpy $R2 656
  StrCpy $R3 1256
  Call HqImage
FunctionEnd
Function HqWelcome
  StrCpy $R0 $mui.WelcomePage.Image
  Call HqSide
FunctionEnd
Function HqFinish
  StrCpy $R0 $mui.FinishPage.Image
  Call HqSide
FunctionEnd

Function .onInit
  ${IfNot} ${RunningX64}
    MessageBox MB_ICONSTOP "$(Need64)"
    Abort
  ${EndIf}
  SetRegView 64
  !insertmacro MUI_LANGDLL_DISPLAY
FunctionEnd

Function .onInstSuccess
  SetShellVarContext current
  Delete "$LOCALAPPDATA\CleanPano\edge\Default\Favicons"
  Delete "$LOCALAPPDATA\CleanPano\edge\Default\Favicons-journal"
  SetShellVarContext all
  System::Call 'shell32::SHChangeNotify(i 0x08000000, i 0, p 0, p 0)'
  nsExec::Exec '"$SYSDIR\ie4uinit.exe" -show'
FunctionEnd

Function RunApp
  Exec '"$WINDIR\explorer.exe" "$INSTDIR\CleanPano.exe"'
FunctionEnd

Section "$(SecApp)" SEC_APP
  SectionIn RO
  SetShellVarContext all
  ; fecha a janela e o motor antigos, se estiverem abertos
  InitPluginsDir
  File "/oname=$PLUGINSDIR\CleanPano.exe" "..\app\CleanPano.exe"
  ExecWait '"$PLUGINSDIR\CleanPano.exe" /stop'
  SetShellVarContext current
  Delete "$LOCALAPPDATA\CleanPano\opacity.txt"
  SetShellVarContext all
  ; idioma escolhido aqui vira o idioma do programa
  CreateDirectory "$APPDATA\CleanPano"
  FileOpen $0 "$APPDATA\CleanPano\install-lang.txt" w
  FileWrite $0 "$(LangCode)"
  FileClose $0
  SetOutPath "$INSTDIR"
  File "..\app\CleanPano.exe"
  File "..\app\CleanPano.ps1"
  File "..\app\Microsoft.Web.WebView2.Core.dll"
  File "..\app\Microsoft.Web.WebView2.WinForms.dll"
  File "..\app\WebView2Loader.dll"
  File "..\art\CleanPano.ico"
  File "..\docs\LICENSES.txt"
  ; interface: apaga a versão antiga e copia a pasta ui inteira (css, js, img, fonts, vendor)
  RMDir /r "$INSTDIR\ui"
  File /r "..\app\ui"
  CreateDirectory "$SMPROGRAMS\CleanPano"
  CreateShortCut "$SMPROGRAMS\CleanPano\CleanPano.lnk" "$INSTDIR\CleanPano.exe" "" "$INSTDIR\CleanPano.exe" 0
  CreateShortCut "$SMPROGRAMS\CleanPano\Desinstalar CleanPano.lnk" "$INSTDIR\Uninstall.exe" "" "$INSTDIR\CleanPano.ico" 0
  WriteUninstaller "$INSTDIR\Uninstall.exe"
  WriteRegStr HKLM "${UNKEY}" "DisplayName" "${APP}"
  WriteRegStr HKLM "${UNKEY}" "DisplayVersion" "${VER}"
  WriteRegStr HKLM "${UNKEY}" "Publisher" "${PUB}"
  WriteRegStr HKLM "${UNKEY}" "DisplayIcon" "$INSTDIR\CleanPano.exe,0"
  WriteRegStr HKLM "${UNKEY}" "InstallLocation" "$INSTDIR"
  WriteRegStr HKLM "${UNKEY}" "UninstallString" '"$INSTDIR\Uninstall.exe"'
  WriteRegStr HKLM "${UNKEY}" "QuietUninstallString" '"$INSTDIR\Uninstall.exe" /S'
  WriteRegDWORD HKLM "${UNKEY}" "NoModify" 1
  WriteRegDWORD HKLM "${UNKEY}" "NoRepair" 1
  WriteRegDWORD HKLM "${UNKEY}" "EstimatedSize" 1600
SectionEnd

Section "$(SecDesk)" SEC_DESK
  SetShellVarContext all
  CreateShortCut "$DESKTOP\CleanPano.lnk" "$INSTDIR\CleanPano.exe" "" "$INSTDIR\CleanPano.exe" 0
SectionEnd

Function un.onInit
  SetRegView 64
  !insertmacro MUI_UNGETLANGUAGE
FunctionEnd

Section "Uninstall"
  SetShellVarContext all
  nsExec::Exec 'schtasks.exe /Delete /TN CleanPano /F'
  IfFileExists "$INSTDIR\CleanPano.exe" 0 +2
  ExecWait '"$INSTDIR\CleanPano.exe" /stop'
  Sleep 1000
  Delete "$DESKTOP\CleanPano.lnk"
  RMDir /r "$SMPROGRAMS\CleanPano"
  RMDir /r "$INSTDIR\ui"
  Delete "$INSTDIR\CleanPano.exe"
  Delete "$INSTDIR\CleanPano.ps1"
  Delete "$INSTDIR\Microsoft.Web.WebView2.Core.dll"
  Delete "$INSTDIR\Microsoft.Web.WebView2.WinForms.dll"
  Delete "$INSTDIR\WebView2Loader.dll"
  Delete "$INSTDIR\CleanPano.ico"
  Delete "$INSTDIR\LICENSES.txt"
  Delete "$INSTDIR\Uninstall.exe"
  RMDir "$INSTDIR"
  RMDir /r "$APPDATA\CleanPano"
  SetShellVarContext current
  RMDir /r "$LOCALAPPDATA\CleanPano"
  SetShellVarContext all
  DeleteRegKey HKLM "${UNKEY}"
SectionEnd
