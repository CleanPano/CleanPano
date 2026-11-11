#Requires -Version 5.1
param([switch]$Boot)
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Start-Process powershell.exe ("-NoProfile -ExecutionPolicy RemoteSigned -File `"$PSCommandPath`""+$(if ($Boot) { ' -Boot' } else { '' })) -Verb RunAs -WindowStyle Hidden
    exit
}
$DataDir = Join-Path $env:ProgramData 'CleanPano'
$LogDir = Join-Path $DataDir 'logs'
New-Item -ItemType Directory -Path $LogDir -Force | Out-Null
$sync = [hashtable]::Synchronized(@{
    DataDir = $DataDir
    Q       = New-Object 'System.Collections.Concurrent.ConcurrentQueue[string]'
    Result  = $null
    LogDir  = $LogDir
    LogFile = (Join-Path $LogDir ("log_{0:yyyy-MM-dd}.txt" -f (Get-Date)))
})

$Core = @'
$ErrorActionPreference = 'SilentlyContinue'
$ProgressPreference = 'SilentlyContinue'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
try { [Console]::OutputEncoding = [Text.Encoding]::UTF8 } catch {}
function Log($m) { $l = "$(Get-Date -f 'HH:mm:ss')  $m"; $sync.Q.Enqueue($l); Add-Content -Path $sync.LogFile -Value $l -Encoding UTF8 }
function Fmt($b) { $b = [double]$b; if ($b -ge 1GB) { '{0:N2} GB' -f ($b / 1GB) } else { '{0:N1} MB' -f ($b / 1MB) } }
function Get-Targets {
    $l = $env:LOCALAPPDATA
    @(
        [pscustomobject]@{ Name = 'Temp do usuário';            Paths = @($env:TEMP); Filter = '*' }
        [pscustomobject]@{ Name = 'Temp do Windows';            Paths = @("$env:windir\Temp"); Filter = '*' }
        [pscustomobject]@{ Name = 'Cache do Windows Update';    Paths = @("$env:windir\SoftwareDistribution\Download"); Filter = '*'; Services = @('wuauserv', 'bits') }
        [pscustomobject]@{ Name = 'Cache de miniaturas';        Paths = @("$l\Microsoft\Windows\Explorer"); Filter = 'thumbcache_*.db' }
        [pscustomobject]@{ Name = 'Relatórios de erro';         Paths = @("$env:ProgramData\Microsoft\Windows\WER\ReportArchive", "$env:ProgramData\Microsoft\Windows\WER\ReportQueue", "$l\CrashDumps"); Filter = '*' }
        [pscustomobject]@{ Name = 'Logs do Windows';            Paths = @("$env:windir\Logs"); Filter = '*.log' }
        [pscustomobject]@{ Name = 'Cache do Google Chrome';     Paths = @("$l\Google\Chrome\User Data\*\Cache", "$l\Google\Chrome\User Data\*\Code Cache", "$l\Google\Chrome\User Data\*\GPUCache"); Filter = '*'; Proc = 'chrome' }
        [pscustomobject]@{ Name = 'Cache do Microsoft Edge';    Paths = @("$l\Microsoft\Edge\User Data\*\Cache", "$l\Microsoft\Edge\User Data\*\Code Cache", "$l\Microsoft\Edge\User Data\*\GPUCache"); Filter = '*'; Proc = 'msedge' }
        [pscustomobject]@{ Name = 'Cache do Firefox';           Paths = @("$l\Mozilla\Firefox\Profiles\*\cache2"); Filter = '*'; Proc = 'firefox' }
        [pscustomobject]@{ Name = 'Cache de shaders (DirectX)'; Paths = @("$l\D3DSCache"); Filter = '*' }
    )
}
function Get-BrowserProcs($name) { @(Get-CimInstance Win32_Process -Filter "Name='$name.exe'" | Where-Object { $_.CommandLine -notlike '*CleanPano*' }) }
function Invoke-Clean($names, $close) {
    $freed = 0; $skipped = @()
    foreach ($t in (Get-Targets | Where-Object { $names -contains $_.Name })) {
        if ($t.Proc -and (Get-BrowserProcs $t.Proc).Count) {
            if ($close) { Get-BrowserProcs $t.Proc | ForEach-Object { Stop-Process -Id $_.ProcessId -Force }; Start-Sleep 2 }
            else { Log "Pulado: $($t.Name) (navegador aberto)"; $skipped += $t.Proc; continue }
        }
        foreach ($s in $t.Services) { Stop-Service $s -Force }
        $ok = 0; $bytes = 0
        foreach ($f in (Get-TargetFiles $t)) {
            $len = $f.Length
            Remove-Item -LiteralPath $f.FullName -Force -ErrorAction SilentlyContinue
            if (-not (Test-Path -LiteralPath $f.FullName)) { $ok++; $bytes += $len }
        }
        foreach ($s in $t.Services) { Start-Service $s }
        $freed += $bytes
        Log ("{0,-28} {1,7} arquivos   {2}" -f $t.Name, $ok, (Fmt $bytes))
    }
    if ($names -contains 'Lixeira') {
        $rb = Get-RecycleSize
        Clear-RecycleBin -Force -ErrorAction SilentlyContinue
        $freed += $rb
        Log ("{0,-28} {1,7}            {2}" -f 'Lixeira', '', (Fmt $rb))
    }
    @{ freed = [double]$freed; skipped = $skipped }
}
function Get-TargetFiles($t) { foreach ($p in $t.Paths) { Get-ChildItem -Path $p -Recurse -Force -File -Filter $t.Filter -ErrorAction SilentlyContinue } }
function Get-RecycleSize {
    $sum = 0
    foreach ($dr in (Get-PSDrive -PSProvider FileSystem)) { $sum += (Get-ChildItem (Join-Path $dr.Root '$Recycle.Bin') -Recurse -Force -File -ErrorAction SilentlyContinue | Measure-Object Length -Sum).Sum }
    [double]$sum
}
function Run-Exe($exe, [string[]]$argList) {
    & $exe @argList 2>&1 | ForEach-Object {
        $s = (($_ | Out-String) -replace "`0", '').Split("`r") | Where-Object { $_.Trim() } | Select-Object -Last 1
        if ($s -and $s -notmatch '^\s*[-\\|/]\s*$' -and $s -notmatch '[█▒]') { Log $s.Trim() }
    }
}
function Get-HwInventory {
    $items = New-Object System.Collections.ArrayList
    function Add-Hw($cat, $title, $name, $specs, $status = 'ok', $flags = @()) { [void]$items.Add(@{ cat = $cat; title = $title; name = ([string]$name).Trim(); specs = @($specs | Where-Object { $_ } | ForEach-Object { ([string]$_).Trim() }); status = $status; flags = @($flags | Where-Object { $_ }) }) }
    # flag = selo de entusiasta: k = chave de tradução na interface (hf_*), s = ok | warn | info, a = valores
    function Flag($k, $s = 'ok', $a = @()) { @{ k = $k; s = $s; a = (@($a | ForEach-Object { $_ } | ForEach-Object { [string]$_ }) -join '|') } }
    function GB($b) { $b = [double]$b; if ($b -ge 1TB) { '{0:N1} TB' -f ($b / 1TB) } elseif ($b -ge 1GB) { '{0:N0} GB' -f ($b / 1GB) } else { '{0:N0} MB' -f ($b / 1MB) } }
    function Dec($a) { if ($a) { -join ($a | Where-Object { $_ -ne 0 } | ForEach-Object { [char]$_ }) } }
    Log 'Lendo componentes do computador...'
    try {
        $cpu = Get-CimInstance Win32_Processor | Select-Object -First 1
        $cf = @()
        # 1) como está AGORA: mede o clock real (contador de desempenho, independe do idioma do Windows)
        #    a) pico em 1 núcleo  b) média de todos os núcleos com carga total
        function Measure-Clock([int]$threads, [int]$ms) {
            $jobs = @(); for ($j = 0; $j -lt $threads; $j++) { $pj = [powershell]::Create(); [void]$pj.AddScript("`$e=(Get-Date).AddMilliseconds($ms);`$x=0;while((Get-Date) -lt `$e){`$x++}"); $jobs += @{ P = $pj; H = $pj.BeginInvoke() } }
            $pk = 0; $avg = @()
            Start-Sleep -Milliseconds 400
            for ($i = 0; $i -lt [math]::Max(3, [int](($ms - 600) / 300)); $i++) {
                $pi = @(Get-CimInstance Win32_PerfFormattedData_Counters_ProcessorInformation -ErrorAction Stop | Where-Object { $_.Name -notmatch '_Total' })
                $fs = @($pi | ForEach-Object { [double]$_.ProcessorFrequency * [double]$_.PercentProcessorPerformance / 100 })
                if ($fs.Count) { $m = ($fs | Measure-Object -Maximum -Average); if ($m.Maximum -gt $pk) { $pk = $m.Maximum }; $avg += $m.Average }
                Start-Sleep -Milliseconds 300
            }
            foreach ($jb in $jobs) { try { [void]$jb.P.EndInvoke($jb.H) } catch {}; $jb.P.Dispose() }
            @{ Peak = $pk; All = $(if ($avg.Count) { ($avg | Measure-Object -Average).Average } else { 0 }) }
        }
        $peak = 0; $allc = 0
        try { $peak = (Measure-Clock 1 2000).Peak } catch {}
        try { $allc = (Measure-Clock ([int]$cpu.NumberOfLogicalProcessors) 2200).All } catch {}
        # 2) como vem de FÁBRICA: clock base (nome / SMBIOS) e boost máximo oficial (tabela dos modelos mais comuns)
        $base = [double]$cpu.MaxClockSpeed
        $nameGHz = $(if ($cpu.Name -match '@\s*([\d.]+)\s*GHz') { [double]$Matches[1] * 1000 } else { 0 })
        $spec = @{}; foreach ($kv in 'i3-8100=3600/3600;i3-8350K=4000/4000;i5-8400=2800/4000;i5-8500=3000/4100;i5-8600=3100/4300;i5-8600K=3600/4300;i7-8700=3200/4600;i7-8700K=3700/4700;i7-8086K=4000/5000;i3-9100=3600/4200;i5-9400=2900/4100;i5-9500=3000/4400;i5-9600K=3700/4600;i7-9700=3000/4700;i7-9700K=3600/4900;i9-9900=3100/5000;i9-9900K=3600/5000;i9-9900KS=4000/5000;i3-10100=3600/4300;i5-10400=2900/4300;i5-10500=3100/4500;i5-10600=3300/4800;i5-10600K=4100/4800;i7-10700=2900/4800;i7-10700K=3800/5100;i9-10850K=3600/5200;i9-10900=2800/5200;i9-10900K=3700/5300;i5-11400=2600/4400;i5-11500=2700/4600;i5-11600K=3900/4900;i7-11700=2500/4900;i7-11700K=3600/5000;i9-11900=2500/5200;i9-11900K=3500/5300;i3-12100=3300/4300;i5-12400=2500/4400;i5-12500=3000/4600;i5-12600=3300/4800;i5-12600K=3700/4900;i7-12700=2100/4900;i7-12700K=3600/5000;i9-12900=2400/5100;i9-12900K=3200/5200;i9-12900KS=3400/5500;i3-13100=3400/4500;i5-13400=2500/4600;i5-13500=2500/4800;i5-13600K=3500/5100;i7-13700=2100/5200;i7-13700K=3400/5400;i9-13900=2000/5600;i9-13900K=3000/5800;i9-13900KS=3200/6000;i3-14100=3500/4700;i5-14400=2500/4700;i5-14500=2600/5000;i5-14600K=3500/5300;i7-14700=2100/5400;i7-14700K=3400/5600;i9-14900=2000/5800;i9-14900K=3200/6000;i9-14900KS=3200/6200;U5-225=3300/4900;U5-245K=4200/5200;U7-265=2400/5300;U7-265K=3900/5500;U9-285=2500/5600;U9-285K=3700/5700;1600=3200/3600;1600X=3600/4000;1700=3000/3700;1700X=3400/3800;1800X=3600/4000;2600=3400/3900;2600X=3600/4200;2700=3200/4100;2700X=3700/4300;2200G=3500/3700;2400G=3600/3900;3100=3600/3900;3300X=3800/4300;3600=3600/4200;3600X=3800/4400;3600XT=3800/4500;3700X=3600/4400;3800X=3900/4500;3800XT=3900/4700;3900X=3800/4600;3900XT=3800/4700;3950X=3500/4700;3200G=3600/4000;3400G=3700/4200;5500=3600/4200;5600=3500/4400;5600X=3700/4600;5600G=3900/4400;5600X3D=3300/4400;5700X=3400/4600;5700G=3800/4600;5700X3D=3000/4100;5800=3400/4600;5800X=3800/4700;5800X3D=3400/4500;5900X=3700/4800;5950X=3400/4900;7600=3800/5100;7600X=4700/5300;7700=3800/5300;7700X=4500/5400;7800X3D=4200/5000;7900=3700/5400;7900X=4700/5600;7900X3D=4400/5600;7950X=4500/5700;7950X3D=4200/5700;8500G=3500/5000;8600G=4300/5000;8700G=4200/5100;9600=3800/5200;9600X=3900/5400;9700X=3800/5500;9800X3D=4700/5200;9900X=4400/5600;9900X3D=4400/5500;9950X=4300/5700;9950X3D=4300/5700'.Split(';')) { $p2 = $kv.Split('='); $bb2 = $p2[1].Split('/'); $spec[$p2[0]] = @([int]$bb2[0], [int]$bb2[1]) }
        $model = $null
        if ($cpu.Name -match '(i[3579])-(\d{4,5})(KS|K|)F?\b') { $model = "$($Matches[1])-$($Matches[2])$($Matches[3])" }
        elseif ($cpu.Name -match 'Ultra (\d) (\d{3})(K?)F?\b') { $model = "U$($Matches[1])-$($Matches[2])$($Matches[3])" }
        elseif ($cpu.Name -match 'Ryzen \d (\d{4}(?:X3D|XT|X|G)?)\b') { $model = $Matches[1] }
        $fabBase = 0; $fab = 0
        if ($model -and $spec.ContainsKey($model)) { $fabBase = $spec[$model][0]; $fab = $spec[$model][1] }
        # com overclock fixo o Windows passa a informar o clock configurado no lugar do base de fábrica
        $baseOC = ($fabBase -gt 0 -and $base -gt $fabBase * 1.03)
        # 3) compara: fábrica x agora
        $g = { param($v) '{0:N2}' -f ($v / 1000) }
        if ($baseOC) { $cf += Flag 'hf_oc' 'warn' @((& $g $fabBase), (& $g $base)) }
        elseif ($nameGHz -gt 0 -and $base -gt $nameGHz * 1.03) { $cf += Flag 'hf_oc' 'warn' @((& $g $nameGHz), (& $g $base)) }
        elseif ($fab -gt 0 -and $peak -gt $fab * 1.025) { $cf += Flag 'hf_oc' 'warn' @((& $g $fab), (& $g $peak)) }
        elseif ($fab -gt 0 -and $allc -gt $fab * 0.985) { $cf += Flag 'hf_oc' 'warn' @((& $g $fab), (& $g $allc)) }
        # overclock fixo (ex.: 5900X travado em 4,65 GHz): de fábrica o 1 núcleo sobe bem mais que todos juntos;
        # com clock fixo, 1 núcleo = todos os núcleos, e todos ficam muito acima do normal de fábrica
        elseif ($fab -gt 0 -and $peak -gt 0 -and $allc -ge $peak * 0.975 -and $allc -ge ($base + 0.6 * ($fab - $base)) -and $model -notmatch 'X3D') { $cf += Flag 'hf_oc_all' 'warn' @((& $g $allc)) }
        elseif ($fab -gt 0) { $cf += Flag 'hf_nooc' 'ok' }
        else { $cf += Flag 'hf_nospec' 'info' }
        if ($fab -gt 0) { $cf += Flag 'hf_spec' 'info' @((& $g $fabBase), (& $g $fab)) }
        # com clock alterado os contadores de frequência do Windows ficam distorcidos: só mostra a medição quando está de fábrica
        if (-not $baseOC) {
            if ($peak -gt $base * 1.02) { $cf += Flag 'hf_boost' 'info' @((& $g $peak)) }
            if ($allc -gt 0) { $cf += Flag 'hf_allc' 'info' @((& $g $allc)) }
        }
        if ($cpu.Name -match 'Ryzen|Threadripper' -or $cpu.Name -match 'i\d-\d{4,5}K|Core.*\d{3,5}K[FS]?\b|Ultra \d+ \d+K') { $cf += Flag 'hf_unl' 'info' }
        if ($null -ne $cpu.VirtualizationFirmwareEnabled) { $cf += $(if ($cpu.VirtualizationFirmwareEnabled) { Flag 'hf_virt' 'ok' } else { Flag 'hf_novirt' 'info' }) }
        elseif ((Get-CimInstance Win32_ComputerSystem).HypervisorPresent) { $cf += Flag 'hf_virt' 'ok' }
        $l2 = $(if ($cpu.L2CacheSize) { "L2 $([math]::Round($cpu.L2CacheSize / 1024, 1)) MB" })
        Add-Hw 'cpu' 'Processador' $cpu.Name @("$($cpu.NumberOfCores) núcleos / $($cpu.NumberOfLogicalProcessors) threads", $(if ($fabBase -gt 0) { 'base {0:N2} GHz' -f ($fabBase / 1000) } else { 'base {0:N2} GHz' -f ($base / 1000) }), $(if ($baseOC) { 'agora {0:N2} GHz' -f ($base / 1000) }), $l2, $(if ($cpu.L3CacheSize) { "L3 $([math]::Round($cpu.L3CacheSize / 1024)) MB" }), $cpu.SocketDesignation, "uso agora $($cpu.LoadPercentage)%") 'ok' $cf
    } catch { Log "Processador: $($_.Exception.Message)" }
    try {
        $vram = @{}
        Get-ChildItem 'HKLM:\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}' -ErrorAction SilentlyContinue | ForEach-Object {
            $p = Get-ItemProperty $_.PSPath -ErrorAction SilentlyContinue
            $q = $p.'HardwareInformation.qwMemorySize'
            if ($p.DriverDesc -and $q) { $vram[$p.DriverDesc] = [double]$q }
        }
        foreach ($g in @(Get-CimInstance Win32_VideoController | Where-Object { $_.Name -notmatch 'Basic|Remote|Virtual|Mirror|Parsec|Meta|Indirect' })) {
            $mem = $(if ($vram[$g.Name]) { $vram[$g.Name] } else { [double]$g.AdapterRAM })
            $res = $(if ($g.CurrentHorizontalResolution) { "$($g.CurrentHorizontalResolution)x$($g.CurrentVerticalResolution) @ $($g.CurrentRefreshRate) Hz" })
            $gf = @()
            $hs = (Get-ItemProperty 'HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers' -Name HwSchMode -ErrorAction SilentlyContinue).HwSchMode
            if ($null -ne $hs) { $gf += $(if ($hs -eq 2) { Flag 'hf_hags' 'ok' } else { Flag 'hf_nohags' 'info' }) }
            if ($g.Name -match 'NVIDIA') {
                try {
                    $smi = @(& nvidia-smi --query-gpu=power.limit,power.default_limit,clocks.applications.graphics,clocks.default_applications.graphics,clocks.max.graphics --format=csv,noheader,nounits 2>$null)[0]
                    if ($smi) {
                        $v = @($smi.Split(',') | ForEach-Object { $n = 0.0; if ([double]::TryParse($_.Trim(), [Globalization.NumberStyles]::Float, [Globalization.CultureInfo]::InvariantCulture, [ref]$n)) { $n } else { 0 } })
                        if ($v[0] -gt 0 -and $v[1] -gt 0) {
                            $pct = [math]::Round(($v[0] / $v[1] - 1) * 100)
                            if ($pct -ge 2) { $gf += Flag 'hf_gpu_pl' 'warn' @($pct) } elseif ($pct -le -2) { $gf += Flag 'hf_gpu_low' 'info' @(-$pct) }
                        }
                        if ($v[2] -gt 0 -and $v[3] -gt 0 -and $v[2] -gt $v[3] + 10) { $gf += Flag 'hf_gpu_oc' 'warn' @([int]$v[3], [int]$v[2]) }
                    }
                } catch {}
            }
            Add-Hw 'gpu' 'Placa de vídeo' $g.Name @($(if ($mem -gt 0) { "$(GB $mem) VRAM" }), $res, "driver $($g.DriverVersion)", $(if ($g.DriverDate) { 'de ' + $g.DriverDate.ToString('dd/MM/yyyy') })) $(if ($g.Status -eq 'OK') { 'ok' } else { 'warn' }) $gf
        }
    } catch { Log "Vídeo: $($_.Exception.Message)" }
    try {
        $mods = @(Get-CimInstance Win32_PhysicalMemory)
        $types = @{ 20 = 'DDR'; 21 = 'DDR2'; 22 = 'DDR2'; 24 = 'DDR3'; 26 = 'DDR4'; 29 = 'LPDDR3'; 30 = 'LPDDR4'; 34 = 'DDR5'; 35 = 'LPDDR5' }
        $tot = ($mods | Measure-Object Capacity -Sum).Sum
        $tp = $types[[int]$mods[0].SMBIOSMemoryType]
        $spd = ($mods | ForEach-Object { if ($_.ConfiguredClockSpeed) { $_.ConfiguredClockSpeed } else { $_.Speed } } | Measure-Object -Maximum).Maximum
        $slots = (Get-CimInstance Win32_PhysicalMemoryArray | Measure-Object MemoryDevices -Sum).Sum
        $pn = ([string]$mods[0].PartNumber).Trim()
        $rf = @()
        # canais: lê a posição de cada pente (ChannelA-DIMM0, DIMM_A1, A1, P0 CHANNEL A...)
        $ch = @{}
        foreach ($m in $mods) {
            $loc = "$($m.DeviceLocator) $($m.BankLabel)"
            $c = $null
            if ($loc -match 'CHANNEL\s*([A-H])\b') { $c = $Matches[1] }
            elseif ($loc -match 'DIMM[_\s-]?([A-H])\d') { $c = $Matches[1] }
            elseif ($loc -match '(?:^|\s|_)([A-H])\d(?:\s|_|$)') { $c = $Matches[1] }
            elseif ($loc -match 'BANK\s*(\d)') { $c = 'B' + $Matches[1] }
            if ($c) { $ch[$c.ToUpper()] = 1 }
        }
        $nch = $ch.Count
        if ($nch -eq 0 -or ($ch.Keys -join '') -match '^(B\d)+$') { $nch = $(if ($mods.Count -ge 4 -and $mods.Count % 4 -eq 0 -and $slots -ge 8) { 4 } elseif ($mods.Count -ge 2) { 2 } else { 1 }) }
        $rf += $(if ($nch -ge 4) { Flag 'hf_quad' 'ok' } elseif ($nch -ge 2) { Flag 'hf_dual' 'ok' } else { Flag 'hf_single' $(if ($slots -ge 2) { 'warn' } else { 'info' }) })
        # XMP / EXPO: compara a velocidade atual com o padrão JEDEC e com a velocidade do kit (no código do pente)
        $cfg = ($mods | ForEach-Object { [int]$_.ConfiguredClockSpeed } | Measure-Object -Maximum).Maximum
        $jedec = @{ 'DDR3' = 1600; 'DDR4' = 3200; 'DDR5' = 6400; 'LPDDR4' = 4266; 'LPDDR5' = 6400 }[$tp]
        $kit = 0; if ($pn -match '(?<!\d)(1[6-9]00|2[0-9]{3}|3[0-9]{3}|4[0-9]{3}|5[0-9]{3}|6[0-9]{3}|7[0-9]{3}|8[0-9]{3})(?!\d)') { $kit = [int]$Matches[1] }
        $rated = ($mods | ForEach-Object { [int]$_.Speed } | Measure-Object -Maximum).Maximum
        if ($cfg -and $tp -notmatch '^LP') {
            if ($kit -gt 0 -and $cfg -gt $kit + 100) { $rf += Flag 'hf_ram_oc' 'warn' @($kit, $cfg) }
            elseif ($kit -gt $cfg + 100) { $rf += Flag 'hf_noxmp' 'warn' @($cfg, $kit) }
            elseif (($jedec -and $cfg -gt $jedec) -or ($rated -and $cfg -gt $rated + 50) -or ($kit -gt 0 -and $cfg -ge $kit - 100 -and $kit -gt $jedec)) { $rf += Flag 'hf_xmp' 'ok' }
        }
        $pns = @($mods | ForEach-Object { ([string]$_.PartNumber).Trim() } | Select-Object -Unique)
        if ($mods.Count -ge 2) { $rf += $(if ($pns.Count -eq 1) { Flag 'hf_match' 'ok' } else { Flag 'hf_mixed' 'warn' }) }
        Add-Hw 'ram' 'Memória RAM' "$(GB $tot) $tp" @($(if ($spd) { "$spd MT/s" }), $(if ($slots) { "$($mods.Count) de $slots slots" } else { "$($mods.Count) pente(s)" }), (($mods | ForEach-Object { GB $_.Capacity }) -join ' + '), ([string]$mods[0].Manufacturer).Trim(), $pn) 'ok' $rf
    } catch { Log "Memória: $($_.Exception.Message)" }
    try {
        $bb = Get-CimInstance Win32_BaseBoard; $bios = Get-CimInstance Win32_BIOS; $cs = Get-CimInstance Win32_ComputerSystem
        $model = $(if ($cs.Model -and $cs.Model -notmatch 'To Be Filled|System Product|Default') { "PC: $($cs.Manufacturer) $($cs.Model)" })
        $bf = @()
        $sb = $null; try { $sb = Confirm-SecureBootUEFI -ErrorAction Stop } catch { if ($_.Exception.Message -match 'not supported|não .* suportad') { $sb = 'legacy' } }
        if ($sb -eq 'legacy') { $bf += Flag 'hf_legacy' 'warn' } else {
            $fw = (Get-ItemProperty 'HKLM:\SYSTEM\CurrentControlSet\Control' -Name PEFirmwareType -ErrorAction SilentlyContinue).PEFirmwareType
            if ($fw -eq 2 -or $sb -is [bool]) { $bf += Flag 'hf_uefi' 'ok' } elseif ($fw -eq 1) { $bf += Flag 'hf_legacy' 'warn' }
            if ($sb -is [bool]) { $bf += $(if ($sb) { Flag 'hf_sb' 'ok' } else { Flag 'hf_nosb' 'info' }) }
        }
        try {
            $tpm = Get-CimInstance -Namespace root\cimv2\Security\MicrosoftTpm -ClassName Win32_Tpm -ErrorAction Stop | Select-Object -First 1
            if ($tpm) { $tv = ([string]$tpm.SpecVersion).Split(',')[0].Trim(); $bf += Flag 'hf_tpm' $(if ($tpm.IsEnabled_InitialValue -ne $false) { 'ok' } else { 'info' }) @($tv) } else { $bf += Flag 'hf_notpm' 'warn' }
        } catch { $bf += Flag 'hf_notpm' 'warn' }
        Add-Hw 'board' 'Placa-mãe' "$($bb.Manufacturer) $($bb.Product)" @("BIOS $($bios.SMBIOSBIOSVersion)", $(if ($bios.ReleaseDate) { 'de ' + $bios.ReleaseDate.ToString('dd/MM/yyyy') }), $(if ($bb.Version -and $bb.Version -notmatch 'Default|To be|x\.x') { "rev $($bb.Version)" }), $model) 'ok' $bf
    } catch { Log "Placa-mãe: $($_.Exception.Message)" }
    $trim = $null; try { $q = (fsutil behavior query DisableDeleteNotify 2>$null) -join ' '; if ($q -match 'NTFS[^=]*=\s*(\d)') { $trim = ($Matches[1] -eq '0') } } catch {}
    try {
        foreach ($d in @(Get-PhysicalDisk | Sort-Object { [int]$_.DeviceId })) {
            $bus = [string]$d.BusType; $mt = [string]$d.MediaType
            $kind = $(if ($bus -eq 'NVMe') { 'SSD NVMe' } elseif ($mt -eq 'SSD') { "SSD $bus" } elseif ($mt -eq 'HDD') { "HD $bus" } else { "Disco $bus" })
            $rc = $d | Get-StorageReliabilityCounter -ErrorAction SilentlyContinue
            $letters = @(Get-Partition -DiskNumber ([int]$d.DeviceId) -ErrorAction SilentlyContinue | Where-Object DriveLetter | ForEach-Object { $v = Get-Volume -DriveLetter $_.DriveLetter -ErrorAction SilentlyContinue; "$($_.DriveLetter): $(GB $v.SizeRemaining) livres" })
            $warn = ($d.HealthStatus -ne 'Healthy') -or ($rc.Wear -gt 80) -or ($rc.Temperature -gt 60)
            $df = @(); if ($mt -eq 'SSD' -and $null -ne $trim) { $df += $(if ($trim) { Flag 'hf_trim' 'ok' } else { Flag 'hf_notrim' 'warn' }) }
            Add-Hw 'disk' $kind $d.FriendlyName (@((GB $d.Size)) + $letters + @("saúde: $(if ($d.HealthStatus -eq 'Healthy') { 'boa' } else { $d.HealthStatus })", $(if ($rc.Temperature) { "$($rc.Temperature) °C" }), $(if ($mt -eq 'SSD' -and $null -ne $rc.Wear) { "desgaste $($rc.Wear)%" }))) $(if ($warn) { 'warn' } else { 'ok' }) $df
        }
    } catch { Log "Discos: $($_.Exception.Message)" }
    try {
        foreach ($m in @(Get-CimInstance -Namespace root\wmi -ClassName WmiMonitorID -ErrorAction SilentlyContinue)) {
            $n = Dec $m.UserFriendlyName
            Add-Hw 'monitor' 'Monitor' $(if ($n) { $n } else { 'Monitor genérico' }) @((Dec $m.ManufacturerName), $(if ($m.YearOfManufacture) { "fabricado em $($m.YearOfManufacture)" }))
        }
    } catch {}
    try {
        foreach ($n in @(Get-NetAdapter -Physical)) {
            $wifi = ([string]$n.PhysicalMediaType -match '802\.11') -or ($n.InterfaceDescription -match 'Wi-?Fi|Wireless|WLAN')
            Add-Hw 'net' $(if ($wifi) { 'Rede Wi-Fi' } else { 'Rede cabeada' }) $n.InterfaceDescription @($(if ($n.Status -eq 'Up') { "conectado · $($n.LinkSpeed)" } else { 'desconectado' }), "driver $($n.DriverVersion)")
        }
    } catch {}
    try {
        $snd = @(Get-CimInstance Win32_SoundDevice | Where-Object { $_.Status -eq 'OK' } | Select-Object -ExpandProperty Name -Unique)
        if ($snd.Count) { Add-Hw 'audio' 'Áudio' $snd[0] @($snd | Select-Object -Skip 1) }
    } catch {}
    Log "$($items.Count) componentes encontrados"
    $r = @{ items = @($items.ToArray()); at = (Get-Date -f 'dd/MM HH:mm'); v = 4 }
        try { ConvertTo-Json -InputObject $r -Depth 12 | Set-Content -Path (Join-Path $sync.DataDir 'hardware.json') -Encoding UTF8 } catch {}
        $r
}
function ToVer($s) { try { [version](([string]$s).Trim()) } catch { $null } }
function New-CatClient { $wc = New-Object Net.WebClient; $wc.Encoding = [Text.Encoding]::UTF8; $wc.Headers.Add('User-Agent', 'CleanPano/1.1 (Windows)'); $wc }
function Get-CatalogRows($q) {
    $html = (New-CatClient).DownloadString('https://www.catalog.update.microsoft.com/Search.aspx?q=' + [uri]::EscapeDataString($q))
    $rows = @()
    foreach ($m in [regex]::Matches($html, '<tr id="([0-9a-fA-F\-]{36})_R\d+".*?</tr>', 'Singleline')) {
        $cells = @([regex]::Matches($m.Value, '<td[^>]*>(.*?)</td>', 'Singleline') | ForEach-Object { [Net.WebUtility]::HtmlDecode((($_.Groups[1].Value -replace '<[^>]+>', ' ') -replace '\s+', ' ').Trim()) })
        if ($cells.Count -ge 6) { $rows += [pscustomobject]@{ Guid = $m.Groups[1].Value; Title = $cells[1]; Products = $cells[2]; Class = $cells[3]; Date = $cells[4]; Version = $cells[5] } }
    }
    $rows
}
function Get-CatalogUrl($guid) {
    $wc = New-CatClient
    $wc.Headers.Add('Content-Type', 'application/x-www-form-urlencoded')
    $body = 'updateIDs=' + [uri]::EscapeDataString('[{"size":0,"languages":"","uidInfo":"' + $guid + '","updateID":"' + $guid + '"}]')
    $r = $wc.UploadString('https://www.catalog.update.microsoft.com/DownloadDialog.aspx', $body)
    $m = [regex]::Matches($r, 'https?://[^''"\s]+\.cab')
    if ($m.Count) { $m[0].Value } else { $null }
}
function Get-HwQueries($ids) {
    $q = New-Object System.Collections.ArrayList
    foreach ($id in $ids) {
        foreach ($rx in '^(PCI\\VEN_[0-9A-F]{4}&DEV_[0-9A-F]{4}&SUBSYS_[0-9A-F]{8})', '^(HDAUDIO\\FUNC_[0-9A-F]{2}&VEN_[0-9A-F]{4}&DEV_[0-9A-F]{4}&SUBSYS_[0-9A-F]{8})', '^(USB\\VID_[0-9A-F]{4}&PID_[0-9A-F]{4})', '^(PCI\\VEN_[0-9A-F]{4}&DEV_[0-9A-F]{4})', '^(HDAUDIO\\FUNC_[0-9A-F]{2}&VEN_[0-9A-F]{4}&DEV_[0-9A-F]{4})', '^(ACPI\\[A-Z0-9_]+)', '^(INTELAUDIO\\[^\\]+)') {
            $m = [regex]::Match([string]$id, $rx, 'IgnoreCase')
            if ($m.Success -and -not $q.Contains($m.Groups[1].Value.ToUpper())) { [void]$q.Add($m.Groups[1].Value.ToUpper()) }
        }
    }
    @($q | Select-Object -First 3)
}
function Invoke-WebDrivers {
    $tmp = Join-Path $env:TEMP 'CleanPano\catalog'
    Remove-Item $tmp -Recurse -Force -ErrorAction SilentlyContinue
    New-Item -ItemType Directory -Path $tmp -Force | Out-Null
    $osTag = $(if ([int](Get-CimInstance Win32_OperatingSystem).BuildNumber -ge 22000) { 'Windows 11' } else { 'Windows 10' })
    $drv = @{}
    Get-CimInstance Win32_PnPSignedDriver | Where-Object { $_.DeviceID } | ForEach-Object { $drv[$_.DeviceID] = $_ }
    $before = @{}; foreach ($k in $drv.Keys) { $before[$k] = [string]$drv[$k].DriverVersion }
    $skipCls = 'Monitor', 'Processor', 'Volume', 'VolumeSnapshot', 'Computer', 'SoftwareDevice', 'SoftwareComponent', 'PrintQueue', 'DiskDrive', 'Keyboard', 'Mouse', 'HIDClass'
    $devs = @(Get-PnpDevice -PresentOnly -ErrorAction SilentlyContinue | Where-Object {
        $_.InstanceId -match '^(PCI|USB|HDAUDIO|INTELAUDIO|ACPI)\\' -and $_.Class -notin $skipCls -and
        -not ($_.InstanceId -match '^ACPI\\' -and $_.Status -eq 'OK') -and
        -not ($_.Class -eq 'Display' -and $_.InstanceId -match 'VEN_10DE') -and
        -not ($_.InstanceId -match '^USB\\(ROOT_HUB|VID_[0-9A-F]{4}&PID_[0-9A-F]{4}&MI_)')
    })
    Log "Catálogo Microsoft: verificando $($devs.Count) dispositivos (drivers publicados pelos fabricantes)..."
    $seen = @{}; $plan = @(); $t0 = Get-Date
    foreach ($d in $devs) {
        if (((Get-Date) - $t0).TotalMinutes -gt 15) { Log 'Catálogo: tempo de busca esgotado, seguindo com o que foi encontrado'; break }
        $ids = @((Get-PnpDeviceProperty -InstanceId $d.InstanceId -KeyName 'DEVPKEY_Device_HardwareIds' -ErrorAction SilentlyContinue).Data)
        if (-not $ids.Count -or $seen.ContainsKey($ids[0])) { continue }
        $seen[$ids[0]] = 1
        $cur = $(if ($drv[$d.InstanceId]) { [string]$drv[$d.InstanceId].DriverVersion } else { '' })
        $rows = @()
        foreach ($q in (Get-HwQueries $ids)) { try { $rows = @(Get-CatalogRows $q) } catch { $rows = @() }; if ($rows.Count) { break } }
        if (-not $rows.Count) { continue }
        $ok = @($rows | Where-Object { $_.Title -notmatch 'ARM64' -and (ToVer $_.Version) })
        $pref = @($ok | Where-Object { $_.Products -match [regex]::Escape($osTag) })
        if (-not $pref.Count) { $pref = @($ok | Where-Object { $_.Products -match 'Windows 1[01]' }) }
        $best = $pref | Sort-Object { ToVer $_.Version } -Descending | Select-Object -First 1
        if (-not $best) { continue }
        if ($cur -and (ToVer $cur) -and ((ToVer $best.Version) -le (ToVer $cur))) { continue }
        $plan += [pscustomobject]@{ Name = $(if ($d.FriendlyName) { $d.FriendlyName } else { $d.InstanceId }); Cur = $cur; New = $best.Version; Guid = $best.Guid; Title = $best.Title }
    }
    Log "Catálogo: $($plan.Count) driver(s) mais novo(s) encontrado(s)"
    $inst = 0
    foreach ($p in $plan) {
        try {
            Log ("  {0}: {1} -> {2}" -f $p.Name, $(if ($p.Cur) { $p.Cur } else { 'sem driver' }), $p.New)
            $url = Get-CatalogUrl $p.Guid
            if (-not $url) { Log '    sem arquivo .cab para baixar, pulado'; continue }
            $cab = Join-Path $tmp "$($p.Guid).cab"; $ex = Join-Path $tmp $p.Guid
            (New-CatClient).DownloadFile($url, $cab)
            New-Item -ItemType Directory -Path $ex -Force | Out-Null
            $x = Start-Process -FilePath 'expand.exe' -ArgumentList "-F:* `"$cab`" `"$ex`"" -Wait -PassThru -WindowStyle Hidden
            if (-not (Get-ChildItem $ex -Filter *.inf -Recurse -ErrorAction SilentlyContinue)) { Log '    pacote sem .inf, pulado'; continue }
            $pn = Start-Process -FilePath 'pnputil.exe' -ArgumentList "/add-driver `"$ex\*.inf`" /subdirs /install" -Wait -PassThru -WindowStyle Hidden
            if ($pn.ExitCode -in 0, 3010) { $inst++; Log '    instalado' } else { Log "    não aplicado (código $($pn.ExitCode))" }
        } catch { Log "    erro: $($_.Exception.Message)" }
    }
    Remove-Item $tmp -Recurse -Force -ErrorAction SilentlyContinue
    $n = 0
    Get-CimInstance Win32_PnPSignedDriver | Where-Object { $_.DeviceID } | ForEach-Object { if ($before.ContainsKey($_.DeviceID) -and $before[$_.DeviceID] -ne [string]$_.DriverVersion) { $n++ } }
    $n = [math]::Max($n, $inst)
    Log "Drivers da web: $n atualizado(s)"
    @{ updated = $n; found = $plan.Count }
}
function Get-ExeFromCmd($cmd) {
    $c = [Environment]::ExpandEnvironmentVariables([string]$cmd)
    $m = [regex]::Match($c, '^\s*"([^"]+)"'); if ($m.Success) { return $m.Groups[1].Value }
    $m = [regex]::Match($c, '^\s*(.+?\.(exe|cmd|bat|lnk|vbs))', 'IgnoreCase'); if ($m.Success) { return $m.Groups[1].Value }
    ($c -split '\s+')[0]
}
$GameRx = 'Steam|Epic ?Games|EpicGamesLauncher|Battle\.net|Blizzard|EADesktop|\bEA ?app|Origin|Ubisoft|Uplay|UbisoftConnect|GOG ?Galaxy|GalaxyClient|Riot ?Client|RiotClient|Rockstar|Xbox|GamingApp|Overwolf|CurseForge|Playnite|HoYoPlay|miHoYo|Wargaming|Amazon ?Games|itch\.io|Bethesda|Battlestate|Garena|Medal|Discord'
function Test-WinItem($exe, $name, $cmd) {
    if ("$name $cmd" -match 'CleanPano') { return 'cleanpano' }
    if ("$name $cmd" -match $GameRx) { return '' }
    if ($exe -and $exe.StartsWith($env:windir, [StringComparison]::OrdinalIgnoreCase)) { return 'windows' }
    if ($exe -and (Test-Path -LiteralPath $exe)) {
        $sig = Get-AuthenticodeSignature -LiteralPath $exe -ErrorAction SilentlyContinue
        if ($sig -and $sig.SignerCertificate -and $sig.SignerCertificate.Subject -match 'O=Microsoft Corporation') { return 'windows' }
    }
    ''
}
function Get-StartupItems {
    $out = New-Object System.Collections.ArrayList
    $sa = 'Software\Microsoft\Windows\CurrentVersion\Explorer\StartupApproved'
    $runs = @(
        @{ Key = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Run'; Appr = "HKCU:\$sa\Run" },
        @{ Key = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run'; Appr = "HKLM:\$sa\Run" },
        @{ Key = 'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Run'; Appr = "HKLM:\$sa\Run32" },
        @{ Key = 'HKCU:\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\Run'; Appr = "HKCU:\$sa\Run32" }
    )
    $list = @()
    foreach ($r in $runs) {
        $p = Get-ItemProperty -Path $r.Key -ErrorAction SilentlyContinue
        if ($p) { foreach ($n in ($p.PSObject.Properties | Where-Object { $_.Name -notlike 'PS*' })) { $list += @{ type = 'reg'; appr = $r.Appr; val = $n.Name; cmd = [string]$n.Value; exe = (Get-ExeFromCmd $n.Value) } } }
    }
    $sh = New-Object -ComObject WScript.Shell
    foreach ($f in @(@{ Dir = [Environment]::GetFolderPath('Startup'); Appr = "HKCU:\$sa\StartupFolder" }, @{ Dir = [Environment]::GetFolderPath('CommonStartup'); Appr = "HKLM:\$sa\StartupFolder" })) {
        Get-ChildItem -Path $f.Dir -File -ErrorAction SilentlyContinue | Where-Object { $_.Name -ne 'desktop.ini' } | ForEach-Object {
            $tg = $_.FullName; if ($_.Extension -eq '.lnk') { try { $tg = $sh.CreateShortcut($_.FullName).TargetPath } catch {} }
            $list += @{ type = 'folder'; appr = $f.Appr; val = $_.Name; cmd = $tg; exe = $tg }
        }
    }
    foreach ($e in $list) {
        $en = $true
        $b = (Get-ItemProperty -Path $e.appr -Name $e.val -ErrorAction SilentlyContinue).($e.val)
        if ($b -is [byte[]] -and $b.Length -gt 0) { $en = (($b[0] -band 1) -eq 0) }
        $vi = $null; if ($e.exe -and (Test-Path -LiteralPath $e.exe -PathType Leaf)) { $vi = (Get-Item -LiteralPath $e.exe).VersionInfo }
        $nm = $(if ($vi -and $vi.FileDescription) { $vi.FileDescription.Trim() } else { [IO.Path]::GetFileNameWithoutExtension($e.val) })
        [void]$out.Add(@{ id = "$($e.type)|$($e.appr)|$($e.val)"; type = $e.type; appr = $e.appr; val = $e.val; name = $nm; publisher = $(if ($vi) { [string]$vi.CompanyName } else { '' }); enabled = $en; exe = [string]$e.exe; kind = (Test-WinItem $e.exe $e.val $e.cmd) })
    }
    $base = 'HKCU:\Software\Classes\Local Settings\Software\Microsoft\Windows\CurrentVersion\AppModel\SystemAppData'
    Get-ChildItem -Path $base -ErrorAction SilentlyContinue | ForEach-Object {
        $pkg = $_.PSChildName
        Get-ChildItem -Path $_.PSPath -ErrorAction SilentlyContinue | ForEach-Object {
            $st = (Get-ItemProperty -Path $_.PSPath -ErrorAction SilentlyContinue).State
            if ($null -ne $st -and $_.PSChildName -ne 'Schemas') {
                $nm = ($pkg -split '_')[0] -replace '^[0-9A-F]+\.', ''
                [void]$out.Add(@{ id = "appx|$($_.PSPath)"; type = 'appx'; appr = $_.PSPath; val = 'State'; name = $nm; publisher = ''; enabled = ($st -in 2, 4); pkg = $pkg; kind = $(if ($pkg -match $GameRx) { '' } elseif ($pkg -match '^(Microsoft|MicrosoftWindows|Windows)\.') { 'windows' } else { '' }) })
            }
        }
    }
    # tarefas agendadas que abrem programas no logon (muitos launchers de jogo usam isso)
    try {
        foreach ($tk in @(Get-ScheduledTask -ErrorAction SilentlyContinue | Where-Object { $_.TaskPath -notlike '\Microsoft\*' })) {
            $lg = @($tk.Triggers | Where-Object { $_.CimClass.CimClassName -in 'MSFT_TaskLogonTrigger', 'MSFT_TaskBootTrigger' })
            if (-not $lg.Count) { continue }
            $ac = @($tk.Actions | Where-Object { $_.Execute }) | Select-Object -First 1
            if (-not $ac) { continue }
            $exe = Get-ExeFromCmd ('"' + [Environment]::ExpandEnvironmentVariables($ac.Execute).Trim('"') + '"')
            $all = "$($tk.TaskName) $exe $($ac.Arguments)"
            if ($all -notmatch $GameRx -and $all -match 'updat|telemetry|crash|repair|maintenance') { continue }  # atualizadores ficam
            $vi = $null; if ($exe -and (Test-Path -LiteralPath $exe -PathType Leaf)) { $vi = (Get-Item -LiteralPath $exe).VersionInfo }
            $nm = $(if ($vi -and $vi.FileDescription) { $vi.FileDescription.Trim() } else { $tk.TaskName })
            [void]$out.Add(@{ id = "task|$($tk.TaskPath)|$($tk.TaskName)"; type = 'task'; appr = $tk.TaskPath; val = $tk.TaskName; name = $nm; publisher = $(if ($vi) { [string]$vi.CompanyName } else { '' }); enabled = ($tk.State -ne 'Disabled'); exe = [string]$exe; kind = (Test-WinItem $exe $tk.TaskName $all) })
        }
    } catch {}
    @($out.ToArray())
}
# fecha os programas que vão sair da inicialização (alguns não aceitam ser desativados abertos)
function Stop-StartupProcs($items) {
    $exes = @{}; $dirs = New-Object System.Collections.ArrayList; $pkgs = New-Object System.Collections.ArrayList
    foreach ($it in $items) {
        if ($it.type -eq 'appx') { if ($it.pkg) { [void]$pkgs.Add(('\windowsapps\' + (([string]$it.pkg) -split '_')[0]).ToLower()) }; continue }
        $e = [string]$it.exe
        if (-not $e -or $e.StartsWith($env:windir, [StringComparison]::OrdinalIgnoreCase)) { continue }
        $exes[$e.ToLower()] = $true
        $d = ''; try { $d = ([string](Split-Path $e -Parent)).TrimEnd('\') } catch {}
        # fecha a pasta inteira só quando ela é a pasta do próprio programa
        if ($d -and $d.Split('\').Count -ge 2 -and $d -notmatch '\\(Program Files( \(x86\))?|ProgramData|Windows|AppData|AppData\\(Local|Roaming|LocalLow)|Programs|Users|Users\\[^\\]+|Desktop|Documents|Downloads)$') { [void]$dirs.Add($d.ToLower() + '\') }
    }
    $kill = New-Object System.Collections.ArrayList
    foreach ($p in @(Get-Process -ErrorAction SilentlyContinue)) {
        if ($p.Id -eq $PID) { continue }
        $pp = ''; try { $pp = [string]$p.Path } catch {}
        if (-not $pp -or $pp -match 'CleanPano') { continue }
        $l = $pp.ToLower(); $hit = $exes.ContainsKey($l)
        if (-not $hit) { foreach ($d in $dirs) { if ($l.StartsWith($d)) { $hit = $true; break } } }
        if (-not $hit) { foreach ($k in $pkgs) { if ($l.Contains($k)) { $hit = $true; break } } }
        if ($hit) { [void]$kill.Add($p) }
    }
    if (-not $kill.Count) { return 0 }
    foreach ($p in $kill) { try { if ($p.MainWindowHandle -ne [IntPtr]::Zero) { [void]$p.CloseMainWindow() } } catch {} }
    Start-Sleep -Milliseconds 1500
    $names = @{}
    foreach ($p in $kill) { try { $p.Refresh(); if (-not $p.HasExited) { Stop-Process -Id $p.Id -Force -ErrorAction SilentlyContinue }; $names[$p.ProcessName] = $true } catch {} }
    Start-Sleep -Milliseconds 800
    foreach ($n in $names.Keys) { Log "  fechado: $n" }
    $names.Count
}
function Set-StartupItem($it, [bool]$on) {
    if ($it.type -eq 'task') { if ($on) { Enable-ScheduledTask -TaskPath $it.appr -TaskName $it.val -ErrorAction Stop | Out-Null } else { Disable-ScheduledTask -TaskPath $it.appr -TaskName $it.val -ErrorAction Stop | Out-Null }; return }
    if ($it.type -eq 'appx') { Set-ItemProperty -Path $it.appr -Name 'State' -Value $(if ($on) { 2 } else { 1 }) -Type DWord -ErrorAction Stop; return }
    if (-not (Test-Path $it.appr)) { New-Item -Path $it.appr -Force | Out-Null }
    $ft = [BitConverter]::GetBytes([DateTime]::Now.ToFileTime())
    $v = [byte[]]($(if ($on) { 2 } else { 3 }), 0, 0, 0) + $(if ($on) { [byte[]](0, 0, 0, 0, 0, 0, 0, 0) } else { $ft })
    Set-ItemProperty -Path $it.appr -Name $it.val -Value ([byte[]]$v) -Type Binary -ErrorAction Stop
}
# lista "manter": programas que o usuário desmarcou e que o botão nunca desativa.
# Fica no registro (HKLM\SOFTWARE\CleanPano), fora da pasta do app, para valer mesmo depois de desinstalar e instalar de novo.
$KeepKey = 'HKLM:\SOFTWARE\CleanPano'
function Get-StartupKeep { try { @((Get-ItemProperty -Path $KeepKey -Name StartupKeep -ErrorAction Stop).StartupKeep | Where-Object { $_ }) } catch { @() } }
function Set-StartupKeep($ids) {
    if (-not (Test-Path $KeepKey)) { New-Item -Path $KeepKey -Force | Out-Null }
    $ids = @($ids | Where-Object { $_ } | Select-Object -Unique)
    if ($ids.Count) { New-ItemProperty -Path $KeepKey -Name StartupKeep -PropertyType MultiString -Value ([string[]]$ids) -Force | Out-Null }
    else { Remove-ItemProperty -Path $KeepKey -Name StartupKeep -ErrorAction SilentlyContinue }
}
function Set-KeepOne([string]$id, [bool]$keep) {
    $k = @(Get-StartupKeep | Where-Object { $_ -ne $id }); if ($keep) { $k += $id }; Set-StartupKeep $k
}
function Get-StartupState {
    $items = Get-StartupItems
    $kp = @(Get-StartupKeep); foreach ($i in $items) { $i.keep = ($kp -contains $i.id) }
    $f = Join-Path $sync.DataDir 'startup-disabled.json'
    $mine = @(); if (Test-Path $f) { try { $mine = @(Get-Content $f -Raw -Encoding UTF8 | ConvertFrom-Json) } catch {} }
    @{ items = $items; active = @($items | Where-Object { $_.enabled -and -not $_.kind -and -not $_.keep }).Count; mine = $mine.Count }
}
'@
. ([ScriptBlock]::Create($Core))

$J_Analyze = @'
$res = @{}
foreach ($t in Get-Targets) {
    $f = @(Get-TargetFiles $t)
    $res[$t.Name] = [double](($f | Measure-Object Length -Sum).Sum)
    Log ("{0,-28} {1,7} arquivos   {2}" -f $t.Name, $f.Count, (Fmt $res[$t.Name]))
}
$res['Lixeira'] = Get-RecycleSize
Log ("{0,-28} {1,7}            {2}" -f 'Lixeira', '', (Fmt $res['Lixeira']))
$sync.Result = $res
'@

$J_Clean = @'
$r = Invoke-Clean $Selected $true
Log ("TOTAL LIBERADO: {0}  (arquivos em uso foram ignorados)" -f (Fmt $r.freed))
$sync.Result = $r.freed
'@

$J_Dism = @'
Log 'DISM: removendo componentes antigos (pode levar 10-30 min)...'
Run-Exe 'dism.exe' @('/Online', '/Cleanup-Image', '/StartComponentCleanup')
'@

$J_Sfc = @'
Log 'SFC: verificando arquivos do sistema (~15 min)...'
Run-Exe 'sfc.exe' @('/scannow')
'@

$J_Startup = @'
$st = Get-StartupState
Log "$($st.active) programa(s) de terceiros iniciam com o Windows"
$sync.Result = $st
'@
$J_StartupOff = @'
$f = Join-Path $sync.DataDir 'startup-disabled.json'
$mine = New-Object System.Collections.ArrayList
if (Test-Path $f) { try { foreach ($x in @(Get-Content $f -Raw -Encoding UTF8 | ConvertFrom-Json)) { [void]$mine.Add($x) } } catch {} }
$n = 0
$kp = @(Get-StartupKeep)
$all = @(Get-StartupItems | Where-Object { $_.enabled -and -not $_.kind })
$todo = @($all | Where-Object { $kp -notcontains $_.id })
foreach ($it in @($all | Where-Object { $kp -contains $_.id })) { Log "  mantido (desmarcado pelo usuário): $($it.name)" }
if ($todo.Count) { Log 'Fechando os programas antes de desativar...'; try { [void](Stop-StartupProcs $todo) } catch { Log "  aviso: $($_.Exception.Message)" } }
foreach ($it in $todo) {
    try { Set-StartupItem $it $false; $n++; [void]$mine.Add(@{ id = $it.id; type = $it.type; appr = $it.appr; val = $it.val; name = $it.name }); Log "  desativado: $($it.name)" } catch { Log "  não foi possível desativar $($it.name): $($_.Exception.Message)" }
}
ConvertTo-Json -InputObject @($mine.ToArray()) -Depth 4 | Set-Content -Path $f -Encoding UTF8
Log "$n programa(s) removido(s) da inicialização"
$st = Get-StartupState; $st.changed = $n
$sync.Result = $st
'@
$J_StartupSet = @'
# reativa um programa da lista e marca como "manter" (o botão não desativa mais)
$it = @(Get-StartupItems | Where-Object { $_.id -eq [string]$Id }) | Select-Object -First 1
if ($it) {
    try {
        Set-StartupItem $it $true
        Set-KeepOne $it.id $true
        $f = Join-Path $sync.DataDir 'startup-disabled.json'
        if (Test-Path $f) { try { $rest = @(Get-Content $f -Raw -Encoding UTF8 | ConvertFrom-Json | Where-Object { $_.id -ne $it.id }); ConvertTo-Json -InputObject @($rest) -Depth 4 | Set-Content -Path $f -Encoding UTF8 } catch {} }
        Log "  reativado e mantido na inicialização: $($it.name)"
    } catch { Log "  não foi possível reativar $($it.name): $($_.Exception.Message)" }
} else { Log '  programa não encontrado na lista de inicialização' }
$sync.Result = Get-StartupState
'@
$J_StartupUndo = @'
$f = Join-Path $sync.DataDir 'startup-disabled.json'
$n = 0
if (Test-Path $f) {
    foreach ($x in @(Get-Content $f -Raw -Encoding UTF8 | ConvertFrom-Json)) { try { Set-StartupItem $x $true; $n++; Log "  reativado: $($x.name)" } catch {} }
    Remove-Item $f -Force -ErrorAction SilentlyContinue
}
Log "$n programa(s) reativado(s) na inicialização"
$st = Get-StartupState; $st.changed = $n
$sync.Result = $st
'@
$J_Repair = @'
Log 'Reparo do Windows 1/2: verificando a imagem do sistema (DISM RestoreHealth, ~10-20 min)...'
Run-Exe 'dism.exe' @('/Online', '/Cleanup-Image', '/RestoreHealth')
$d = $LASTEXITCODE
Log 'Reparo do Windows 2/2: verificando arquivos do sistema (SFC, ~15 min)...'
$lines = New-Object System.Collections.ArrayList
& sfc.exe /scannow 2>&1 | ForEach-Object { $s = (($_ | Out-String) -replace "`0", '').Split("`r") | Where-Object { $_.Trim() } | Select-Object -Last 1; if ($s -and $s -notmatch '\d+%') { [void]$lines.Add($s.Trim()); Log $s.Trim() } }
$all = ($lines -join ' ')
$res = $(if ($all -match 'did not find any integrity|não encontrou nenhuma viola|no encontró ninguna infracción') { 'ok' } elseif ($all -match 'successfully repaired|reparou-os com êxito|los reparó correctamente') { 'fixed' } elseif ($all -match 'unable to fix|não pôde reparar|no pudo reparar') { 'partial' } else { 'done' })
Log "Reparo do Windows concluído ($res). Reinicie o PC para finalizar."
$sync.Result = @{ result = $res; dism = $d }
'@


$J_TopProc = @'
Get-Process | Sort-Object WorkingSet64 -Descending | Select-Object -First 10 | ForEach-Object {
    Log ("{0,-28} RAM {1,10}   CPU {2,8}s" -f $_.Name, (Fmt $_.WorkingSet64), [math]::Round($_.CPU, 1))
}
'@

$J_Ping = @'
$p = New-Object System.Net.NetworkInformation.Ping
$all = @()
foreach ($h in '1.1.1.1', '8.8.8.8', 'google.com') {
    $t = @(1..4 | ForEach-Object { try { $r = $p.Send($h, 2000); if ($r.Status -eq 'Success') { [int]$r.RoundtripTime } } catch {} })
    if ($t.Count) { $avg = [math]::Round(($t | Measure-Object -Average).Average); $all += $avg; Log ("{0,-12} média {1} ms  ({2}/4 ok)" -f $h, $avg, $t.Count) }
    else { Log "$h sem resposta" }
}
$sync.Result = $(if ($all.Count) { [math]::Round(($all | Measure-Object -Average).Average) } else { $null })
'@

$J_Speed = @'
Log 'Baixando 25 MB de teste (Cloudflare)...'
try {
    $wc = New-Object Net.WebClient
    $sw = [Diagnostics.Stopwatch]::StartNew()
    $d = $wc.DownloadData('https://speed.cloudflare.com/__down?bytes=25000000')
    $sw.Stop()
    $mbps = [math]::Round(($d.Length * 8) / $sw.Elapsed.TotalSeconds / 1e6, 1)
    Log "Download: $mbps Mbps"
    $sync.Result = $mbps
} catch { Log "Falha no teste: $($_.Exception.Message)" }
'@

$J_FlushDns = @'
Clear-DnsClientCache
Run-Exe 'ipconfig.exe' @('/flushdns')
'@

$J_SetDns = @'
$ads = @(Get-NetAdapter -Physical | Where-Object Status -eq 'Up')
if (-not $ads.Count) { Log 'Nenhum adaptador físico ativo'; return }
foreach ($a in $ads) {
    switch ($Mode) {
        'cf'   { Set-DnsClientServerAddress -InterfaceIndex $a.ifIndex -ServerAddresses '1.1.1.1', '1.0.0.1'; Log "DNS Cloudflare aplicado em $($a.Name)" }
        'g'    { Set-DnsClientServerAddress -InterfaceIndex $a.ifIndex -ServerAddresses '8.8.8.8', '8.8.4.4'; Log "DNS Google aplicado em $($a.Name)" }
        'auto' { Set-DnsClientServerAddress -InterfaceIndex $a.ifIndex -ResetServerAddresses; Log "DNS automático (provedor) em $($a.Name)" }
    }
}
Clear-DnsClientCache
'@

$J_ResetNet = @'
Run-Exe 'netsh.exe' @('winsock', 'reset')
Run-Exe 'netsh.exe' @('int', 'ip', 'reset')
Clear-DnsClientCache
Log 'Pilha de rede resetada. REINICIE o computador.'
'@

$J_Drivers = @'
$rows = @(Get-CimInstance Win32_PnPSignedDriver | Where-Object DeviceName | Sort-Object DeviceClass, DeviceName | ForEach-Object {
    [pscustomobject]@{ Classe = $_.DeviceClass; Dispositivo = $_.DeviceName; Versao = $_.DriverVersion; Data = $(if ($_.DriverDate) { $_.DriverDate.ToString('yyyy-MM-dd') } else { '' }); Fabricante = $_.Manufacturer }
})
$csv = Join-Path $sync.LogDir ("drivers_{0:yyyy-MM-dd}.csv" -f (Get-Date))
$rows | Export-Csv $csv -NoTypeInformation -Encoding UTF8
Log "$($rows.Count) drivers listados -> $csv"
$sync.Result = $rows
'@

$J_BadDev = @'
$rows = @(Get-PnpDevice -PresentOnly | Where-Object { $_.Status -in 'Error', 'Degraded', 'Unknown' } | ForEach-Object {
    [pscustomobject]@{ Status = [string]$_.Status; Classe = $_.Class; Nome = $_.FriendlyName; Id = $_.InstanceId }
})
if ($rows.Count) { foreach ($r in $rows) { Log "PROBLEMA: $($r.Nome) [$($r.Status)]" } } else { Log 'Nenhum dispositivo com problema' }
$sync.Result = $rows
'@

$J_WUSearch = @'
Log "Buscando atualizações ($Type) no Windows Update..."
try {
    $s = New-Object -ComObject Microsoft.Update.Session
    $r = $s.CreateUpdateSearcher().Search("IsInstalled=0 and IsHidden=0 and Type='$Type'")
    foreach ($u in $r.Updates) { Log "  - $($u.Title)" }
    Log "$($r.Updates.Count) pendente(s)"
    $sync.Result = [int]$r.Updates.Count
} catch { Log "Erro no Windows Update: $($_.Exception.Message)"; $sync.Result = 0 }
'@

$J_WUInstall = @'
try {
    $s = New-Object -ComObject Microsoft.Update.Session
    $r = $s.CreateUpdateSearcher().Search("IsInstalled=0 and IsHidden=0 and Type='$Type'")
    $col = New-Object -ComObject Microsoft.Update.UpdateColl
    foreach ($u in $r.Updates) { if (-not $u.EulaAccepted) { $u.AcceptEula() }; [void]$col.Add($u) }
    Log "Baixando $($col.Count) atualização(ões)..."
    $dl = $s.CreateUpdateDownloader(); $dl.Updates = $col; [void]$dl.Download()
    Log 'Instalando...'
    $in = $s.CreateUpdateInstaller(); $in.Updates = $col; $res = $in.Install()
    $codes = @{ 2 = 'Sucesso'; 3 = 'Sucesso com erros'; 4 = 'Falhou'; 5 = 'Cancelado' }
    Log ("Resultado: {0}. Reiniciar necessário: {1}" -f $codes[[int]$res.ResultCode], $(if ($res.RebootRequired) { 'SIM' } else { 'não' }))
} catch { Log "Erro: $($_.Exception.Message)" }
'@

$J_Winget = @'
if (-not (Get-Command winget -ErrorAction SilentlyContinue)) { Log 'winget não encontrado (instale "App Installer" na Microsoft Store)'; return }
if ($All) { Run-Exe 'winget' @('upgrade', '--all', '--silent', '--accept-source-agreements', '--accept-package-agreements') }
else { Run-Exe 'winget' @('upgrade', '--accept-source-agreements') }
'@

$J_Restore = @'
try {
    Enable-ComputerRestore -Drive "$env:SystemDrive\" -ErrorAction SilentlyContinue
    Checkpoint-Computer -Description "CleanPano $(Get-Date -f 'yyyy-MM-dd HH:mm')" -RestorePointType MODIFY_SETTINGS -ErrorAction Stop
    Log 'Ponto de restauração criado'
} catch { Log "Não foi possível criar (o Windows permite 1 a cada 24h): $($_.Exception.Message)" }
'@


$J_Optimize = @'
$plan = @()
if ($DoRestore) { $plan += , @('restore', 'Ponto de restauração') }
$plan += , @('temp', 'Arquivos temporários')
$plan += , @('logs', 'Logs e relatórios de erro')
$plan += , @('browsers', 'Cache dos navegadores')
$plan += , @('system', 'Caches do Windows e lixeira')
$plan += , @('net', 'DNS automático e cache')
if ($DoGpu -or $DoDrivers) { $plan += , @('hw', 'Reconhecer hardware') }
if ($DoGpu) { $plan += , @('gpu', 'Driver da placa de vídeo') }
if ($DoDrivers) { $plan += , @('drivers', 'Atualizar drivers') }
if ($DoWinget) { $plan += , @('winget', 'Atualizar programas') }
if ($DoDism) { $plan += , @('dism', 'Limpeza profunda do Windows (DISM)') }
$sync.Steps = @($plan | ForEach-Object { [hashtable]::Synchronized(@{ id = $_[0]; name = $_[1]; state = 'wait'; detail = '' }) })
function Step($id, $state, $detail) { foreach ($s in $sync.Steps) { if ($s.id -eq $id) { $s.state = $state; if ($null -ne $detail) { $s.detail = [string]$detail } } } }
$groups = @{
    temp     = @('Temp do usuário', 'Temp do Windows')
    logs     = @('Relatórios de erro', 'Logs do Windows')
    browsers = @('Cache do Google Chrome', 'Cache do Microsoft Edge', 'Cache do Firefox')
    system   = @('Cache do Windows Update', 'Cache de miniaturas', 'Cache de shaders (DirectX)', 'Lixeira')
}
$total = 0; $hwOK = $false; $inv = $null
foreach ($p in $plan) {
    $id = $p[0]
    if ($id -in 'gpu', 'drivers' -and -not $hwOK) { Step $id 'skip' 'hardware não reconhecido'; Log "$($p[1]): pulado (hardware não reconhecido)"; continue }
    Step $id 'run' $null
    Log "-- $($p[1])"
    try {
        if ($id -eq 'hw') {
            $inv = Get-HwInventory
            $n = @($inv.items).Count
            $hwOK = $n -gt 0
            Step $id $(if ($hwOK) { 'ok' } else { 'err' }) $(if ($hwOK) { "$n componentes reconhecidos" } else { 'hardware não reconhecido' })
        }
        elseif ($id -eq 'restore') {
            try {
                Enable-ComputerRestore -Drive "$env:SystemDrive\" -ErrorAction SilentlyContinue
                Checkpoint-Computer -Description "CleanPano $(Get-Date -f 'yyyy-MM-dd HH:mm')" -RestorePointType MODIFY_SETTINGS -ErrorAction Stop
                Log 'Ponto de restauração criado'; Step $id 'ok' 'criado agora'
            } catch { Log 'Ponto de restauração: o Windows só permite 1 a cada 24h'; Step $id 'skip' 'já existe um nas últimas 24h' }
        }
        elseif ($groups.ContainsKey($id)) {
            $r = Invoke-Clean $groups[$id] $true
            $total += $r.freed
            $d = Fmt $r.freed
            if ($r.skipped.Count) { $d += " · pulado: $($r.skipped -join ', ') (aberto)" }
            Step $id 'ok' $d
        }
        elseif ($id -eq 'net') {
            $nd = 0
            foreach ($a in @(Get-NetAdapter -Physical -ErrorAction SilentlyContinue | Where-Object Status -eq 'Up')) {
                try { Set-DnsClientServerAddress -InterfaceIndex $a.ifIndex -ResetServerAddresses -ErrorAction Stop; $nd++; Log "DNS automático (provedor) em $($a.Name)" } catch { Log "não foi possível ajustar o DNS de $($a.Name): $($_.Exception.Message)" }
            }
            Clear-DnsClientCache
            Run-Exe 'ipconfig.exe' @('/flushdns')
            Run-Exe 'netsh.exe' @('interface', 'ip', 'delete', 'arpcache')
            Step $id 'ok' $(if ($nd) { 'DNS automático · cache e ARP limpos' } else { 'DNS e ARP limpos' })
        }
        elseif ($id -eq 'dism') {
            $cbs = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing'
            if ((Test-Path "$cbs\RebootPending") -or (Test-Path "$cbs\PackagesPending")) {
                # com atualização esperando reiniciar o DISM sempre recusa a limpeza; não é erro
                Log 'DISM: o Windows tem atualização esperando reiniciar. A limpeza profunda roda depois que o PC for reiniciado.'
                Step $id 'skip' 'reinicie o PC para liberar'
            } else {
                $before = (New-Object System.IO.DriveInfo 'C').TotalFreeSpace
                Log 'DISM: removendo versões antigas de componentes (pode levar 10-30 min)...'
                $global:LASTEXITCODE = 0
                $dout = New-Object System.Collections.ArrayList
                & dism.exe /Online /Cleanup-Image /StartComponentCleanup 2>&1 | ForEach-Object {
                    $ln = (($_ | Out-String) -replace "`0", '').Split("`r") | Where-Object { $_.Trim() } | Select-Object -Last 1
                    if ($ln -and $ln -notmatch '^\s*[-\\|/]\s*$' -and $ln -notmatch '[█▒]' -and $ln -notmatch '\d+[.,]\d+%') { Log $ln.Trim(); [void]$dout.Add($ln.Trim()) }
                }
                $code = [int64]$LASTEXITCODE
                $hex = '0x{0:X8}' -f ($code -band 4294967295L)
                $all = ($dout -join ' ')
                $gain = [math]::Max(0, (New-Object System.IO.DriveInfo 'C').TotalFreeSpace - $before)
                $total += $gain
                if ($code -in 0, 3010) { Step $id 'ok' $(if ($gain -gt 1MB) { "$(Fmt $gain) liberados" } else { 'nada antigo para remover' }) }
                elseif ($hex -in '0x800F0806', '0x800F082F' -or $all -match '0x800f0806|0x800f082f|pending|pendente|pendiente') {
                    Log "DISM: recusado pelo Windows por atualização pendente ($hex). Reinicie o PC e otimize de novo."
                    Step $id 'skip' 'reinicie o PC para liberar'
                }
                else { Log "DISM terminou com erro $hex"; Step $id 'err' "erro $hex (veja Atividade)" }
            }
        }
        elseif ($id -eq 'gpu') {
            $gpus = @(Get-CimInstance Win32_VideoController | Where-Object { $_.Name -notmatch 'Basic|Remote|Virtual|Mirror|Parsec|Meta|Indirect' -and $_.PNPDeviceID -match '^PCI' })
            if (-not $gpus.Count) { Step $id 'skip' 'nenhuma placa de vídeo encontrada' }
            else {
                $res = @(); $gerr = $false
                Log "Placas de vídeo: $(($gpus | ForEach-Object { $_.Name }) -join ', ')"
                $col = @()
                if ($UseWU) {
                $s = New-Object -ComObject Microsoft.Update.Session
                $sr = $s.CreateUpdateSearcher().Search("IsInstalled=0 and IsHidden=0 and Type='Driver'")
                $col = New-Object -ComObject Microsoft.Update.UpdateColl
                foreach ($u in $sr.Updates) { if ($u.DriverClass -eq 'Display') { Log "  - $($u.Title)"; if (-not $u.EulaAccepted) { $u.AcceptEula() }; [void]$col.Add($u) } }
                if ($col.Count) {
                    Log "Instalando $($col.Count) driver(s) de vídeo do Windows Update..."
                    $dl = $s.CreateUpdateDownloader(); $dl.Updates = $col; [void]$dl.Download()
                    $in = $s.CreateUpdateInstaller(); $in.Updates = $col; [void]$in.Install()
                    $res += "$($col.Count) driver(s) de vídeo via Windows Update"
                }
                }
                foreach ($g in @($gpus | Where-Object { $_.Name -match 'NVIDIA' -and $_.Name -match 'GeForce|RTX|GTX' -and $_.Name -notmatch 'Quadro|RTX A\d|Tesla' })) {
                    try {
                        $cur = $null
                        $p = ([string]$g.DriverVersion).Split('.')
                        if ($p.Count -ge 4) { $dg = $p[2] + $p[3]; $dg = $dg.Substring([math]::Max(0, $dg.Length - 5)); $cur = $dg.Substring(0, 3) + '.' + $dg.Substring(3) }
                        $api = 'https://gfwsl.geforce.com/services_toolkit/services/com/nvidia/services/AjaxDriverService.php?func=DriverManualLookup&psid=120&pfid=929&osID=57&languageCode=1033&isWHQL=1&dch=1&sort1=0&numberOfResults=1'
                        $di = ((New-Object Net.WebClient).DownloadString($api) | ConvertFrom-Json).IDS[0].downloadInfo
                        $new = [string]$di.Version; $url = [string]$di.DownloadURL
                        if ($cur -and ([version]$new -le [version]$cur)) { Log "NVIDIA: já na versão mais nova ($cur)"; $res += "NVIDIA já na versão mais nova ($cur)"; continue }
                        if (Get-CimInstance Win32_Battery) { $url = $url -replace '-desktop-', '-notebook-' }
                        $dir = Join-Path $env:TEMP 'CleanPano'; New-Item -ItemType Directory -Path $dir -Force | Out-Null
                        $file = Join-Path $dir "nvidia-$new.exe"
                        Log "NVIDIA: baixando driver $new (~800 MB)..."
                        try { Start-BitsTransfer -Source $url -Destination $file -ErrorAction Stop } catch { (New-Object Net.WebClient).DownloadFile($url, $file) }
                        if (-not (Test-Path $file) -or (Get-Item $file).Length -lt 100MB) { throw 'download incompleto do driver' }
                        $seven = Join-Path $dir '7zr.exe'
                        if (-not (Test-Path $seven)) { Log 'NVIDIA: baixando extrator 7-Zip (oficial)...'; (New-Object Net.WebClient).DownloadFile('https://www.7-zip.org/a/7zr.exe', $seven) }
                        $ex = Join-Path $dir "nvidia-$new"
                        Remove-Item $ex -Recurse -Force -ErrorAction SilentlyContinue
                        Log 'NVIDIA: extraindo instalador...'
                        $z = Start-Process -FilePath $seven -ArgumentList 'x', "`"$file`"", "-o`"$ex`"", '-y' -Wait -PassThru -WindowStyle Hidden
                        $setup = Join-Path $ex 'setup.exe'
                        if (-not (Test-Path $setup)) { throw "não foi possível extrair o instalador (7-Zip código $($z.ExitCode))" }
                        Log "NVIDIA: instalando $new (a tela pode piscar)..."
                        $pr = Start-Process -FilePath $setup -ArgumentList '-s', '-noreboot', '-noeula' -PassThru -WindowStyle Hidden
                        if (-not $pr.WaitForExit(1800000)) { try { $pr.Kill() } catch {}; throw 'instalação passou de 30 minutos e foi cancelada' }
                        Remove-Item $file, $ex -Recurse -Force -ErrorAction SilentlyContinue
                        Remove-Item 'C:\NVIDIA\DisplayDriver' -Recurse -Force -ErrorAction SilentlyContinue
                        if ($pr.ExitCode -in 0, 1) { Log "NVIDIA: $cur → $new instalado"; $res += "NVIDIA $cur → $new instalado" }
                        else { Log "NVIDIA: falha na instalação (código $($pr.ExitCode))"; $res += "NVIDIA: falha na instalação (código $($pr.ExitCode))"; $gerr = $true }
                    } catch { Log "NVIDIA: erro - $($_.Exception.Message)"; $res += 'NVIDIA: falhou (veja Atividade)'; $gerr = $true }
                }
                foreach ($g in @($gpus | Where-Object { $_.Name -match 'AMD|Radeon|Intel' })) {
                    $res += "$($g.Name): atualizado na etapa de drivers pela web"
                }
                if (-not $res.Count) { $res += 'concluído' }
                Step $id $(if ($gerr) { 'err' } else { 'ok' }) ($res -join ' · ')
            }
        }
        elseif ($id -eq 'drivers') {
            $txt = @(); $derr = $false
            try {
                $w = Invoke-WebDrivers
                $txt += $(if ($w.updated -gt 0) { "$($w.updated) atualizado(s) pela web" } else { 'todos já atualizados (web)' })
            } catch { Log "Drivers da web: erro - $($_.Exception.Message)"; $txt += 'web: falhou (veja Atividade)'; $derr = $true }
            if ($UseWU) {
                Log 'Procurando drivers no Windows Update (opção ligada)...'
                $s = New-Object -ComObject Microsoft.Update.Session
                $sr = $s.CreateUpdateSearcher().Search("IsInstalled=0 and IsHidden=0 and Type='Driver'")
                if ($sr.Updates.Count) {
                    $col = New-Object -ComObject Microsoft.Update.UpdateColl
                    foreach ($u in $sr.Updates) { Log "  - $($u.Title)"; if (-not $u.EulaAccepted) { $u.AcceptEula() }; [void]$col.Add($u) }
                    $dl = $s.CreateUpdateDownloader(); $dl.Updates = $col; [void]$dl.Download()
                    $in = $s.CreateUpdateInstaller(); $in.Updates = $col; $r2 = $in.Install()
                    $txt += "$($col.Count) via Windows Update"
                    if ($r2.RebootRequired) { $txt += 'reinicie o PC' }
                }
            }
            Step $id $(if ($derr) { 'err' } else { 'ok' }) ($txt -join ' · ')
        }
        elseif ($id -eq 'winget') {
            if (-not (Get-Command winget -ErrorAction SilentlyContinue)) { Step $id 'skip' 'winget não instalado' }
            else { Run-Exe 'winget' @('upgrade', '--all', '--silent', '--accept-source-agreements', '--accept-package-agreements'); Step $id 'ok' 'concluído' }
        }
    } catch { Log "Erro em $($p[1]): $($_.Exception.Message)"; Step $id 'err' 'falhou (veja Atividade)' }
}
Log ("OTIMIZAÇÃO CONCLUÍDA · {0} liberados" -f (Fmt $total))
$sync.Result = @{ hw = $inv; freed = [double]$total; steps = @($sync.Steps | ForEach-Object { @{ id = $_.id; name = $_.name; state = $_.state; detail = $_.detail } }) }
'@


