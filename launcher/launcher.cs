using System;
using System.Diagnostics;
using System.Drawing;
using System.IO;
using System.Management;
using System.Net;
using System.Net.Sockets;
using System.Reflection;
using System.Runtime.CompilerServices;
using System.Runtime.InteropServices;
using Microsoft.Web.WebView2.Core;
using Microsoft.Web.WebView2.WinForms;
using System.Text.RegularExpressions;
using System.Threading;
using System.Windows.Forms;
[assembly: AssemblyTitle(AppInfo.Name)]
[assembly: AssemblyProduct(AppInfo.Name)]
[assembly: AssemblyDescription(AppInfo.Description)]
[assembly: AssemblyCompany(AppInfo.Name)]
[assembly: AssemblyCopyright("© 2026 " + AppInfo.Name)]
[assembly: AssemblyVersion(AppInfo.Version)]
[assembly: AssemblyFileVersion(AppInfo.Version)]

/* ============================================================
   Lançador da janela (base PANO): janela própria sem moldura (WebView2),
   transparência, cantos arredondados, arrastar, bandeja do Windows.
   Para outro programa, mude só o bloco AppInfo abaixo.
   ============================================================ */
static class AppInfo {
    public const string Name = "CleanPano";               // nome do programa (pastas, janela, bandeja)
    public const string Description = "CleanPano - PC Cleaner";
    public const string Version = "1.15.1.0";
    public const string Engine = "CleanPano.ps1";          // motor (servidor local em PowerShell)
    public const int Port = 8765;                         // porta local do motor
    public const bool Admin = true;                       // motor roda como administrador
}

static class Program {
    const int Port = AppInfo.Port;
    internal static readonly string Url = "http://127.0.0.1:" + Port + "/";

