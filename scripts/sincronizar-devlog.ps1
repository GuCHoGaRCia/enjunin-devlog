# Sincroniza el espejo publico C:\enjunin-devlog con los commits NUEVOS
# de C:\enjunin.com.ar (saas-turnos). Idempotente: solo agrega los que
# aun no estan replicados (los identifica por el trailer "Ref: saas-turnos@").
$ErrorActionPreference = 'Stop'
[Console]::OutputEncoding = New-Object System.Text.UTF8Encoding($false)
$git  = "$env:ProgramFiles\Git\cmd\git.exe"
$src  = 'C:\enjunin.com.ar'
$dst  = 'C:\enjunin-devlog'
$enc  = New-Object System.Text.UTF8Encoding($false)
$msgFile = Join-Path $env:TEMP 'devlog-msg.tmp'

if (-not (Test-Path "$dst\.git")) { throw "no existe el espejo en $dst" }

# hashes ya replicados (trailer "Ref: saas-turnos@xxxxxxx")
$ya = @{}
$refs = & $git -C $dst log --format='%b'
foreach ($linea in $refs) {
    if ($linea -match 'Ref: saas-turnos@([0-9a-f]{7,40})') { $ya[$Matches[1]] = $true }
}

# commits origen aun no replicados (los mas viejos primero)
$log = & $git -C $src log --reverse --format='%H%x1f%aI%x1f%B%x1e'
$records = ($log -join "`n") -split [char]0x1e | Where-Object { $_.Trim() -ne '' }

$n = 0
foreach ($r in $records) {
    $parts  = $r.Trim() -split [char]0x1f, 3
    $hash   = $parts[0]
    $fecha  = $parts[1]
    $msg    = $parts[2].TrimEnd()
    $corto  = $hash.Substring(0, 7)

    $match = $false
    foreach ($k in $ya.Keys) { if ($hash.StartsWith($k) -or $k.StartsWith($corto)) { $match = $true; break } }
    if ($match) { continue }

    $lineas  = $msg -split "`n"
    $subject = $lineas[0].Trim()
    $cuerpo  = (($lineas | Select-Object -Skip 1) -join "`n").Trim()
    $dia     = $fecha.Substring(0, 10)

    $entry = "### $dia — $subject`n`n"
    if ($cuerpo -ne '') { $entry += "$cuerpo`n`n" }
    $entry += "---`n`n"
    [IO.File]::AppendAllText("$dst\devlog.md", $entry, $enc)

    $env:GIT_AUTHOR_DATE    = $fecha
    $env:GIT_COMMITTER_DATE = $fecha
    & $git -C $dst add devlog.md
    [IO.File]::WriteAllText($msgFile, "$msg`n`nRef: saas-turnos@$corto`n", $enc)
    & $git -C $dst commit -F $msgFile | Out-Null
    if ($LASTEXITCODE -ne 0) { throw "fallo commit para $hash" }
    $n++
}
Remove-Item Env:\GIT_AUTHOR_DATE, Env:\GIT_COMMITTER_DATE -ErrorAction SilentlyContinue

if ($n -eq 0) { "sin cambios: el espejo esta al dia ($($ya.Count) replicados)" }
else {
    "commits nuevos replicados: $n"
    & $git -C $dst push origin main
    "pusheados OK"
}