$J_Hardware = @'
$sync.Result = Get-HwInventory
'@


$J_WebDrivers = @'
try { $sync.Result = Invoke-WebDrivers } catch { Log "Drivers da web: erro - $($_.Exception.Message)"; $sync.Result = $null }
'@

$Port = 8765
$UiDir = Join-Path $PSScriptRoot 'ui'
$UiFile = Join-Path $UiDir 'index.html'
$Mime = @{ js = 'text/javascript; charset=utf-8'; woff2 = 'font/woff2'; ico = 'image/x-icon'; png = 'image/png'; svg = 'image/svg+xml'; webp = 'image/webp'; css = 'text/css; charset=utf-8' }
$ErrFile = Join-Path $LogDir 'server_error.txt'
$script:CpuName = ((Get-CimInstance Win32_Processor | Select-Object -First 1).Name).Trim()
$Tasks = @{ analyze = $J_Analyze; clean = $J_Clean; dism = $J_Dism; sfc = $J_Sfc; startup = $J_Startup; startupoff = $J_StartupOff; startupundo = $J_StartupUndo; startupset = $J_StartupSet; repair = $J_Repair; topproc = $J_TopProc; ping = $J_Ping; speed = $J_Speed; flushdns = $J_FlushDns; setdns = $J_SetDns; resetnet = $J_ResetNet; drivers = $J_Drivers; baddev = $J_BadDev; wusearch = $J_WUSearch; wuinstall = $J_WUInstall; winget = $J_Winget; restore = $J_Restore; optimize = $J_Optimize; hardware = $J_Hardware; webdrivers = $J_WebDrivers }
$Titles = @{ analyze = 'Análise'; clean = 'Limpeza'; dism = 'Limpeza profunda (DISM)'; sfc = 'Verificação SFC'; startup = 'Programas de inicialização'; startupoff = 'Desativando inicialização'; startupset = 'Reativando programa'; startupundo = 'Reativando inicialização'; repair = 'Reparando o Windows'; topproc = 'Top 10 processos'; ping = 'Teste de ping'; speed = 'Teste de velocidade'; flushdns = 'Limpar cache DNS'; setdns = 'Trocar DNS'; resetnet = 'Reset de rede'; drivers = 'Listar drivers'; baddev = 'Dispositivos com problema'; wusearch = 'Buscar no Windows Update'; wuinstall = 'Instalar atualizações'; winget = 'winget'; restore = 'Ponto de restauração'; optimize = 'Otimizando'; hardware = 'Lendo hardware'; webdrivers = 'Drivers pela web' }
$script:Job = $null
$script:Done = New-Object System.Collections.ArrayList
$script:LastSeen = Get-Date
$script:QuitAt = $null

