# ============================================================
#  Claude Usage Widget  -  numeros OFICIALES (/api/oauth/usage)
#  Resistente: timeouts, no se congela, boton Reconectar al vencer.
#  NOTA: solo texto ASCII.
# ============================================================

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

$cBg=[System.Drawing.Color]::FromArgb(30,30,30)
$cAccent=[System.Drawing.Color]::FromArgb(217,119,87)
$cText=[System.Drawing.Color]::FromArgb(230,230,230)
$cMuted=[System.Drawing.Color]::FromArgb(150,150,150)
$cBar=[System.Drawing.Color]::FromArgb(60,60,60)
$cWarn=[System.Drawing.Color]::FromArgb(220,170,70)
$cDanger=[System.Drawing.Color]::FromArgb(225,90,75)

$CredPath = "$env:USERPROFILE\.claude\.credentials.json"
$ReconnectCmd = Join-Path $PSScriptRoot 'Reconectar-Claude.cmd'
$script:LastGood = $null
$script:State = 'init'    # ok | expired | offline | nocreds

function Draw-Spark($g,$cx,$cy,$r,$color){
    $g.SmoothingMode='AntiAlias'
    $pen=New-Object System.Drawing.Pen($color,[single]([math]::Max(1,$r*0.22)))
    $pen.StartCap='Round'; $pen.EndCap='Round'
    for($i=0;$i -lt 12;$i++){ $a=[math]::PI*2*$i/12; $len=if($i % 2 -eq 0){$r}else{$r*0.62}
        $g.DrawLine($pen,[single]$cx,[single]$cy,[single]($cx+[math]::Cos($a)*$len),[single]($cy+[math]::Sin($a)*$len)) }
    $pen.Dispose()
}
function Sev-Color($sev,$pct){
    switch("$sev"){ 'normal'{ if($pct -ge 80){return $cWarn} return $cAccent }
        'warning'{return $cWarn} 'warn'{return $cWarn}
        default{ if($sev){return $cDanger}; if($pct -ge 80){return $cDanger}elseif($pct -ge 50){return $cWarn}return $cAccent } }
}

function Get-OfficialUsage {
    try { $c = Get-Content $CredPath -Raw -ErrorAction Stop | ConvertFrom-Json } catch { $script:State='nocreds'; return $script:LastGood }
    $expMs=[int64]$c.claudeAiOauth.expiresAt
    $nowMs=[DateTimeOffset]::UtcNow.ToUnixTimeMilliseconds()
    if (($expMs - $nowMs) -lt 60000) { $script:State='expired'; return $script:LastGood }  # vencido: pedir reconexion
    try {
        $h=@{ 'Authorization'="Bearer $($c.claudeAiOauth.accessToken)"; 'anthropic-beta'='oauth-2025-04-20'; 'anthropic-version'='2023-06-01'; 'Content-Type'='application/json' }
        $u=Invoke-RestMethod -Uri 'https://api.anthropic.com/api/oauth/usage' -Headers $h -Method GET -TimeoutSec 12
    } catch {
        if ("$($_.Exception.Message)" -match '401|403') { $script:State='expired' } else { $script:State='offline' }
        return $script:LastGood
    }
    $d=[ordered]@{ SessPct=[int]$u.five_hour.utilization; WeekPct=[int]$u.seven_day.utilization
        SessReset=$null; WeekReset=$null; SessSev='normal'; WeekSev='normal'; Stamp=(Get-Date); Ok=$true }
    try{ $d.SessReset=([datetimeoffset]$u.five_hour.resets_at).LocalDateTime }catch{}
    try{ $d.WeekReset=([datetimeoffset]$u.seven_day.resets_at).LocalDateTime }catch{}
    foreach($l in $u.limits){ if($l.kind -eq 'session'){$d.SessSev=$l.severity}; if($l.group -eq 'weekly'){$d.WeekSev=$l.severity} }
    $script:State='ok'; $script:LastGood=$d; return $d
}

