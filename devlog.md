# Bitácora de desarrollo

Entradas en orden cronológico. Cada una replica el mensaje y la fecha de un
commit del repositorio privado `saas-turnos` — **solo texto, sin código**.

---

### 2026-09-22 — init: ecosistema enjunin.com.ar - Fase 1 MVP (turnos, super admin, caja, lista de espera) + docs roadmap/contexto

---

### 2026-09-22 — fix: subdominio inexistente responde 404 en vez de 500 (TenantCouldNotBeIdentifiedOnDomainException)

---

### 2026-09-23 — docs: repo privado GitHub saas-turnos + estado git en roadmap y contexto

---

### 2026-09-23 — feat: Etapas 9-10-11 - recordatorios email, UI planes/pagos, auditoria + Ley 25.326

Etapa 9: Mailable RecordatorioTurno + job EnviarRecordatorioTurno (claim condicional por query builder, failed() revierte), comando turnos:recordatorios {--dry} sobre cuentas trial/activa via \->run(), schedule horario, config recordatorio_horas, migracion recordatorio_enviado_at. Requiere DB_QUEUE_CONNECTION=mysql para que el payload lleve tenant_id.

Etapa 10: SuscripcionService::registrarPago (activacion/renovacion +1 mes, reactiva cuenta suspendida) y reactivar extraido, auditorias manuales con previos/nuevos estados; modal plan en /admin/cuentas (activar sin pago / registrar pago aprobado, historial de pagos 30).

Etapa 11: AuditoriaService + trait Auditable en 18 modelos (auditoria tenant con user_id / auditoria_central con model_id string - fix SQLSTATE 22007 vs Cuenta.id), enmascarado de password/2FA, listeners Login/Failed, sinAuditoria() para seeds; pantallas /turnos/auditoria, /admin/auditoria, /turnos/datos-personales; DatosPersonalesService (consultar/exportar/baja con anonimizacion + redaccion de auditorias previas, baja_datos solo nombres de campos); fix HMAC impersonar (email sin codificar) + auditoria impersonar. Fix: User declara trait Auditable (faltaba) y ejecutado_por usa data_get en vez de getEmailForAuth inexistente.

Tests: phpunit 6/6 (59); smokes auditoria 31, recordatorios 18, datos-personales 32, plan-pagos 30, caja 14, lista-espera 14 (0 FAIL, en secuencia); E2E HTTP 22 checks (403 rol, export, impersonar round-trip/tampered/expired). Docs: roadmap etapas 9-11 marcadas + checklist DB_QUEUE_CONNECTION; contexto-tecnico actualizado.

---

### 2026-09-23 — Etapa 12: facturacion con comprobantes inmutables

- Tabla tenant turnos_comprobantes: FK turno_id/paciente_id, numeracion
  correlativa por anio YYYY-NNNNNN (unique + reintento), columna generada
  turno_emitido + indice unico (un comprobante emitido por turno).
- Inmutabilidad en 3 capas: trigger BEFORE UPDATE que solo admite
  emitido->anulado con motivo (SQLSTATE 45000), guard del modelo
  (updating/deleting) y el indice unico de la BD.
- FacturacionService::emitir()/anular() con validaciones y auditoria
  (trait + anular_comprobante manual con previos/nuevos).
- UI /turnos/facturacion (admin+recepcion) + link en nav; comprobantes
  incluidos en datosCompletos/export de Ley 25.326.
- Smoke tests/smoke/facturacion.php: 39 OK, 0 FAIL.
- Verificacion: PHPUnit 6/6, smokes 178 OK en secuencia, E2E 26/26.
- Docs: roadmap (Etapa 12, regla 18, fase 3) y contexto-tecnico.

---

### 2026-09-23 — Etapa 14: preparacion de produccion cPanel (preflight + fixes de backups/alta de cuentas)

- Nuevo comando php artisan deploy:preflight: checklist §7 ejecutable
  (env, cola, caches, permisos, migraciones, tablas jobs, mysqldump, crons)
  con salida PASS/WARN/FAIL y modo --strict para el servidor.
  Dev: 12 PASS, 7 WARN (brecha dev-prod esperada), 0 FAIL.
- Pipeline de produccion verificado de punta a punta: optimize (config +
  routes + view cache) con la suite en verde bajo caches (PHPUnit 7/7,
  smokes 178 OK, E2E 26) y optimize:clear de vuelta a dev. route:cache
  acepta closures (Laravel 12 las serializa con SerializableClosure).