    static readonly string LogFile = Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData), AppInfo.Name, "launcher.log");
    internal static void L(string m) {
        try { Directory.CreateDirectory(Path.GetDirectoryName(LogFile)); File.AppendAllText(LogFile, DateTime.Now.ToString("yyyy-MM-dd HH:mm:ss") + "  " + m + Environment.NewLine); } catch { }
    }

    static bool Up() {
        try { using (var c = new TcpClient()) { var r = c.BeginConnect("127.0.0.1", Port, null, null); bool ok = r.AsyncWaitHandle.WaitOne(300); if (ok) c.EndConnect(r); return ok && c.Connected; } }
        catch { return false; }
    }

    internal static string Get(string path) {
        try {
            var rq = (HttpWebRequest)WebRequest.Create(Url + path.TrimStart(new char[] { '/' }));
            rq.Timeout = 2500; rq.Proxy = null;
            using (var rs = rq.GetResponse()) using (var sr = new StreamReader(rs.GetResponseStream())) return sr.ReadToEnd();
        } catch { return null; }
    }

    static bool StartServer(bool boot = false) {
        string dir = AppDomain.CurrentDomain.BaseDirectory;
        var psi = new ProcessStartInfo("powershell.exe", "-NoProfile -ExecutionPolicy RemoteSigned -File \"" + Path.Combine(dir, AppInfo.Engine) + "\"" + (boot ? " -Boot" : ""));
        psi.UseShellExecute = true; if (AppInfo.Admin) psi.Verb = "runas"; psi.WindowStyle = ProcessWindowStyle.Hidden;
        try { Process.Start(psi); } catch { return false; }
        if (boot) return true;
        for (int i = 0; i < 60; i++) { Thread.Sleep(500); if (Up()) return true; }
        MessageBox.Show("O " + AppInfo.Name + " não conseguiu iniciar.\n" + AppInfo.Name + " could not start.\n\n" + Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.CommonApplicationData), AppInfo.Name + "\\logs\\server_error.txt"), AppInfo.Name, MessageBoxButtons.OK, MessageBoxIcon.Error);
        return false;
    }

    static string Prof() { return Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData), AppInfo.Name, "edge"); }

    static void KillProfileEdge() {
        try {
            using (var q = new ManagementObjectSearcher("SELECT ProcessId, CommandLine FROM Win32_Process WHERE Name='msedge.exe'"))
                foreach (ManagementObject o in q.Get()) {
                    string cl = (o["CommandLine"] ?? "").ToString();
                    if (cl.IndexOf(AppInfo.Name + "\\edge", StringComparison.OrdinalIgnoreCase) >= 0) { try { Process.GetProcessById(Convert.ToInt32(o["ProcessId"])).Kill(); } catch { } }
                }
            L("Edge do perfil " + AppInfo.Name + " finalizado (estava travado)");
        } catch (Exception ex) { L("KillProfileEdge: " + ex.Message); }
    }

    static bool UiConnected(int seconds) {
        for (int i = 0; i < seconds * 2; i++) {
            Thread.Sleep(500);
            string s = Get("api/status");
            if (s != null) { var m = Regex.Match(s, "\"uiAge\":(-?\\d+)"); if (m.Success) { int a = int.Parse(m.Groups[1].Value); if (a >= 0 && a < 5) return true; } else return true; }
        }
        return false;
    }

    static void LaunchEdge() {
        var e = new ProcessStartInfo("msedge.exe", "--app=" + Url + " --user-data-dir=\"" + Prof() + "\" --window-size=1280,820 --disable-background-timer-throttling --no-first-run --no-default-browser-check");
        e.UseShellExecute = true; Process.Start(e);
    }

    internal static bool InTray = false;

    [MethodImpl(MethodImplOptions.NoInlining)]
    static string Wv2Version() { return CoreWebView2Environment.GetAvailableBrowserVersionString(); }

    static bool HasWebView2() {
        try { string v = Wv2Version(); L("WebView2 runtime: " + (v ?? "(nenhum)")); return !string.IsNullOrEmpty(v); }
        catch (Exception ex) { L("WebView2 indisponível: " + ex.GetType().Name + " " + ex.Message); return false; }
    }

    [MethodImpl(MethodImplOptions.NoInlining)]
    static bool RunWindow() {
        bool created;
        var mx = new Mutex(true, AppInfo.Name + "Window", out created);
        if (!created) { try { EventWaitHandle.OpenExisting(AppInfo.Name + "Show").Set(); } catch { } return true; }
        var ev = new EventWaitHandle(false, EventResetMode.AutoReset, AppInfo.Name + "Show");
        Application.EnableVisualStyles();
        var f = new Win();
        var th = new Thread(() => { while (ev.WaitOne()) { try { f.BeginInvoke((Action)f.Bring); } catch { } } });
        th.IsBackground = true; th.Start();
        Application.Run(f);
        GC.KeepAlive(mx);
        return !f.Failed;
    }

    internal static void OpenWindow() {
        if (!Up() && !StartServer()) return;
        if (HasWebView2()) {
            if (InTray) { try { Process.Start(Application.ExecutablePath, "/window"); return; } catch (Exception ex) { L("Abrir janela: " + ex.Message); } }
            else {
                try { L("Abrindo janela (WebView2)"); if (RunWindow()) return; L("WebView2 falhou; usando o Edge"); }
                catch (Exception ex) { L("WebView2 erro: " + ex.Message); }
            }
        }
        OpenEdge();
    }

    static void OpenEdge() {
        try {
            L("Abrindo janela (Edge app)");
            LaunchEdge();
            if (UiConnected(12)) { L("Janela conectada"); return; }
            L("Janela não conectou; reiniciando o Edge do " + AppInfo.Name);
            KillProfileEdge(); Thread.Sleep(800);
            LaunchEdge();
            if (UiConnected(12)) { L("Janela conectada na 2a tentativa"); return; }
        } catch (Exception ex) { L("Edge falhou: " + ex.Message); }
        L("Abrindo no navegador padrão");
        try { Process.Start(Url); } catch (Exception ex) { L("Navegador padrão falhou: " + ex.Message); }
    }

    [DllImport("user32.dll")] static extern bool SetProcessDpiAwarenessContext(IntPtr v);
    [DllImport("user32.dll")] static extern bool SetProcessDPIAware();

    [STAThread]
    static void Main(string[] args) {
        // /stop: usado pelo instalador/desinstalador para fechar o app e o motor (sem PowerShell no instalador)
        if (Array.Exists(args, a => a.Equals("/stop", StringComparison.OrdinalIgnoreCase))) { StopAll(); return; }
        try { if (!SetProcessDpiAwarenessContext(new IntPtr(-4))) SetProcessDPIAware(); } catch { try { SetProcessDPIAware(); } catch { } }
        try { Run(args); }
        catch (Exception ex) { L("ERRO: " + ex); MessageBox.Show(AppInfo.Name + ": " + ex.Message + "\n\n" + LogFile, AppInfo.Name, MessageBoxButtons.OK, MessageBoxIcon.Error); }
    }

    static void StopAll() {
        int me = Process.GetCurrentProcess().Id;
        try {
            using (var q = new ManagementObjectSearcher("SELECT ProcessId, CommandLine FROM Win32_Process WHERE Name='powershell.exe'"))
                foreach (ManagementObject o in q.Get()) {
                    string cl = (o["CommandLine"] ?? "").ToString();
                    if (cl.IndexOf(AppInfo.Engine, StringComparison.OrdinalIgnoreCase) >= 0) { try { Process.GetProcessById(Convert.ToInt32(o["ProcessId"])).Kill(); } catch { } }
                }
        } catch { }
        foreach (var p in Process.GetProcessesByName(AppInfo.Name)) { if (p.Id != me) { try { p.Kill(); p.WaitForExit(3000); } catch { } } }
        KillProfileEdge();
    }

    static void Run(string[] args) {
        L("Iniciando launcher " + string.Join(" ", args));
        if (Array.Exists(args, a => a.Equals("/window", StringComparison.OrdinalIgnoreCase))) { OpenWindow(); return; }
        // /boot: chamado pela tarefa agendada no logon; só liga o motor em modo automático (ele abre a bandeja depois)
        if (Array.Exists(args, a => a.Equals("/boot", StringComparison.OrdinalIgnoreCase))) { if (!Up()) StartServer(true); return; }
        bool tray = Array.Exists(args, a => a.Equals("/tray", StringComparison.OrdinalIgnoreCase));
        if (!Up() && !StartServer()) return;
        string st = Get("api/status");
        L("status: " + (st ?? "(sem resposta)"));
        if (tray || (st != null && st.Contains("\"trayWanted\":true"))) {
            bool created;
            using (var m = new Mutex(true, AppInfo.Name + "Tray", out created)) {
                if (!created) return;
                Application.EnableVisualStyles();
                InTray = true;
                Application.Run(new Tray());
            }
            return;
        }
        OpenWindow();
    }
}