# ----- ventana -----
$form=New-Object System.Windows.Forms.Form
$form.FormBorderStyle='None'; $form.BackColor=$cBg
$form.Size=New-Object System.Drawing.Size(252,184)
$form.TopMost=$true; $form.ShowInTaskbar=$false; $form.StartPosition='Manual'
$wa=[System.Windows.Forms.Screen]::PrimaryScreen.WorkingArea
$form.Location=New-Object System.Drawing.Point(($wa.Right-267),($wa.Bottom-200))
$form.Opacity=0.96
$form.Add_Paint({ param($s,$e); $pen=New-Object System.Drawing.Pen($cAccent,1); $e.Graphics.DrawRectangle($pen,0,0,$s.Width-1,$s.Height-1); $pen.Dispose() })

function New-Lbl($x,$y,$w,$h,$txt,$col,$size,$style){
    $l=New-Object System.Windows.Forms.Label
    $l.Location=New-Object System.Drawing.Point($x,$y); $l.Size=New-Object System.Drawing.Size($w,$h)
    $l.Text=$txt; $l.ForeColor=$col; $l.BackColor=[System.Drawing.Color]::Transparent
    $l.Font=New-Object System.Drawing.Font('Segoe UI',$size,$style); $form.Controls.Add($l); return $l
}
function New-Bar($x,$y,$w){
    $b=New-Object System.Windows.Forms.Panel; $b.Location=New-Object System.Drawing.Point($x,$y); $b.Size=New-Object System.Drawing.Size($w,6); $b.BackColor=$cBar
    $f=New-Object System.Windows.Forms.Panel; $f.Location=New-Object System.Drawing.Point(0,0); $f.Size=New-Object System.Drawing.Size(0,6); $f.BackColor=$cAccent
    $b.Controls.Add($f); $form.Controls.Add($b); return $f
}

$logoBmp=New-Object System.Drawing.Bitmap(26,26); $lg=[System.Drawing.Graphics]::FromImage($logoBmp); Draw-Spark $lg 13 13 11 $cAccent; $lg.Dispose()
$pic=New-Object System.Windows.Forms.PictureBox; $pic.Image=$logoBmp; $pic.Size=New-Object System.Drawing.Size(26,26); $pic.Location=New-Object System.Drawing.Point(10,8); $pic.BackColor=$cBg; $form.Controls.Add($pic)

$lblTitle=New-Lbl 42 11 150 22 'Claude' $cAccent 12 ([System.Drawing.FontStyle]::Bold)
$lblClose=New-Lbl 226 6 20 20 'X' $cMuted 10 ([System.Drawing.FontStyle]::Bold); $lblClose.Cursor='Hand'; $lblClose.TextAlign='MiddleCenter'

$lblSessHdr=New-Lbl 12 42 130 18 'Sesion (5h)' $cMuted 9 ([System.Drawing.FontStyle]::Regular)
$lblSessPct=New-Lbl 142 38 98 22 '--%' $cAccent 13 ([System.Drawing.FontStyle]::Bold); $lblSessPct.TextAlign='MiddleRight'
$barSess=New-Bar 12 64 228
$lblSessRst=New-Lbl 12 72 228 16 'se reinicia en --' $cMuted 8 ([System.Drawing.FontStyle]::Regular)

$lblWeekHdr=New-Lbl 12 96 130 18 'Semana' $cMuted 9 ([System.Drawing.FontStyle]::Regular)
$lblWeekPct=New-Lbl 142 92 98 22 '--%' $cAccent 13 ([System.Drawing.FontStyle]::Bold); $lblWeekPct.TextAlign='MiddleRight'
$barWeek=New-Bar 12 118 228
$lblWeekRst=New-Lbl 12 126 228 16 'se reinicia --' $cMuted 8 ([System.Drawing.FontStyle]::Regular)

$lblFoot=New-Lbl 12 152 228 18 'Oficial - plan Pro' $cMuted 7 ([System.Drawing.FontStyle]::Italic)
$lblFoot.Cursor='Hand'