$SetFile = Join-Path $DataDir 'settings.json'
$script:BootMode = $false
function Get-Settings {
    $c = @{ opts = $null; lang = 'pt' }
    if (Test-Path $SetFile) { try { $j = Get-Content $SetFile -Raw -Encoding UTF8 | ConvertFrom-Json; if ($j.opts) { $c.opts = $j.opts }; if ($j.lang) { $c.lang = [string]$j.lang } } catch {} }
    $c
}
function Save-Settings($c) { ConvertTo-Json -InputObject $c -Depth 5 | Set-Content -Path $SetFile -Encoding UTF8 }
function OptB($o, $n, $d) { if ($o -and $null -ne $o.$n) { [bool]$o.$n } else { $d } }
function Test-Boot { [bool](Get-ScheduledTask -TaskName 'CleanPano' -ErrorAction SilentlyContinue) }
function Register-Boot {
    try {
        $me = "$env:USERDOMAIN\$env:USERNAME"
        $act = New-ScheduledTaskAction -Execute ("`"" + (Join-Path $PSScriptRoot 'CleanPano.exe') + "`"") -Argument '/boot'
        $trg = New-ScheduledTaskTrigger -AtLogOn -User $me
        $trg.Delay = 'PT1M'
        $pri = New-ScheduledTaskPrincipal -UserId $me -LogonType Interactive -RunLevel Highest
        $set = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable -ExecutionTimeLimit (New-TimeSpan -Hours 3)
        Register-ScheduledTask -TaskName 'CleanPano' -Description 'CleanPano: otimização automática ao entrar no Windows' -Action $act -Trigger $trg -Principal $pri -Settings $set -Force -ErrorAction Stop | Out-Null
        Log 'Inicialização automática ligada (1 min após entrar no Windows)'
    } catch { Log "Erro ao ligar a inicialização automática: $($_.Exception.Message)" }
}
function Show-Toast($title, $text) {
    try {
        [void][Windows.UI.Notifications.ToastNotificationManager, Windows.UI.Notifications, ContentType = WindowsRuntime]
        [void][Windows.Data.Xml.Dom.XmlDocument, Windows.Data.Xml.Dom.XmlDocument, ContentType = WindowsRuntime]
        $x = New-Object Windows.Data.Xml.Dom.XmlDocument
        $x.LoadXml("<toast><visual><binding template='ToastGeneric'><text>$([Security.SecurityElement]::Escape($title))</text><text>$([Security.SecurityElement]::Escape($text))</text></binding></visual></toast>")
        $app = '{1AC14E77-02E7-4E5D-B744-2EB1AE5198B7}\WindowsPowerShell\v1.0\powershell.exe'
        [Windows.UI.Notifications.ToastNotificationManager]::CreateToastNotifier($app).Show([Windows.UI.Notifications.ToastNotification]::new($x))
    } catch {}
}

$script:BootRun = $false
$script:TrayAttached = $false
$script:LastFreed = ''
$script:LastPoll = $null
function Get-SavedOptVars {
    $o = (Get-Settings).opts
    @{ DoRestore = (OptB $o 'restore' $true); DoGpu = (OptB $o 'gpu' $true); DoDrivers = (OptB $o 'drivers' $true); DoWinget = (OptB $o 'winget' $true); DoDism = (OptB $o 'dism' $true); CloseBrowsers = $true; UseWU = (OptB $o 'usewu' $false) }
}
function Get-Status {
    $st = @(if ($sync.Steps) { $sync.Steps })
    $done = @($st | Where-Object { $_ -and $_.state -in 'ok', 'skip', 'err' }).Count
    $pct = $(if ($st.Count -and $sync.Steps) { [int]($done * 100 / $st.Count) } else { 0 })
    @{
        busy = [bool]$script:Job
        opt = [bool]($script:Job -and $script:Job.Task -eq 'optimize')
        pct = $pct
        lastFreed = $script:LastFreed
        lang = (Get-Settings).lang
        trayWanted = [bool]($script:BootRun -and -not $script:TrayAttached)
        uiAge = $(if ($script:LastPoll) { [int]((Get-Date) - $script:LastPoll).TotalSeconds } else { -1 })
    }
}
function Get-NetDetails {
    $out = New-Object System.Collections.ArrayList
    $cfgs = @(Get-NetIPConfiguration -ErrorAction SilentlyContinue | Where-Object { $_.NetAdapter -and $_.NetAdapter.Status -eq 'Up' })
    $wl = @{}
    try {
        $cur = $null
        foreach ($l in (netsh wlan show interfaces 2>$null)) {
            if ($l -match '^\s*(Name|Nome|Nombre)\s*:\s*(.+)$') { $cur = $Matches[2].Trim(); $wl[$cur] = @{} }
            elseif ($cur -and $l -match '^\s*SSID\s*:\s*(.+)$') { $wl[$cur].ssid = $Matches[1].Trim() }
            elseif ($cur -and $l -match '^\s*(Signal|Sinal|Señal)\s*:\s*(\d+)%') { $wl[$cur].signal = [int]$Matches[2] }
            elseif ($cur -and $l -match '^\s*(Radio type|Tipo de r[aá]dio|Tipo de radio)\s*:\s*(.+)$') { $wl[$cur].radio = $Matches[2].Trim() }
            elseif ($cur -and $l -match '^\s*(Band|Banda)\s*:\s*(.+)$') { $wl[$cur].band = $Matches[2].Trim() }
        }
    } catch {}
    foreach ($c in $cfgs) {
        $a = $c.NetAdapter
        $v4 = @($c.IPv4Address)[0]
        $ipif = Get-NetIPInterface -InterfaceIndex $c.InterfaceIndex -AddressFamily IPv4 -ErrorAction SilentlyContinue
        $v6 = @(Get-NetIPAddress -InterfaceIndex $c.InterfaceIndex -AddressFamily IPv6 -ErrorAction SilentlyContinue | Where-Object { $_.PrefixOrigin -ne 'WellKnown' } | Sort-Object { $_.IPAddress -like 'fe80*' } | Select-Object -ExpandProperty IPAddress)
        $mask = ''
        if ($v4) { $pl = [int]$v4.PrefixLength; $bits = ('1' * $pl).PadRight(32, '0'); $mask = (0..3 | ForEach-Object { [Convert]::ToInt32($bits.Substring($_ * 8, 8), 2) }) -join '.' }
        $isWifi = ($a.PhysicalMediaType -match '802\.11|Wireless') -or ($a.InterfaceDescription -match 'Wi-?Fi|Wireless|WLAN|802\.11')
        $w = $wl[$a.Name]
        [void]$out.Add([ordered]@{
            name    = $a.Name
            desc    = $a.InterfaceDescription
            type    = $(if ($isWifi) { 'wifi' } else { 'eth' })
            link    = [string]$a.LinkSpeed
            mac     = ($a.MacAddress -replace '-', ':')
            ip      = $(if ($v4) { $v4.IPAddress } else { '' })
            prefix  = $(if ($v4) { [int]$v4.PrefixLength } else { 0 })
            mask    = $mask
            gw      = $(if ($c.IPv4DefaultGateway) { @($c.IPv4DefaultGateway)[0].NextHop } else { '' })
            dns     = @($c.DNSServer | Where-Object { $_.AddressFamily -eq 2 } | ForEach-Object { $_.ServerAddresses } | Select-Object -Unique)
            dhcp    = $(if ($ipif) { [string]$ipif.Dhcp -eq 'Enabled' } else { $null })
            ipv6    = $(if ($v6.Count) { $v6[0] } else { '' })
            profile = $(try { [string](Get-NetConnectionProfile -InterfaceIndex $c.InterfaceIndex -ErrorAction Stop).NetworkCategory } catch { '' })
            ssid    = $(if ($w) { $w.ssid } else { '' })
            signal  = $(if ($w) { $w.signal } else { $null })
            radio   = $(if ($w) { $w.radio } else { '' })
            band    = $(if ($w) { $w.band } else { '' })
            primary = [bool]$c.IPv4DefaultGateway
        })
    }
    $pub = ''
    try { $pub = [string](Invoke-RestMethod -Uri 'https://api.ipify.org' -TimeoutSec 3 -UseBasicParsing) } catch {}
    $sorted = @($out | Sort-Object { -not $_.primary })
    @{ adapters = $sorted; publicIp = $pub.Trim(); host = $env:COMPUTERNAME; at = (Get-Date).ToString('HH:mm') }
}
function Get-Info {
    $d = New-Object System.IO.DriveInfo 'C'
    $os = Get-CimInstance Win32_OperatingSystem
    $o = (powercfg /getactivescheme) -join ' '
    $ads = @(Get-NetAdapter -Physical | Where-Object Status -eq 'Up')
    $dns = @($ads | ForEach-Object { (Get-DnsClientServerAddress -InterfaceIndex $_.ifIndex -AddressFamily IPv4).ServerAddresses } | Select-Object -Unique)
    $br = @('chrome', 'msedge', 'firefox' | Where-Object { (Get-BrowserProcs $_).Count -gt 0 })
    [ordered]@{
        disk     = @{ free = [double]$d.TotalFreeSpace; total = [double]$d.TotalSize }
        ram      = @{ used = [double](($os.TotalVisibleMemorySize - $os.FreePhysicalMemory) * 1KB); total = [double]($os.TotalVisibleMemorySize * 1KB) }
        power    = $(if ($o -match '\(([^)]+)\)') { $Matches[1] } else { '-' })
        uptimeH  = [math]::Round(((Get-Date) - $os.LastBootUpTime).TotalHours, 1)
        os       = ($os.Caption -replace 'Microsoft ', '')
        build    = [string]$os.BuildNumber
        arch     = [string]$os.OSArchitecture
        cpu      = $script:CpuName
        pc       = $env:COMPUTERNAME
        dns      = $dns
        adapter  = $(if ($ads.Count) { $ads[0].Name } else { '' })
        link     = $(if ($ads.Count) { [string]$ads[0].LinkSpeed } else { '' })
        browsers = $br
        winget   = [bool](Get-Command winget -ErrorAction SilentlyContinue)
        cats     = @(@((Get-Targets).Name) + 'Lixeira')
        hwKnown  = (Test-Path (Join-Path $DataDir 'hardware.json'))
        version = $(try { (Get-Item (Join-Path $PSScriptRoot 'CleanPano.exe') -ErrorAction Stop).VersionInfo.FileVersion } catch { '' })
        installLang = $(try { ([string](Get-Content (Join-Path $DataDir 'install-lang.txt') -TotalCount 1 -ErrorAction Stop)).Trim() } catch { '' })
        laptop   = [bool](Get-CimInstance Win32_Battery -ErrorAction SilentlyContinue)
        wuState  = $(try { [string](Get-Service wuauserv -ErrorAction Stop).StartType } catch { 'Unknown' })
    }
}

function Start-Work([string]$task, [hashtable]$vars) {
    if ($script:Job -or -not $Tasks.ContainsKey($task)) { return $false }
    $sync.Result = $null
    $sync.Steps = $null
    $rs = [runspacefactory]::CreateRunspace()
    $rs.ApartmentState = 'STA'
    $rs.Open()
    $rs.SessionStateProxy.SetVariable('sync', $sync)
    foreach ($k in $vars.Keys) { $rs.SessionStateProxy.SetVariable($k, $vars[$k]) }
    $ps = [powershell]::Create()
    $ps.Runspace = $rs
    [void]$ps.AddScript($Core + "`n" + $Tasks[$task])
    Log ">> $($Titles[$task])"
    $script:Job = @{ PS = $ps; RS = $rs; H = $ps.BeginInvoke(); Task = $task; Title = $Titles[$task] }
    $true
}

function Check-Work {
    if ($script:Job -and $script:Job.H.IsCompleted) {
        $j = $script:Job
        $script:Job = $null
        try { [void]$j.PS.EndInvoke($j.H) } catch { Log "Erro: $($_.Exception.Message)" }
        $j.PS.Dispose(); $j.RS.Close()
        Log "OK  $($j.Title) concluído"
        [void]$script:Done.Add(@{ task = $j.Task; result = $sync.Result })
        if ($j.Task -eq 'optimize') { $script:LastFreed = Fmt $(if ($sync.Result) { $sync.Result.freed } else { 0 }) }
        if ($script:BootMode -and $j.Task -eq 'optimize' -and -not $script:TrayAttached) {
            $script:BootMode = $false
            $fr = Fmt $(if ($sync.Result) { $sync.Result.freed } else { 0 })
            $L = (Get-Settings).lang
            $msg = @{ pt = @('CleanPano: otimização concluída', "$fr liberados. Abra o CleanPano para ver os detalhes."); en = @('CleanPano: optimization finished', "$fr freed. Open CleanPano to see the details."); es = @('CleanPano: optimización terminada', "$fr liberados. Abre CleanPano para ver los detalles.") }
            $m = $(if ($msg.ContainsKey($L)) { $msg[$L] } else { $msg.en })
            Show-Toast $m[0] $m[1]
        }
    }
}

function Send-Bytes($ctx, [byte[]]$b, [string]$type, [int]$code = 200) {
    $r = $ctx.Response
    $r.StatusCode = $code
    $r.ContentType = $type
    $r.Headers.Add('Cache-Control', 'no-store')
    $r.ContentLength64 = $b.Length
    $r.OutputStream.Write($b, 0, $b.Length)
    $r.OutputStream.Close()
}
function Send-Json($ctx, $o) { Send-Bytes $ctx ([Text.Encoding]::UTF8.GetBytes((ConvertTo-Json -InputObject $o -Depth 8 -Compress))) 'application/json; charset=utf-8' }

function Handle($ctx) {
    $req = $ctx.Request
    $q = $req.QueryString
    $ap = $req.Url.AbsolutePath
    if ($ap -match '^/([A-Za-z0-9_\-]+/)*[A-Za-z0-9_\-.]+\.(js|woff2|ico|png|svg|css|webp)$' -and $ap -notmatch '\.\.') {
        $f = Join-Path $UiDir ($ap.TrimStart('/') -replace '/', '\')
        if (Test-Path -LiteralPath $f -PathType Leaf) { Send-Bytes $ctx ([IO.File]::ReadAllBytes($f)) $Mime[$Matches[2]]; return }
    }
    switch ($req.Url.AbsolutePath.ToLower()) {
        '/' { Send-Bytes $ctx ([IO.File]::ReadAllBytes($UiFile)) 'text/html; charset=utf-8' }
        '/api/ping' { Send-Json $ctx @{ ok = $true } }
        '/api/info' { Send-Json $ctx (Get-Info) }
        '/api/netinfo' { Send-Json $ctx (Get-NetDetails) }
        '/api/poll' {
            $script:LastSeen = Get-Date
            $script:LastPoll = Get-Date
            $script:QuitAt = $null
            Check-Work
            $lines = New-Object System.Collections.ArrayList
            $l = $null
            while ($sync.Q.TryDequeue([ref]$l)) { [void]$lines.Add($l) }
            $done = @($script:Done.ToArray())
            $script:Done.Clear()
            Send-Json $ctx @{ busy = [bool]$script:Job; task = $(if ($script:Job) { $script:Job.Title } else { '' }); key = $(if ($script:Job) { $script:Job.Task } else { '' }); lines = @($lines.ToArray()); done = $done; steps = $(if ($sync.Steps) { @($sync.Steps | ForEach-Object { @{ id = $_.id; name = $_.name; state = $_.state; detail = $_.detail } }) } else { $null }) }
        }
        '/api/run' {
            $body = (New-Object IO.StreamReader($req.InputStream, [Text.Encoding]::UTF8)).ReadToEnd() | ConvertFrom-Json
            $vars = @{}
            if ($body.vars) { foreach ($p in $body.vars.PSObject.Properties) { $vars[$p.Name] = $p.Value } }
            Send-Json $ctx @{ ok = (Start-Work ([string]$body.task) $vars) }
        }
        '/api/startupkeep' {
            # marcar/desmarcar um programa: desmarcado = mantido (o botão de desativar pula ele)
            $id = [string]$q['id']; $keep = ($q['keep'] -eq '1'); $nm = [string]$q['name']
            $ok = $false
            if ($id) { try { Set-KeepOne $id $keep; $ok = $true; Log $(if ($keep) { "Inicialização: '$nm' desmarcado (será mantido)" } else { "Inicialização: '$nm' marcado (será desativado pelo botão)" }) } catch { Log "Erro ao salvar a escolha de inicialização: $($_.Exception.Message)" } }
            Send-Json $ctx @{ ok = $ok }
        }
        '/api/open' {
            switch ($q['w']) {
                'logs' { Start-Process explorer.exe $LogDir }
                'taskmgr' { Start-Process taskmgr.exe '/7 /startup' }
                'devmgmt' { Start-Process devmgmt.msc }
                'rstrui' { Start-Process rstrui.exe }
            }
            Send-Json $ctx @{ ok = $true }
        }
        '/api/power' {
            if ($q['m'] -eq 'high') { powercfg -setactive SCHEME_MIN; Log 'Plano de energia: Alto desempenho' }
            else { powercfg -setactive SCHEME_BALANCED; Log 'Plano de energia: Equilibrado' }
            Send-Json $ctx @{ ok = $true }
        }
        '/api/status' { $script:LastSeen = Get-Date; $script:QuitAt = $null; Check-Work; Send-Json $ctx (Get-Status) }
        '/api/tray' { $script:TrayAttached = $true; $script:LastSeen = Get-Date; Send-Json $ctx @{ ok = $true } }
        '/api/optimize-saved' { Send-Json $ctx @{ ok = (Start-Work 'optimize' (Get-SavedOptVars)) } }
        '/api/settings' {
            if ($req.HttpMethod -eq 'POST') {
                $b = (New-Object IO.StreamReader($req.InputStream, [Text.Encoding]::UTF8)).ReadToEnd() | ConvertFrom-Json
                $cfg = Get-Settings
                if ($b.opts) { $cfg.opts = $b.opts }
                if ($b.lang) { $cfg.lang = [string]$b.lang }
                Save-Settings $cfg
                if ($null -ne $b.autostart) {
                    if ($b.autostart) { Register-Boot }
                    else { Unregister-ScheduledTask -TaskName 'CleanPano' -Confirm:$false -ErrorAction SilentlyContinue; Log 'Inicialização automática desligada' }
                }
            }
            Send-Json $ctx @{ autostart = (Test-Boot) }
        }
        '/api/quit' { $script:QuitAt = (Get-Date).AddSeconds(6); Send-Json $ctx @{ ok = $true } }
        default { Send-Bytes $ctx ([Text.Encoding]::UTF8.GetBytes('not found')) 'text/plain' 404 }
    }
}

$listener = $null
try {
    $listener = New-Object System.Net.HttpListener
    $listener.Prefixes.Add("http://127.0.0.1:$Port/")
    $listener.Start()
    Log "CleanPano pronto (porta $Port)"
    try { $tk = Get-ScheduledTask -TaskName 'CleanPano' -ErrorAction Stop; if ($tk.Actions[0].Execute -notlike "*$(Join-Path $PSScriptRoot 'CleanPano.exe')*") { Register-Boot } } catch {}
    if ($Boot) {
        $script:BootMode = $true
        $script:BootRun = $true
        Log 'Iniciado com o Windows: otimização automática (bandeja)'
        [void](Start-Work 'optimize' (Get-SavedOptVars))
        Start-Process explorer.exe "`"$(Join-Path $PSScriptRoot 'CleanPano.exe')`""
    }
    $stop = $false
    while (-not $stop) {
        $t = $listener.GetContextAsync()
        while (-not $t.Wait(300)) {
            Check-Work
            $idle = ((Get-Date) - $script:LastSeen).TotalSeconds
            if (-not $script:Job -and (($script:QuitAt -and (Get-Date) -gt $script:QuitAt) -or $idle -gt 120)) { $stop = $true; break }
        }
        if ($stop) { break }
        $ctx = $t.Result
        try { Handle $ctx } catch { try { Send-Json $ctx @{ ok = $false; error = $_.Exception.Message } } catch {} }
    }
} catch {
    "$(Get-Date -f 'yyyy-MM-dd HH:mm:ss')  $($_.Exception.Message)" | Add-Content $ErrFile -Encoding UTF8
} finally {
    if ($listener) { try { $listener.Stop(); $listener.Close() } catch {} }
}