class Win : Form {
    [StructLayout(LayoutKind.Sequential)] struct BB { public int dwFlags; public int fEnable; public IntPtr hRgnBlur; public int fTransitionOnMaximized; }
    [DllImport("dwmapi.dll")] static extern int DwmEnableBlurBehindWindow(IntPtr h, ref BB b);
    [DllImport("gdi32.dll")] static extern IntPtr CreateRectRgn(int a, int b, int c, int d);
    [DllImport("gdi32.dll")] static extern bool DeleteObject(IntPtr o);
    [DllImport("user32.dll")] static extern bool ReleaseCapture();
    [DllImport("user32.dll")] static extern IntPtr SendMessage(IntPtr h, int m, IntPtr w, IntPtr l);
    [DllImport("user32.dll")] static extern uint GetDpiForWindow(IntPtr h);
    [DllImport("user32.dll")] static extern bool SetForegroundWindow(IntPtr h);

    readonly WebView2 wv = new WebView2();
    public bool Failed = false;
    bool maxed = false; Rectangle normal; int op = 98;
    static readonly Color Bg = Color.FromArgb(241, 241, 236);
    static readonly string Dir = Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData), AppInfo.Name);
    static readonly string BoundsFile = Path.Combine(Dir, "window.txt");

    float Scale() { try { return GetDpiForWindow(Handle) / 96f; } catch { return DeviceDpi / 96f; } }

    public Win() {
        Text = AppInfo.Name;
        FormBorderStyle = FormBorderStyle.None;
        BackColor = Color.Black;
        StartPosition = FormStartPosition.Manual;
        ShowInTaskbar = true;
        try { Icon = Icon.ExtractAssociatedIcon(Application.ExecutablePath); } catch { }
        Environment.SetEnvironmentVariable("WEBVIEW2_DEFAULT_BACKGROUND_COLOR", "00000000");
        wv.DefaultBackgroundColor = Color.Transparent;
        wv.BackColor = Color.Black;
        wv.Dock = DockStyle.Fill;
        Controls.Add(wv);
        Load += (s, e) => Place();
        Shown += (s, e) => Init();
        FormClosing += (s, e) => SaveBounds();
        FormClosed += (s, e) => { if (!Failed) Program.Get("api/quit"); };
    }

    protected override CreateParams CreateParams {
        get { var cp = base.CreateParams; cp.Style |= 0x00020000 | 0x00010000 | 0x00080000; return cp; }
    }

    // fundo da janela transparente por pixel: a página decide o que é transparente
    // (fundo e cartões ficam translúcidos; logo, mascote e botão principal ficam sólidos)
    protected override void OnHandleCreated(EventArgs e) {
        base.OnHandleCreated(e);
        try {
            var bb = new BB(); bb.dwFlags = 3; bb.fEnable = 1; bb.hRgnBlur = CreateRectRgn(0, 0, -1, -1);
            DwmEnableBlurBehindWindow(Handle, ref bb);
            DeleteObject(bb.hRgnBlur);
        } catch (Exception ex) { Program.L("Transparência: " + ex.Message); }
    }

    void SetOp(int v) { op = Math.Max(50, Math.Min(100, v)); }

    void Place() {
        float k = Scale();
        int g = (int)Math.Round(6 * k);
        Padding = new Padding(g);
        try { op = int.Parse(File.ReadAllText(Path.Combine(Dir, "opacity.txt")).Trim()); } catch { op = 98; }
        SetOp(op);
        MinimumSize = new Size((int)(900 * k), (int)(600 * k));
        var wa = Screen.FromPoint(Cursor.Position).WorkingArea;
        Rectangle r = Rectangle.Empty; bool mx = false;
        try {
            var p = File.ReadAllText(BoundsFile).Trim().Split(',');
            r = new Rectangle(int.Parse(p[0]), int.Parse(p[1]), int.Parse(p[2]), int.Parse(p[3]));
            mx = p.Length > 4 && p[4] == "1";
            bool vis = false;
            foreach (var s in Screen.AllScreens) if (s.WorkingArea.IntersectsWith(new Rectangle(r.X + 40, r.Y + 10, Math.Max(1, r.Width - 80), 40))) vis = true;
            if (!vis || r.Width < 300 || r.Height < 200) r = Rectangle.Empty;
        } catch { r = Rectangle.Empty; }
        if (r.IsEmpty) {
            int w = Math.Min((int)(1280 * k), (int)(wa.Width * .92)), h = Math.Min((int)(820 * k), (int)(wa.Height * .92));
            r = new Rectangle(wa.X + (wa.Width - w) / 2, wa.Y + (wa.Height - h) / 2, w, h);
        }
        Bounds = r; normal = r;
        if (mx) ToggleMax();
    }

    void SaveBounds() {
        try { var r = maxed ? normal : Bounds; if (WindowState == FormWindowState.Minimized) r = RestoreBounds; Directory.CreateDirectory(Dir); File.WriteAllText(BoundsFile, r.X + "," + r.Y + "," + r.Width + "," + r.Height + "," + (maxed ? "1" : "0")); } catch { }
    }

    public void Bring() {
        if (WindowState == FormWindowState.Minimized) WindowState = FormWindowState.Normal;
        Show(); Activate(); SetForegroundWindow(Handle);
    }

    void ToggleMax() {
        if (WindowState == FormWindowState.Minimized) WindowState = FormWindowState.Normal;
        if (!maxed) { normal = Bounds; Padding = new Padding(0); Bounds = Screen.FromHandle(Handle).WorkingArea; maxed = true; }
        else { maxed = false; Padding = new Padding((int)Math.Round(6 * Scale())); Bounds = normal; }
        Post("max:" + (maxed ? "1" : "0"));
    }

    void Post(string m) { try { if (wv.CoreWebView2 != null) wv.CoreWebView2.PostWebMessageAsString(m); } catch { } }

    async void Init() {
        try {
            var env = await CoreWebView2Environment.CreateAsync(null, Path.Combine(Dir, "webview2"));
            await wv.EnsureCoreWebView2Async(env);
            var c = wv.CoreWebView2; var st = c.Settings;
            st.AreDevToolsEnabled = false; st.IsStatusBarEnabled = false; st.AreDefaultContextMenusEnabled = false;
            st.IsZoomControlEnabled = false; st.AreBrowserAcceleratorKeysEnabled = false; st.IsPinchZoomEnabled = false;
            await c.AddScriptToExecuteOnDocumentCreatedAsync("window.cpHost={max:" + (maxed ? "true" : "false") + ",op:" + op + "};");
            c.WebMessageReceived += (s, e) => { string m = null; try { m = e.TryGetWebMessageAsString(); } catch { } Msg(m); };
            c.WindowCloseRequested += (s, e) => Close();
            c.NewWindowRequested += (s, e) => { e.Handled = true; try { Process.Start(e.Uri); } catch { } };
            c.ProcessFailed += (s, e) => Program.L("WebView2 processo falhou: " + e.ProcessFailedKind);
            c.Navigate(Program.Url);
            Program.L("Janela WebView2 pronta");
        } catch (Exception ex) {
            Program.L("WebView2 init falhou: " + ex);
            Failed = true; Close();
        }
    }

    void Msg(string m) {
        if (m == null) return;
        if (m.StartsWith("op:")) {
            int v; if (int.TryParse(m.Substring(3), out v)) { SetOp(v); try { Directory.CreateDirectory(Dir); File.WriteAllText(Path.Combine(Dir, "opacity.txt"), op.ToString()); } catch { } }
            return;
        }
        switch (m) {
            case "drag":
                if (maxed) return;
                ReleaseCapture(); SendMessage(Handle, 0xA1, (IntPtr)2, IntPtr.Zero); break;
            case "min": WindowState = FormWindowState.Minimized; break;
            case "max": ToggleMax(); break;
            case "close": Close(); break;
            case "state": Post("max:" + (maxed ? "1" : "0")); break;
        }
    }

    protected override void WndProc(ref Message m) {
        if (m.Msg == 0x84 && !maxed) {
            base.WndProc(ref m);
            long lp = m.LParam.ToInt64();
            var p = PointToClient(new Point((short)(lp & 0xFFFF), (short)((lp >> 16) & 0xFFFF)));
            int g = Math.Max(Padding.Left, 4);
            bool l = p.X < g, r = p.X >= ClientSize.Width - g, tp = p.Y < g, b = p.Y >= ClientSize.Height - g;
            int ht = tp && l ? 13 : tp && r ? 14 : b && l ? 16 : b && r ? 17 : l ? 10 : r ? 11 : tp ? 12 : b ? 15 : 0;
            if (ht != 0) m.Result = (IntPtr)ht;
            return;
        }
        if (m.Msg == 0xA3) { ToggleMax(); m.Result = IntPtr.Zero; return; }
        if (m.Msg == 0x112) {
            int c = m.WParam.ToInt32() & 0xFFF0;
            if (c == 0xF030) { if (!maxed) ToggleMax(); return; }
            if (c == 0xF120 && maxed && WindowState == FormWindowState.Normal) { ToggleMax(); return; }
        }
        base.WndProc(ref m);
    }
}