# arrastrar
$script:drag=$false; $script:dx=0; $script:dy=0
$onDown={ $script:drag=$true; $script:dx=$_.X; $script:dy=$_.Y }
$onMove={ if($script:drag){ $form.Location=New-Object System.Drawing.Point(($form.Location.X+$_.X-$script:dx),($form.Location.Y+$_.Y-$script:dy)) } }
$onUp={ $script:drag=$false }
foreach($c in @($form,$lblTitle,$pic)){ $c.Add_MouseDown($onDown); $c.Add_MouseMove($onMove); $c.Add_MouseUp($onUp) }

# bandeja
$bmp=New-Object System.Drawing.Bitmap(16,16); $g=[System.Drawing.Graphics]::FromImage($bmp); Draw-Spark $g 8 8 7 $cAccent; $g.Dispose()
$icon=[System.Drawing.Icon]::FromHandle($bmp.GetHicon())
$tray=New-Object System.Windows.Forms.NotifyIcon; $tray.Icon=$icon; $tray.Visible=$true; $tray.Text='Claude - Uso'
$menu=New-Object System.Windows.Forms.ContextMenuStrip
$miShow=$menu.Items.Add('Mostrar / Ocultar ventana'); $miRef=$menu.Items.Add('Actualizar ahora'); $miLogin=$menu.Items.Add('Reconectar (login)')
$menu.Items.Add('-')|Out-Null; $miExit=$menu.Items.Add('Salir'); $tray.ContextMenuStrip=$menu

function Find-ClaudeExe {
    $base = Join-Path $env:APPDATA 'Claude\claude-code'
    # reintenta: claude.exe desaparece por instantes cuando la app lo gestiona/actualiza
    for ($try = 0; $try -lt 3; $try++) {
        if (Test-Path $base) {
            $e = Get-ChildItem $base -Recurse -Filter 'claude.exe' -ErrorAction SilentlyContinue |
                 Sort-Object LastWriteTime -Descending | Select-Object -First 1 -ExpandProperty FullName
            if ($e) { return $e }
        }
        $gc = Get-Command claude.exe -ErrorAction SilentlyContinue
        if ($gc) { return $gc.Source }
        Start-Sleep -Milliseconds 700
    }
    return $null
}
function Launch-Login {
    $exe = Find-ClaudeExe
    if ($exe) {
        try { Start-Process -FilePath 'cmd.exe' -ArgumentList @('/k', ('"' + $exe + '" auth login --claudeai')) } catch {}
    } elseif (Test-Path $ReconnectCmd) {
        try { Start-Process -FilePath $ReconnectCmd } catch {}
    } else {
        [System.Windows.Forms.MessageBox]::Show('No encontre claude.exe. Abre Claude Code una vez y reintenta.','Claude Widget') | Out-Null
    }
}

function Fmt-Countdown($dt){ if(-not $dt){return '--'}; $ts=$dt-(Get-Date)
    if($ts.TotalMinutes -lt 0){return 'ya'}; if($ts.TotalHours -lt 24){return ('en {0}h {1:00}m' -f [int]$ts.TotalHours,$ts.Minutes)}
    return ('en {0}d {1}h' -f [int]$ts.TotalDays,$ts.Hours) }