- .env.production.example: plantilla comentada de produccion (§7.2).
- Fix 1 (backups nunca funcionaron): Cuenta::databaseName() no existia
  (BadMethodCallException silenciada por un catch aguas abajo) y faltaba el
  '>' de redireccion en el comando de mysqldump (Couldn't find table).
  Ahora tenants:backup-all -> Exitosos: 1 con .sql real, y todo fallo
  queda en provisioning_logs (flag \ en respaldar).
- Fix 2 (alta de cuentas rota): crear() moria en el log->update() final y
  limpiarAFallo borraba la cuenta recien creada. Cubierto con el test
  test_crear_y_eliminar_cuenta_con_bd_propia (13 checks end-to-end).
- Test de dominio: env() -> config() (env() da null bajo config:cache).
- Docs: roadmap (Etapa 14, §7 pasos 2/4/7/8, verificacion 7/7) y
  contexto-tecnico (gotchas §3.18-21, conteos de migraciones, mapa).
- Verificacion: PHPUnit 7/7 (68 assertions), smokes 178 OK/0 FAIL,
  E2E 26/26, preflight 0 FAIL, backup y provisioning end-to-end OK.

---

### 2026-09-23 — Etapa 13: reportes de gestion (ocupacion, caja, ausencias, retencion)

- ReportesService: ocupacion por profesional (slots = horarios activos menos
  bloqueos sobre duracion efectiva, pct puede superar 100%, null sin slots),
  ingresos por caja con desglose por metodo, ausencias con top-10 de
  pacientes y retencion (base/rango/nuevos/perdidos).
- Helper rango(): formato AAAA-MM-DD, ordenamiento y tope 366 dias.
- UI Livewire /turnos/reportes (4 pestanas, gate admin+recepcion) + link en
  nav.
- Smoke tests/smoke/reportes.php: 71 OK, 0 FAIL.
- Docs: roadmap Etapa 13 completa; suite total 249 OK y E2E 30 checks.

---

### 2026-09-23 — docs + CI local: setup de tenant, E2E versionado y ajuste de CI

- tests/ci/setup_clinicavida.php: alta idempotente del tenant de prueba
  clinicavida para CI (TenantProvisioningService: BD + migraciones +
  TenantDatabaseSeeder).
- tests/e2e/: e2e_http.ps1 + e2e_setup.php + e2e_cleanup.php versionados
  (antes solo en Temp; 30 checks HTTP).
- Docs: roadmap seccion 6 y contexto-tecnico con el pipeline de GitHub
  Actions (phpunit + 8 smokes = 249 checks) y el E2E.
- El workflow .github/workflows/ci.yml queda en la rama LOCAL ci-workflow:
  el push esta bloqueado hasta que la credencial OAuth tenga scope
  workflow (accion del usuario; documentado en ambos docs).

---

### 2026-09-23 — e2e: scripts autocontenidos (sin rutas absolutas) + receta actualizada

- e2e_setup/e2e_cleanup: __DIR__ en vez de ruta absoluta al proyecto.
- e2e_http.ps1: jars en %TEMP%\enjunin-e2e, PHP via PHP_BIN/PATH con
  fallback a XAMPP, setup resuelto desde \.
- contexto-tecnico seccion 5: receta con la suite versionada.
- Verificado: E2E 30 OK / 0 FAIL + cleanup desde tests/e2e/.

---

### 2026-09-23 — deploy: artisan deploy:package (zip de produccion con autorevision)

- Empaqueta apps/plataforma en apps/build/turnos-deploy-<fecha>.zip:
  allowlist de directorios/archivos; excluye .env* (salvo *.example),
  logs, sqlite, runtime de storage y bootstrap/cache, public/storage y
  node_modules. Directorios vacios del esqueleto via addEmptyDir.
- Autorevision al cerrar el zip: 0 secretos + minimos presentes
  (exit 1 si falla). --dry-run lista inclusiones/exclusiones.
- Verificado: extraccion limpia (sin .env, artisan bootea) y
  deploy:preflight sobre el extracto = 10 PASS / 0 FAIL. Pint PASS.
- .gitignore raiz: /apps/build/.

---

### 2026-09-23 — docs: checklist 7.1 usa deploy:package + receta de comandos CI/zip

---

### 2026-09-24 — style: pint verde en todo el repo (43 archivos, 43 issues)

- pint (preset laravel) sobre app/, config/, migrations/, routes/ y
  tests/: concat_space, unary/not_operator_spaces,
  class_attributes_separation, ordered_imports, phpdoc, etc.
- Solo estilo, sin cambios semanticos.
- Verificacion completa post-fix: pint 148/148, phpunit 7/7 (68),
  8 smokes 249 OK / 0 FAIL, E2E 30/30 + cleanup.

---

### 2026-09-24 — docs: pint como paso #0 de la verificacion (roadmap 6 + contexto-tecnico)

- Orden de verificacion: pint --test (148) -> phpunit -> 8 smokes ->
  E2E 30. CI replica el mismo pipeline con el style gate.

---

### 2026-09-24 — e2e: version bash/curl (tests/e2e/e2e_http.sh) espejo de los 30 checks

- Mismos 30 checks y labels que e2e_http.ps1; corre en CI (ubuntu) y
  Git Bash. PHP via PHP_BIN/PATH/fallback XAMPP; jars en TMPDIR.
- Fix: page_status no debe truncar el jar (borraba la sesion del
  login y todos los GET daban 302).
- Verificado local: 30 OK / 0 FAIL + cleanup con artisan serve :8899.
- Docs: receta E2E y pipeline CI actualizados (paso #0 pint, E2E bash).

---

### 2026-09-24 — deploy: scripts/deploy-ftp.ps1 (subida FTP del zip) + docs

- scripts/deploy-ftp.ps1: sube el zip de deploy:package por FTP/FTPS
  (curl 8.21, -w/-T/--ftp-create-dirs). Password nunca en argv (config
  temporal UTF-8 sin BOM, borrado en finally) o env DEPLOY_FTP_PASS.
  2da barrera: re-valida el zip con PHP antes de conectar (detecta
  .env*/logs/sqlite). -DryRun sin credenciales, -Resume (-C -), -NoTls.
  ASCII puro: PS 5.1 lee .ps1 sin BOM como ANSI y un UTF-8 mal leido
  rompe el parseo (gotcha verificado en esta corrida).
- Tests: parse OK; dry-run sobre zip real OK (34.8 MB, 11992 entradas);
  zip malicioso con .env aborta exit 1; zip inexistente aborta exit 1.
- Docs: roadmap 7.1 (subida asistida), contexto-tecnico (receta) y
  **Fase 2 completada** (E9 recordatorios + E10 planes + E11 auditoria
  + backups verificados: las 4 items estaban en verde).

---

### 2026-09-24 — git: .gitattributes fuerza LF en *.sh

core.autocrlf=true local convierte a CRLF en cada checkout/rebase; el E2E
bash romperia con \\$'\\\\r': command not found\. El CI de Linux esta a salvo
(autocrlf off + actions/checkout), pero el working copy local quedaba a la
merced de la proxima operacion de git.

---

### 2026-09-24 — Etapa 15: sala de espera en vivo (estado en_atencion, tablero, +4 E2E)

---

### 2026-09-24 — Etapa 15: smoke 403 independiente de APP_DEBUG + docs (150 archivos pint)

---

### 2026-09-24 — Reportes: columna En at. en el breakdown por estado (smoke 75, total 270)

---

### 2026-09-24 — Etapa 16: consulta del médico (historia clinica append-only, fila propia, /turnos/usuarios)

- tabla turnos_historia_clinica (append-only, sin UI de edicion/borrado) + users.profesional_id con fallback por email (User::perfilProfesional)
- /turnos/consulta gate profesional: mobile-first, fila propia con Atender, form de evolucion, timeline de historia clinica; turnoMio() anti-tampering; acciones via TurnosService::marcar
- /turnos/usuarios gate admin: alta/edicion de cuentas con rol + vinculo profesional (nadie cambia su propio rol), auditoria de cambios de rol
- nav por roles: base admin/recepcion + bloque Mi consulta para profesional
- fix validacion: validator() con data plano y claves form.* no resuelve (via \->validate()); '' -> null antes de validar
- fixtures con autolimpieza previa por marcas (idempotencia tras crashes)
- smoke tests/smoke/consulta.php: 35 OK, 0 FAIL -> 10 smokes, 305 OK total
- E2E sh/ps1: +4 checks -> 38 (ps1: patron de contenido ASCII-safe por lectura ANSI sin BOM)
- docs: roadmap Etapa 16 + regla 21; conteos 156 pint / 305 smokes / 38 E2E

verificacion: pint PASS 156 · phpunit 7/7 (68) · 10 smokes 305/0 · E2E sh 38/0 · E2E ps1 38/0 · preflight 11 PASS/8 WARN/0 FAIL

---

### 2026-09-26 — deploy: arquitectura de convivencia cPanel sin SSH (2 zips + setup-once)

- deploy:package genera DOS zips con la carpeta destino embebida en la
  raiz: apps-turnos-*.zip (HOME -> ~/apps/turnos, con vendor) y
  public-turnos-*.zip (public_html/ -> public_html/turnos), cada uno con
  su autorevision; --out ahora es directorio.
- public/index.php autodetecta la base (local ../ | prod
  ~/apps/turnos), mismo patron que Enjunin Motors; sin storage:link
  (la app no usa el disco publico, assets por CDN).
- setup-once.php nuevo: inicializador one-shot para hostings SIN
  Terminal (key si vacia, migrate, seed, optimize, tenants:migrate),
  idempotente por marcas en storage/setup-once/, log propio y todo.ok;
  se instala como cron de 1 minuto y se retira al ver el OK.
- deploy-ftp.ps1 sube LOS DOS zips con re-validacion por zip (-DryRun
  muestra el plan de ambos con sus destinos).
- .env.production.example: runbook sin terminal + prefijo de BD usuario_
  que exige cPanel (DB_DATABASE y TENANCY_DB_PREFIX).
- docs/despliegue-cpanel.md NUEVA: guia completa de convivencia
  (public_html solo expuesto / ~/apps todo lo no expuesto, mismo patron
  que autos), DNS/subdominios/SSL (wildcard *.enjunin.com.ar ya cubre
  turnos.enjunin.com.ar; *.turnos.enjunin.com.ar queda pendiente),
  inicializacion por cron, 4 crons, preflight por cron, smoke de
  produccion, re-despliegues y gotchas.
- roadmap §7 + bloque Falta de Etapa 14 y contexto-tecnico §1b
  actualizados al plan sin-SSH; /enjunin/ (copia de la otra app) al
  .gitignore raiz; aprendizaje del mysqld caido con grants corrompidos.

Verificacion: pint PASS 157 archivos (+setup-once.php) · phpunit 7/7
(68) · 10 smokes 305 OK / 0 FAIL · E2E 38 OK / 0 FAIL ·
deploy:preflight 11 PASS / 8 WARN / 0 FAIL · deploy:package 2 zips OK.

---

### 2026-09-26 — repo: espejo local del hosting (public_html/ + apps/)

El repo local queda con la misma estructura que el servidor:

- public_html/ = lo que se sube al docroot: landing index.html
  PRESERVADA (hasta terminar el proyecto) + images/enjunin.jpg,
  .htaccess raiz (de autos, intacto), tmp/, enjunin-motors/,
  GuCHoGaRCia/, y los junctions autos/ y turnos/.
- apps/ = lo que se sube un nivel arriba: turnos/ (app Laravel,
  renombrada desde apps/plataforma), autos/ (repo Enjunin Motors,
  con su .git) y build/ (zips, gitignorado).
- public_html/{autos,turnos} son junctions a apps/*/public:
  scripts/link-public.ps1 los recrea tras un clone; PHP los
  resuelve, asi que la autodetector de public/index.php no cambia
  (y la rama de produccion ../../apps/turnos tambien resolveria
  en local porque el layout ES el del hosting).
- Docs actualizados: despliegue-cpanel.md agrega el §0.1 espejo
  local; contexto-tecnico.md §1b documenta la decision; paths
  apps/plataforma -> apps/turnos en todo el repo.

Verificado: pint 157 PASS · phpunit 7/7 (68) · smokes 305/0 ·
E2E 38/0 · preflight 11 PASS 8 WARN 0 FAIL · deploy:package 2 zips OK.

---

### 2026-09-26 — docs: gotcha de la copia descargada -> redistribuida en el espejo local

---

### 2026-09-26 — repo: ignora la vitrina local enjunin-turnos/ (repo con .git anidado)

---

### 2026-09-23 — ci: GitHub Actions con phpunit + los 8 smokes (249 checks)

---

### 2026-09-24 — ci: gate de pint (style) antes de phpunit

- vendor/bin/pint --test tras composer install: falla rapido si el
  estilo se rompe (repo actual: PASS 148 archivos).
- Encabezado y nombre del job actualizados.

---

### 2026-09-24 — ci: E2E HTTP bash (30 checks) como ultimo step del pipeline

- Levanta artisan serve :8899 (health /up con retry), corre
  tests/e2e/e2e_http.sh y exige 'RESULTADO E2E: 30 OK, 0 FAIL'.
- Pipeline completo: pint -> phpunit -> smokes 249 -> E2E 30.
- YAML validado con js-yaml; bash -n sobre el bloque run extraido.

---

### 2026-09-24 — ci: 9 smokes (270) + E2E 34 checks + pint 150 archivos (Etapa 15)

---

### 2026-09-24 — ci: 10 smokes (305) + E2E 38 checks + pint 156 archivos (Etapa 16)

smoke consulta.php (35 OK) al array; literales RESULTADO E2E 34->38; rebaseado sobre main (d361e77)

---

### 2026-09-26 — ci: pint a 157 archivos (setup-once.php, Etapa 14/convivencia cPanel)

---