class Tray : ApplicationContext {
    readonly NotifyIcon icon = new NotifyIcon();
    readonly System.Windows.Forms.Timer timer = new System.Windows.Forms.Timer();
    readonly ToolStripMenuItem miOpen = new ToolStripMenuItem(), miOpt = new ToolStripMenuItem(), miExit = new ToolStripMenuItem();
    bool wasOpt = false, announced = false; int fails = 0; string lang = "pt";

    static string S(string k, string lang) {
        int i = lang == "pt" ? 0 : lang == "es" ? 2 : 1;
        switch (k) {
            case "open": return new[] { "Abrir ", "Open ", "Abrir " }[i] + AppInfo.Name;
            case "opt": return new[] { "Otimizar agora", "Optimize now", "Optimizar ahora" }[i];
            case "exit": return new[] { "Sair", "Exit", "Salir" }[i];
            case "running": return new[] { "Otimizando", "Optimizing", "Optimizando" }[i];
            case "idle": return new[] { "pronto", "ready", "listo" }[i];
            case "done": return new[] { "Otimização concluída", "Optimization finished", "Optimización terminada" }[i];
            case "freed": return new[] { "{0} liberados. Clique para ver os detalhes.", "{0} freed. Click to see the details.", "{0} liberados. Haz clic para ver los detalles." }[i];
            case "start": return new[] { "Otimizando o PC em segundo plano...", "Optimizing your PC in the background...", "Optimizando el PC en segundo plano..." }[i];
        }
        return k;
    }