function Update-Ui {
    $u = Get-OfficialUsage
    if ($script:State -eq 'ok' -and $u) {
        $cs=Sev-Color $u.SessSev $u.SessPct
        $lblSessPct.Text=('{0}%' -f $u.SessPct); $lblSessPct.ForeColor=$cs
        $barSess.Width=[int](228*[math]::Min(100,$u.SessPct)/100); $barSess.BackColor=$cs
        $lblSessRst.Text=('se reinicia {0}' -f (Fmt-Countdown $u.SessReset))
        $cw=Sev-Color $u.WeekSev $u.WeekPct
        $lblWeekPct.Text=('{0}%' -f $u.WeekPct); $lblWeekPct.ForeColor=$cw
        $barWeek.Width=[int](228*[math]::Min(100,$u.WeekPct)/100); $barWeek.BackColor=$cw
        if($u.WeekReset){ $lblWeekRst.Text=('se reinicia '+$u.WeekReset.ToString('ddd d, h:mm tt')) }else{ $lblWeekRst.Text='se reinicia --' }
        $lblFoot.ForeColor=$cMuted; $lblFoot.Font=New-Object System.Drawing.Font('Segoe UI',7,[System.Drawing.FontStyle]::Italic)
        $lblFoot.Text=('Oficial - actualizado '+$u.Stamp.ToString('h:mm tt'))
        $tray.Text=('Claude - Sesion {0}% - Semana {1}%' -f $u.SessPct,$u.WeekPct)
    }
    elseif ($script:State -eq 'expired') {
        $lblFoot.ForeColor=$cDanger; $lblFoot.Font=New-Object System.Drawing.Font('Segoe UI',8,[System.Drawing.FontStyle]::Bold)
        $lblFoot.Text='Token vencido - CLIC AQUI para reconectar'
        $tray.Text='Claude - token vencido (clic en widget)'
    }
    else {  # offline / nocreds
        $lblFoot.ForeColor=$cWarn; $lblFoot.Font=New-Object System.Drawing.Font('Segoe UI',8,[System.Drawing.FontStyle]::Regular)
        $lblFoot.Text='Sin conexion - reintentando...'
        $tray.Text='Claude - sin conexion'
    }
}

# ----- animacion deslizar arriba -----
$script:FinalTop=$wa.Bottom-200; $script:StartTop=$wa.Bottom; $script:Mode=''; $form.Top=$script:FinalTop
$anim=New-Object System.Windows.Forms.Timer; $anim.Interval=10
$anim.Add_Tick({
    if($script:Mode -eq 'show'){ $rem=$form.Top-$script:FinalTop; $form.Opacity=[math]::Min(0.96,$form.Opacity+0.14)
        if($rem -le 1){$form.Top=$script:FinalTop;$form.Opacity=0.96;$anim.Stop();return}; $form.Top=$form.Top-[math]::Max(7,[int]($rem*0.34)) }
    elseif($script:Mode -eq 'hide'){ $rem=$script:StartTop-$form.Top; $form.Opacity=[math]::Max(0.0,$form.Opacity-0.16)
        if($rem -le 1){$form.Hide();$form.Top=$script:FinalTop;$anim.Stop();return}; $form.Top=$form.Top+[math]::Max(7,[int]($rem*0.34)) }
})
function Show-Panel{ Update-Ui; $form.Top=$script:StartTop; $form.Opacity=0.0; $form.Show(); $form.Activate(); $script:Mode='show'; $anim.Start() }
function Hide-Panel{ $script:Mode='hide'; $anim.Start() }
function Toggle-Panel{ if($form.Visible -and $script:Mode -ne 'hide'){Hide-Panel}else{Show-Panel} }

# ----- eventos -----
$lblClose.Add_Click({ Hide-Panel })
$lblFoot.Add_Click({ if($script:State -eq 'expired'){ Launch-Login } else { Update-Ui } })
$miShow.Add_Click({ Toggle-Panel }); $miRef.Add_Click({ Update-Ui }); $miLogin.Add_Click({ Launch-Login })
$tray.Add_MouseClick({ if($_.Button -eq [System.Windows.Forms.MouseButtons]::Left){ Toggle-Panel } })
$miExit.Add_Click({ $timer.Stop(); $anim.Stop(); $tray.Visible=$false; $tray.Dispose(); [System.Windows.Forms.Application]::Exit() })
$form.Add_FormClosing({ $tray.Visible=$false; $tray.Dispose() })

$timer=New-Object System.Windows.Forms.Timer; $timer.Interval=120000; $timer.Add_Tick({ Update-Ui })
$timer.Start()
Show-Panel
[System.Windows.Forms.Application]::Run()
