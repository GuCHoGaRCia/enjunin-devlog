# Genera el espejo publico "bitácora" de saas-turnos en C:\enjunin-devlog.
# Cada commit real se replica con su fecha y mensaje originales, pero el
# contenido es solo una linea en devlog.md (CERO codigo fuente).
$ErrorActionPreference = 'Stop'
[Console]::OutputEncoding = New-Object System.Text.UTF8Encoding($false)  # git sale en UTF-8
$git  = "$env:ProgramFiles\Git\cmd\git.exe"
$src  = 'C:\enjunin.com.ar'
$dst  = 'C:\enjunin-devlog'
$enc  = New-Object System.Text.UTF8Encoding($false)

if (Test-Path $dst) { Remove-Item -Recurse -Force $dst }
New-Item -ItemType Directory -Path $dst | Out-Null
& $git -C $dst init
& $git -C $dst config core.autocrlf false
& $git -C $dst config user.name  'GuCHo GaRCia'
& $git -C $dst config user.email 'guchogarcia@gmail.com'

$msgFile = Join-Path $env:TEMP 'devlog-msg.tmp'

# --- README inicial ---
$readme = @'
# EnJunin — bitácora de desarrollo (público, sin código fuente)

Repo **espejo documental** de la actividad de desarrollo del SaaS EnJunin
Turnos: cada entrada replica el **mensaje y la fecha real** de los commits
del repositorio privado, pero el contenido es solo una línea en `devlog.md`.

**No hay código fuente acá** — el desarrollo vive en repositorios privados.
'@
# --- header del devlog ---
$devlogHeader = @'
# Bitácora de desarrollo

Entradas en orden cronológico. Cada una replica el mensaje y la fecha de un
commit del repositorio privado `saas-turnos` — **solo texto, sin código**.

---
'@
[IO.File]::WriteAllText("$dst\devlog.md", $devlogHeader + "`n`n", $enc)

[IO.File]::WriteAllText("$dst\README.md", $readme, $enc)
& $git -C $dst add README.md devlog.md
[IO.File]::WriteAllText($msgFile, "docs: README + header de la bitacora publica (sin codigo fuente)`n", $enc)
& $git -C $dst commit -F $msgFile
if ($LASTEXITCODE -ne 0) { throw 'fallo el commit inicial' }

# --- extraer commits del repo real ---
$log = & $git -C $src log --reverse --format='%H%x1f%aI%x1f%B%x1e'
$records = ($log -join "`n") -split [char]0x1e | Where-Object { $_.Trim() -ne '' }

$n = 0
foreach ($r in $records) {
    $parts  = $r.Trim() -split [char]0x1f, 3
    $hash   = $parts[0]
    $fecha  = $parts[1]
    $msg    = $parts[2].TrimEnd()
    $corto  = $hash.Substring(0, 7)

    $lineas  = $msg -split "`n"
    $subject = $lineas[0].Trim()
    $cuerpo  = (($lineas | Select-Object -Skip 1) -join "`n").Trim()
    $dia     = $fecha.Substring(0, 10)

    $entry = "### $dia — $subject`n`n"
    if ($cuerpo -ne '') { $entry += "$cuerpo`n`n" }
    $entry += "---`n`n"

    [IO.File]::AppendAllText("$dst\devlog.md", $entry, $enc)

    $env:GIT_AUTHOR_DATE     = $fecha
    $env:GIT_COMMITTER_DATE  = $fecha
    & $git -C $dst add devlog.md
    [IO.File]::WriteAllText($msgFile, "$msg`n`nRef: saas-turnos@$corto`n", $enc)
    & $git -C $dst commit -F $msgFile
    if ($LASTEXITCODE -ne 0) { throw "fallo commit para $hash" }
    $n++
}
Remove-Item Env:\GIT_AUTHOR_DATE, Env:\GIT_COMMITTER_DATE -ErrorAction SilentlyContinue

"commits creados: $n"
"total en espejo: " + (& $git -C $dst rev-list --count HEAD)
& $git -C $dst log -3 --format='%h %ad %s' --date=iso