    public Tray() {
        try { icon.Icon = Icon.ExtractAssociatedIcon(Application.ExecutablePath); } catch { icon.Icon = SystemIcons.Application; }
        var menu = new ContextMenuStrip();
        miOpen.Font = new Font(miOpen.Font, FontStyle.Bold);
        miOpen.Click += (s, e) => Program.OpenWindow();
        miOpt.Click += (s, e) => Program.Get("api/optimize-saved");
        miExit.Click += (s, e) => Quit(true);
        menu.Items.AddRange(new ToolStripItem[] { miOpen, miOpt, new ToolStripSeparator(), miExit });
        icon.ContextMenuStrip = menu;
        icon.DoubleClick += (s, e) => Program.OpenWindow();
        icon.BalloonTipClicked += (s, e) => Program.OpenWindow();
        icon.Text = AppInfo.Name;
        icon.Visible = true;
        Program.Get("api/tray");
        Labels();
        timer.Interval = 2000;
        timer.Tick += (s, e) => Tick();
        timer.Start();
        Tick();
    }

    void Labels() { miOpen.Text = S("open", lang); miOpt.Text = S("opt", lang); miExit.Text = S("exit", lang); }

    static string Str(string j, string k) { var m = Regex.Match(j, "\"" + k + "\":\"((?:[^\"\\\\]|\\\\.)*)\""); return m.Success ? Regex.Unescape(m.Groups[1].Value) : ""; }
    static bool Bool(string j, string k) { return Regex.IsMatch(j, "\"" + k + "\":true"); }
    static int Int(string j, string k) { var m = Regex.Match(j, "\"" + k + "\":(\\d+)"); return m.Success ? int.Parse(m.Groups[1].Value) : 0; }

    void Tick() {
        string j = Program.Get("api/status");
        if (j == null) { if (++fails > 15) Quit(false); return; }
        fails = 0;
        string l = Str(j, "lang"); if (l != "" && l != lang) { lang = l; Labels(); }
        bool opt = Bool(j, "opt");
        miOpt.Enabled = !Bool(j, "busy");
        if (opt) {
            string t = AppInfo.Name + " · " + S("running", lang) + " " + Int(j, "pct") + "%";
            icon.Text = t.Length > 63 ? t.Substring(0, 63) : t;
            if (!announced) { announced = true; icon.ShowBalloonTip(4000, AppInfo.Name, S("start", lang), ToolTipIcon.Info); }
        } else {
            icon.Text = AppInfo.Name + " · " + S("idle", lang);
            if (wasOpt) icon.ShowBalloonTip(8000, AppInfo.Name + " · " + S("done", lang), string.Format(S("freed", lang), Str(j, "lastFreed")), ToolTipIcon.Info);
        }
        wasOpt = opt;
    }

    void Quit(bool stopServer) {
        timer.Stop();
        if (stopServer) Program.Get("api/quit");
        icon.Visible = false; icon.Dispose();
        ExitThread();
    }
}
