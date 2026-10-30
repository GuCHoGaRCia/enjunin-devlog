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

### 2026-09-26 — ci: apps/plataforma -> apps/turnos (repo local ahora es el espejo del hosting)

---

### 2026-09-29 — docs: checklist de despliegue en hosting - roadmap ejecutable con gates (fases 2-4 completadas; subdominio turnos + SSL central verificados; alcance wildcard *.turnos cambiado a subdominio manual post-pago)

---

### 2026-09-30 — fix(turnos): setup-once requiere vendor/autoload (Class Application not found en CLI) + guarda PHP >= 8.2

---

### 2026-09-30 — fix(turnos): setup-once llama paso() sin signo \$ (Undefined variable en key:generate) + mkdir bootstrap/cache

---

### 2026-09-30 — fix(turnos): preflight acepta PHP >= 8.2 (8.3 soportado por Laravel 12; el CLI no lo gobierna MultiPHP)

---

### 2026-09-30 — fix(turnos): disco public apunta a public_path('storage') — hosting sin symlink()/exec() (cPanel compartido); en dev resuelve vía junction

---

### 2026-09-30 — fix(turnos): usePublicPath al docroot real (public_html/turnos) — en prod public_path() apuntaba a apps/turnos/public no servido (Vite, disco publico, preflight)

---

### 2026-10-04 — docs(checklist): cierra Fases 7 y 8 (setup-once, 4 crons, preflight 17/0/0, fixes public_path/filesystems/build, login /admin) + nota npm build en re-despliegues

---

### 2026-10-04 — feat(tenancy): subdominios planos {slug}.enjunin.com.ar — sin nivel .turnos.; el producto se diferencia por el docroot de cPanel; guardia de slugs vs CENTRAL_DOMAINS; docs y preflight actualizados (tests 6/6)

---

### 2026-10-04 — fix(livewire): resolver componentes fuera de class_namespace (419 en todo update)

---

### 2026-10-04 — fix(cuentas): incluir contacto_nombre y admin_password en reglas de validate (alta siempre fallaba)

---

### 2026-10-04 — feat(tenancy): alta tolera BD preexistente + traduce el 1044 de CREATE DATABASE a instrucciones de cPanel

---

### 2026-10-04 — fix: alta de paciente reventaba 500 con fecha_nacimiento vacia

Laravel saltea las reglas no implicitas sobre strings vacios (nullable|date nunca corrio), el '' del snapshot de Livewire llegaba al INSERT y MySQL strict lo rechazaba con SQLSTATE 22007. Normaliza '' -> null antes de validar, como ya hacia GestionUsuarios. Test de regresion PacienteAltaTest (rojo -> verde).

---

### 2026-10-04 — docs(checklist): Fase 9 — cuenta prueba creada (Opción B), smoke 5 y 6 en verde, bug 4 (500 al crear paciente por '' en fecha)

---

### 2026-10-09 — fix(scheduler): Schedule::call in-process — proc_open esta off en cPanel

schedule:run nunca ejecuto turnos:recordatorios en produccion: Laravel lanza
los comandos agendados como proceso hijo con proc_open, deshabilitado en el
PHP del hosting, y el fallo es silencioso (el schedule imprime DONE igual y
el error va a laravel.log). Fix: en prod, cron directo
`0 * * * * artisan turnos:recordatorios >> recordatorios.log` (guia 6) y
Schedule::call() in-process + name() como respaldo.

Docs: checklist Fase 9 paso 4 (cola con tenant_id) CERRADO con evidencia:
recordatorio_enviado_at seteado + failed_jobs con LOCATE(tenant_id)=435 y
TransportException (SMTP pendiente, Fase 4).

---

### 2026-10-09 — docs: Gate 10 paso 7 (autos) omitido por falta de credenciales; preflight informa el cron real de recordatorios

---

### 2026-10-09 — ﻿docs: GATE 10 PASADO - Fase 4 (Produccion cPanel) completa

Preflight final en prod con --strict: 17 PASS - 0 WARN - 0 FAIL
('Listo para produccion'). Fase 9 cerrada (smoke 1-6 en verde; paso 4
con evidencia de cola + tenant_id; paso 7/autos omitido por credenciales,
como deuda documentada). Roadmap: Fase 4 y Etapa 14 completadas.

---

### 2026-10-09 — ﻿docs: GATE 10 PASADO - Fase 4 (Produccion cPanel) completa

Preflight final en prod con --strict: 17 PASS - 0 WARN - 0 FAIL
('Listo para produccion'). Fase 9 cerrada (smoke 1-6 en verde; paso 4
con evidencia de cola + tenant_id; paso 7/autos omitido por credenciales,
como deuda documentada). Roadmap: Fase 4 y Etapa 14 completadas.

---

### 2026-10-09 — docs: checklist - estado final de los 4 crons verificado 09/10 (borradas temporales de preflight/config:cache/storage:link, recordatorios a la hora en punto)

---

### 2026-10-10 — feat(pagos): H1 Etapa 17 - nucleo de cobro con Mercado Pago

- config/services.php + .env(.production).example: claves MP_ACCESS_TOKEN,
  MP_PUBLIC_KEY, MP_WEBHOOK_SECRET, MP_AMBIENTE.
- Migraciones centrales: suscripciones.mp_preapproval_id(unico)/mp_estado/
  mp_init_point/mp_proxima_cobro_at; pagos.mp_payment_id (UNIQUE = llave de
  idempotencia del webhook); tabla webhook_events (auditoria + idempotencia
  de entrega).
- MercadoPagoClient: REST puro con Http:: (POST /preapproval, GET/PUT
  /preapproval/{id}, GET /v1/payments/{id}) sin SDK - 4 llamadas y cero
  vendor extra para el hosting compartido.
- CobroMercadoPagoService: iniciarCobro() (alta desde /admin sin regalar
  periodo; cambio de plan pausa el acuerdo viejo y crea el nuevo),
  registrarPagoAprobado() (idempotente por mp_payment_id, pendiente ->
  aprobado actualiza la misma fila y recien ahi renueva),
  sincronizarPreapproval() (paused -> suspender, canceled -> cancelar).
- Tests: 7 nuevos (53 assertions) -> suite 20/146 OK, pint PASS 170 files.

---

### 2026-10-10 — feat(pagos): webhook de Mercado Pago con firma e idempotencia (H2)

- FirmaWebhookMercadoPago: valida x-signature (HMAC SHA-256 sobre el
  manifest id/ts) con el gotcha de PHP verificado (?data.id llega como
  data_id): se leen ambos formatos de query.
- WebhookMercadoPagoController: responde 200 siempre (<22 s, MP reintenta
  cada 15 min), RE-CONSULTA a la API con nuestro token antes de confiar
  en el payload, y bitacora webhook_events con dedupe por evento_id +
  firma_ts. Errores de MP quedan en estado=error (los cierra H4).
- Rutas: POST /webhooks/mercadopago (throttle 60/min) y
  GET /suscripcion/retorno (back_url del checkout).
- CSRF excluido para webhooks/* en bootstrap/app.php.
- Vista pagos/retorno.blade.php autocontenida (sin @vite: la ve un
  cliente externo).
- Trait Tests\Concerns\FixturesDeFacturacion: fixtures de cuentas/planes
  compartidos por los tests de facturacion (refactor de CobroMercadoPagoTest).
- WebhookMercadoPagoTest: 7 tests (firma invalida 401 sin tocar la API,
  sin secreto configurado acepta, pago aprobado renueva, entrega repetida
  no duplica, topic desconocido ignorado, error de MP no revienta,
  back_url ok).

Suite: 27 tests / 176 assertions OK · Pint PASS

---

### 2026-10-10 — cobro(mp): external_reference con prefijo "turnos:" y pagos ajenos ignorados

La integracion de Mercado Pago es unica para todo EnJunin (enjunin.mp),
asi que los webhooks de ambas apps pueden recibir pagos de todas.
Ajustes:

- external_reference pasa a "turnos:suscripcion:{id}" (antes
  "suscripcion:{id}"): el prefijo de app hace imposible que una app
  futura que copie este codigo colisione con otra.
- registrarPagoAprobado: un pago sin nuestra referencia (y sin acuerdo
  nuestro) se ignora limpio (null + Log::info) en vez de lanzar
  excepcion; con nuestra referencia y sin suscripcion sigue siendo
  anomalia real -> excepcion.
- El reason del acuerdo en MP ahora lleva prefijo "[Turnos]" para
  distinguir los cobros en el panel unificado de la cuenta.
- Tests: pago de otra app ignorado + anomalia por referencia propia sin
  suscripcion (29 tests / 183 assertions OK, Pint PASS).

---

### 2026-10-14 — docs(roadmap): Etapa 17 (MP, pausa) + Etapa 18 (portal paciente, landing, HC Digital)

---

### 2026-10-14 — feat(portal): H0 Etapa 18 - middleware role en todo el backoffice + rol paciente

- EnsureRole (alias 'role') en TODAS las rutas /turnos/*: cierra el acceso
  al backoffice de usuarios sin rol (el registro abierto de Fortify creaba
  cuentas sin rol y Agenda/Pacientes/Profesionales/ListaEspera/Caja solo
  pedian 'auth').
- CreateNewUser asigna el rol 'paciente' al registrarse (guardia Role::
  findOrCreate para cuentas sin el seeder nuevo).
- Seeder de tenants crea el rol 'paciente'; '/' y '/home' redirigen por
  rol (paciente -> /paciente/turnos, staff -> agenda, super -> /admin).
- Nuevo smoke tests/smoke/portal-paciente.php -> 16 OK, 0 FAIL.
  Suite PHPUnit 29/183 OK. Pint PASS (176 archivos).

---

### 2026-10-14 — feat(portal): H1 Etapa 18 - landing publica del consultorio

- '/' en el subdominio deja de redirigir a login: el invitado ve la
  landing (nombre, especialidades, profesionales con su agenda semanal,
  obras sociales, contacto) con CTA Sacar turno / Iniciar sesion.
- Vista modules/turnos/landing.blade.php + layout components/layouts/
  public.blade.php (sin FullCalendar ni Livewire, solo Tailwind CDN).
- Helpers nombreConsultorio()/contactoConsultorio() en app/helpers.php
  (autoload via composer.json files): el nombre vive en la columna real
  tenants.nombre, no en el JSON data (tenant('nombre') daba null).
- DiasSemana::nombre() para rotular horarios.
- Smoke portal-paciente -> 25 OK, 0 FAIL. Pint PASS 178. PHPUnit 29/183.

---

### 2026-10-14 — feat(portal): H2 Etapa 18 - verificacion de email para pacientes

- User implementa MustVerifyEmail; feature emailVerification() activa en
  Fortify. El staff creado por admin nace verificado (no se traba).
- Notificacion VerifyEmailPortal con branding del consultorio
  (nombreConsultorio) y enlace firmado /email/verify (60 min).
- Smoke portal-paciente -> 29 OK, 0 FAIL. Pint PASS. PHPUnit 29/183.

---

### 2026-10-14 — feat(portal): H3 Etapa 18 - reserva online y Mis turnos del paciente

- TurnosService::slotsDisponibles(): huecos libres desde la grilla del
  profesional (turnos_horarios_atencion) menos turnos activos y bloqueos,
  con duracion efectiva. Sin grilla ese dia no se ofrece online.
- Migracion turnos_pacientes.user_id (FK users nullOnDelete): la ficha
  clinica queda atada al login del portal y se conserva si se borra la
  cuenta.
- PacientePortalService (deUsuario/crearDesdeUsuario/fichaObligatoria).
- Livewire PacienteTurnos (/paciente/turnos): proximos/pasados, cancelar
  con anticipacion minima, alta/edicion de ficha (obra social + nro de
  afiliado o particular).
- Livewire PacienteReservar (/paciente/reservar): profesional -> dia ->
  hora -> confirmar; alta via agendar() con las mismas reglas (un
  paciente nunca genera sobreturno).
- Rutas con auth + verified + role:paciente; layout components.layouts.public.
- Smoke portal-paciente -> 45 OK, 0 FAIL. Pint PASS 183. PHPUnit 29/183.

---

### 2026-10-14 — feat(portal): H4 Etapa 18 - ficha completa del paciente con HC y auditoria

- Migracion turnos_pacientes: alergias, medicacion_actual, antecedentes
  (datos clinicos relevantes de la ficha).
- ABM de recepcion edita los campos clinicos (validacion + form).
- Boton 'Ficha' abre el detalle: cobertura (obra social + nro de
  afiliado o Particular), contacto (aviso si tiene cuenta en el portal),
  resumen clinico y historia clinica en solo lectura (ultimas 50
  evoluciones).
- Cada apertura registra 'hc_acceso' en la bitacora (Ley 26.529
  Art.14: el paciente tiene derecho a saber quien accedio a su HC).
- Smoke portal-paciente -> 48 OK, 0 FAIL. Pint PASS 184. PHPUnit 29/183.

---

### 2026-10-14 — feat(portal): H5 Etapa 18 - cierre de consulta con HC firmada y proxima cita

- Catalogo CIE-10 curado (Support/Cie10, 78 codigos de consulta
  ambulatoria) con validacion 'in:' en el formulario de la consulta.
- Migraciones: turnos_profesionales.matricula (ABM de profesionales) y
  turnos_historia_clinica.{cie10_codigo,cie10_texto,profesional_matricula}
  - la matricula se snapshotea al firmar cada nota (Res. 434/2019: si
  cambia la matricula, la nota historica conserva la vigente entonces).
- Select CIE-10 en la pantalla del medico junto al diagnostico.
- Al finalizar la consulta se abre el panel 'Agendar la proxima cita':
  dia -> hora con slotsDisponibles() -> agendar() (mismas reglas que el
  portal, sin sobreturnos) u Omitir.
- Smoke portal-paciente -> 58 OK, 0 FAIL. Pint PASS 187. PHPUnit 29/183.

---

### 2026-10-14 — turnos H6: HC Digital conforme (Ley 26.529 / Dto 1089/2012 / Res 434/2019)

- Firma SHA-256 encadenada por paciente (HistoriaClinicaService::firmar
  en el evento creating; payload solo con campos inmutables porque los
  FK mutan por SET NULL sin disparar triggers).
- Inmutabilidad en BD: triggers SIGNAL 45000 bloquean UPDATE/DELETE;
  la baja del paciente borra la HC en cascada (accion FK sin trigger).
- Correccion solo por enmienda (enmienda_de_id) con UI en Consulta y
  badges en staff/portal.
- verificarCadena() detecta notas con firma falsa o contenido alterado.
- Exportacion JSON de la HC (actos + firmas + verificacion + retencion
  10 anos, config/turnos.php) auditada como export_datos.
- Portal /paciente/historia-clinica: lectura propia con badge de
  integridad y seccion Accesos a mi historia clinica (Art. 14; el
  acceso del titular no se registra). Sin PII en descripciones de
  bitacora (correccion del patron Etapa 11).
- E2E HTTP +14 checks (landing, portal, HC, EnsureRole del portal):
  52 OK, 0 FAIL. Smoke portal-paciente 86 OK, 0 FAIL. Pint PASS 192;
  PHPUnit 29/183.

---

### 2026-10-16 — docs: README del proyecto con capturas + estado de la Etapa 18 desplegada

- README.md nuevo: que es el producto, caracteristicas (paciente /
  staff / cumplimiento normativo), arquitectura multi-tenant con diagrama
  Mermaid, roadmap de 18 etapas, stack, verificacion y despliegue.
- 7 capturas en docs/images/ generadas contra el tenant local (landing,
  agenda, pacientes, portal del paciente, historia clinica digital,
  panel central y login).
- roadmap.md: Etapa 18 marcada completada y desplegada; registro de
  cierre en produccion (codigo FTP, 6 migraciones, columnas y triggers
  de inmutabilidad, 4 crons) con SMTP y preflight como pendientes.
- checklist: anexo del re-despliegue de la Etapa 18 (File Manager
  trunca zips grandes -> subir por FTP).
- tests/demo/seed_demo.php: seeder idempotente de dataset de demo con
  guarda anti-produccion (para demos y capturas).

---

### 2026-10-16 — docs(README): diagrama Mermaid conservador (subgrafos primero) y anclas de navegacion corregidas

---

### 2026-10-16 — style: Pint fix en tests/demo/seed_demo.php (193 archivos PASS)

---

### 2026-10-16 — feat(demo): seeder autosuficiente (asegura catalogos y resuelve por nombre) para cualquier tenant

---

### 2026-10-16 — fix(demo): emails de demo agnosticos al tenant (correo.test en vez de clinicavida.test)

---

### 2026-10-16 — feat(ops): mail-test.php — prueba de envio real por cron con diagnostico puerto/auth/dominio

---

### 2026-10-17 — fix(ops): mail-test barre puertos Resend (587/2587/2465/465) en una corrida — el hosting filtra el 465

---

### 2026-10-17 — feat(mail): transporte ResendApiTransport (API HTTPS) — el hosting filtra todo el SMTP saliente

---

### 2026-10-18 — fix(ui): marca del tenant en login/nav + nav con menu Mas + 105 campos sin borde y su padding

---

### 2026-10-18 — docs(roadmap): Etapa 18 CERRADA en prod (SMTP Resend API + preflight 17 PASS) + pulido UI demo y gotchas de produccion

---

### 2026-10-23 — fix(lang): traducciones es completas (146 keys) — auth/validation/passwords/pagination devolvian la key cruda en pantalla

---

### 2026-10-23 — feat(mp): H4 — cron de reconciliacion turnos:mp-reconciliar (cada 6 h) recupera cobros que el webhook no entrego

---

### 2026-10-23 — feat(mp): H3 — panel /admin/pagos (KPIs por moneda, acuerdos MP con Cobrar, historial y filtros)

---

### 2026-10-23 — fix(preflight): MAIL_MAILER=resend ya cuenta como PASS (transporte propio por API, Plan B) — era falsa alarma del chequeo pre-Resend

---

### 2026-10-23 — docs: Etapa 17 DESPLEGADA en prod (panel + cron) — roadmap, 5to cron en checklist, gotchas del despliegue

---

### 2026-10-24 — feat(agenda): doble clic -> ficha del paciente + toast flotante para el rechazo de un drag

- Doble clic sobre un turno abre la ficha rapida del paciente (contacto
  cliquiable, cobertura, datos clinicos con alergias destacadas y ultimos
  turnos); el clic simple sigue abriendo la edicion (ventana de 300 ms).
- Toast de flash flotante (fixed, z-60, auto-oculto a los 7s): antes vivia
  arriba del calendario y el rechazo de un drag se leia como "no quedo
  grabado" porque uno miraba el punto de soltada.
- wire:ignore en #calendar: el morph de Livewire vaciaba el contenedor en
  cada render (ficha/edicion) y FullCalendar quedaba en blanco hasta el
  proximo agenda-actualizada.
- wire:key unico en el toast: el morph conservaba el nodo y Alpine
  mantenia visible=false del render anterior, asi que los siguientes
  toasts no se veian nunca.
- Sin bloques @php en la vista: compileStatements de Blade los deja a
  medias en esta plantilla (directivas crudas y echos sin compilar).
- 4 tests nuevos: AgendaFichaPacienteTest (259 assertions en total).

---

### 2026-10-24 — feat(mail): confirmación de reserva online + FROM name del consultorio

- ConfirmacionTurno: mail de confirmación cuando el paciente reserva
  online (fecha, profesional, cobertura de datos y link a Mis turnos).
  Se envía FUERA del try de la reserva: si el envío falla, el turno ya
  existe, se reporta el error y la reserva sigue igual.
- BrandingMails: al inicializar tenancy mail.from.name pasa a
  nombreConsultorio() y se revierte al terminar (un worker de cola con
  varios tenants no arrastra el nombre de una cuenta a otra). Cubre de
  una sola vez la verificación de email, el recordatorio, el reset de
  clave y esta confirmación, que salían con "EnJunin Plataforma".
- Purge del mailer junto con el config: Mailer cachea el from al
  construirse (MailManager::resolve), si no quedaba el nombre viejo.
- Fix de tipeo: "próximos7 días" en el paso 2 de la reserva.

Tests: ConfirmacionTurnoOnlineTest (3 tests / 19 assertions) — reserva
real con Mail::fake, remitente ida y vuelta con reflection sobre el
mailer, y SMTP caído sin perder el turno. Suite completa 44/278 OK.

---

### 2026-10-24 — Etapa 19: datos del consultorio (direccion, WhatsApp, horarios, redes y mapa)

El consultorio edita sus datos publicos desde su propio backoffice
(/turnos/consultorio, solo rol admin) y se reflejan en la landing, en el
footer publico, en el login y en el pie de los mails.

- Columnas nuevas en `tenants`: direccion, whatsapp, horarios (json, 7 dias)
  y redes (json) + migracion central 2026_10_24_000001 (en prod: SQL en
  phpMyAdmin, no hay artisan).
- Cuenta::getConnectionName() fuerza la conexion central (mismo criterio que
  CentralModel): sin eso, un find() en contexto tenant apunta a la BD del
  consultorio y revienta con "table tenants doesnt exist".
- Helpers: contactoConsultorio() ampliada (direccion, whatsapp_url, horarios,
  redes, maps_url, maps_embed) + horariosTextoConsultorio() (agrupa dias
  consecutivos iguales: "Lun a Vie 08:00 a 18:00"), redesConsultorio(),
  normalizarRed(), pieContactoMail(), enlaceWhatsApp/enlaceMaps/embebidoMaps.
- Google Maps sin API key: iframe output=embed en la landing y solo link en
  los mails (los clientes de correo no muestran iframes).
- Pantalla Livewire Consultorio + vista, con grilla de 7 dias (dia cerrado =
  no se muestra), redes (URL o @usuario) y validaciones de tramo horario.
- Mails: nuevo partial mail/partials/pie-contacto.blade.php, con $pie resuelto
  al enviar para no depender de tenancy si el mail sale encolado.
- Apoyo: Support/ConsultorioRedes (plataformas/etiquetas/placeholders) y
  DiasSemana::ABREVIATURAS.
- Docs: roadmap (Etapa 19) y checklist de despliegue (22 archivos, SQL y
  borrar bootstrap/cache/routes-*.php: es la primera subida con ruta nueva).
- Tests: DatosConsultorioTest (6 tests / 38 assertions). Suite total
  50 tests / 316 assertions PASS. Pint 213 archivos PASS.

---

### 2026-10-24 — Etapa 19b: equipo medico (careteo) como subtitulo + direcciones de Junin (BA)

- Nueva columna `equipo` (varchar 500) en `tenants`: nombres de los doctores
  que la componen, separados por coma. Si queda VACIA no se muestra en el
  perfil publico (hero de la landing y bajo el titulo del login).
- Criterio de ubicacion: todas las cuentas del SaaS son de Junin (BA) - de
  ahi el nombre enjunin.com.ar - por eso direccionPublica() completa la
  direccion con ", Junin, Buenos Aires" solo si viene sin ciudad (sin coma);
  si quien carga ya escribio ciudad y provincia se respeta tal cual. El link
  y el iframe de Google Maps usan esa direccion completa (idempotente).
- Formulario del backoffice: campo "Equipo medico (subtitulo)" (textarea,
  max 500) con la ayuda "si queda vacio no se muestra", y placeholders de
  ejemplo de Junin (Av. Illia 1450, Junin, Buenos Aires / tel 2364).
- Helpers: equipoConsultorio() (split por coma, punto medio, punto y coma o
  salto de linea) + clave `equipo` en contactoConsultorio().
- Demo local (Clinica Vida): direccion de Junin y equipo cargado.
- Docs: roadmap (Etapa 19) y checklist (SQL ahora con `equipo` + SQL opcional
  de direccion de demo).
- Tests: DatosConsultorioTest 8 tests / 50 assertions. Suite total
  52 tests / 328 assertions PASS. Pint 213 archivos PASS.

---

### 2026-10-25 — Etapa 20: landing comercial central con precios y demo de drag & drop

- `resources/views/welcome.blade.php` reescrita: la portada de
  turnos.enjunin.com.ar dejo de ser la welcome de Laravel y ahora es la
  pagina de venta de la app de consultorios / turnos.
  - Nav + hero con CTA a precios, demo y panel.
  - Funciones (8): agenda visual, agenda por profesional, pacientes,
    lista de espera, reserva online, sala de espera, historia clinica y
    recordatorios/cobros.
  - Como funciona (5 bloques): la agenda, los pacientes, la lista de
    espera, la agenda por profesional y la reserva de turnos online.
  - Precios: 4 planes con limites de profesionales/sedes/turnos.
  - CTA final + footer.
- Precios leidos de la tabla `planes` (modulo turnos) desde
  `routes/web.php`, envueltos en `rescue(..., [])`: si la BD no responde o
  no hay filas, la seccion queda con mensaje de contacto en vez de 500 en
  la portada.
- Demo de cambio de turnos con drag & drop: mini-agenda de 8 horarios con
  2 turnos arrastrables. HTML5 drag & drop + fallback tactil (tocar turno
  y luego horario) porque en celular no hay DnD nativo; eventos delegados
  en el contenedor para que "Restaurar" pueda reemplazar el HTML.
  La agenda real ya lo hace: `editable: true` -> `Agenda::reprogramar()`.
- Tests: LandingCentralTest (2 tests / 14 assertions). Suite total
  54 tests / 342 assertions PASS. Pint 214 archivos PASS.
- Docs: roadmap (Etapa 20) y checklist (Anexo Ronda 2: subida de 2
  archivos, renombre de prueba -> consultoriosvida, circuito UAT de punta
  a punta y gotchas del alta de cuentas).

---

### 2026-10-25 — Etapa 21: SSO EnJunin (cookie enjunin_sso) para un solo login

- `app/Http/Middleware/SsoEnjunin.php` (nuevo): va en el grupo de `/admin`
  ANTES de `auth`. Valida la cookie firmada con HMAC-SHA256 (`SSO_SECRET` de
  `.env`) y deja el panel abierto SIN clave, pero únicamente si ese email es
  super-admin central: la cookie aporta identidad, nunca permisos. Si hay
  sesión de super-admin, (re)emite la cookie (dominio `SSO_COOKIE_DOMAIN`,
  Secure en https, HttpOnly, SameSite=Lax, 12 h, renueva con < 10 min).
- `SSO_SECRET` vacío → middleware apagado (comportamiento anterior).
- `bootstrap/app.php`: `EncryptCookies::except('enjunin_sso')` (Enjunin Motors
  es PHP a secas: no puede descifrar con nuestro APP_KEY) + el middleware en
  la lista de prioridad antes del ancla `AuthenticatesRequests`, para que
  `Authenticate` no se lo salte (mismo truco que `CentralOnly`).
- `routes/web.php`: `SsoEnjunin` en el grupo del panel central.
- `tests/Feature/PanelSsoTest.php`: 8 tests / 19 assertions (entra sin clave,
  no entra sin rol, firma falsa, vencida, emisión, apagado).
- Verificación: suite 62 tests / 361 assertions PASS · Pint 216 PASS.
- Docs: roadmap Etapa 21 y checklist (Ronda 3: 3 archivos de turnos + 5 de
  autos + `SSO_SECRET`/`SSO_COOKIE_DOMAIN` en el `.env` y `sso_secret` en el
  `config/config.php` de autos, con el MISMO valor).

---

### 2026-10-30 — Etapa 22+23: marca del consultorio en la landing y los tres roles del consultorio

Etapa 22 — landing del consultorio (portada, logo y frase):
- Migración central 2026_10_28_000001: columnas foto_portada y frase(180) en tenants.
- Cuenta (central): foto_portada y frase en $fillable y getCustomColumns().
- helpers: rutaImagenConsultorio(), logoConsultorio(), portadaConsultorio() y
  fraseConsultorio() devuelven null si no existe el archivo (fallback).
- ConsultorioImagenesController (POST /turnos/consultorio/imagenes, role:admin):
  subida de logo/portada (jpg/jpeg/png/webp, 2-4 MB max), quitar_logo /
  quitar_portada, borra solo dentro de la carpeta del tenant; la frase se lee con
  array_key_exists porque ConvertEmptyStringsToNull entrega null.
- Storage: public/uploads/consultorios/{slug}/ con nombres estables logo.ext /
  portada.ext; en la BD la ruta relativa al docroot; sin storage:link (en prod no existe).
- Landing: hero con portada de fondo (velo linear-gradient, fallback al degradado
  violeta), logo h-20 y frase que reemplaza la bajada por defecto. Layout publico:
  favicon + meta description + og:* con la marca del consultorio.
- .gitignore: /public/uploads/.
- MarcaConsultorioTest: 7 tests / 52 assertions PASS.

Etapa 23 — tres roles por consultorio:
- Usuarios\Support\Roles: etiquetas humanas Administrador / Secretaria / Medico /
  Paciente con descripcion y color de badge. Los slugs NO cambian
  (admin/recepcion/profesional/paciente): solo cambia lo que se muestra.
- GestionUsuarios multi-rol: form.roles (checkboxes), los roles del portal
  (paciente) se preservan, autofrota (nadie se quita Administrador desde su propia
  cuenta) y vinculo profesional editable (para el medico-dueno).
- Nav: badge con la etiqueta humana junto al nombre.
- MatrizRolesTest: 8 tests / 84 assertions PASS.

Suite al cerrar ambas etapas: 77 tests / 497 assertions PASS, Pint PASS.

---

### 2026-10-30 — Etapa 24: recetas y ordenes del consultorio (codigo unico, vigencia 30/60, firma SHA-256 y QR)

El medico emite desde su consulta el documento que el paciente lleva a la
farmacia/obra social. Alcance legal en docs/receta-electronica.md: no somos
plataforma inscripta en el ReNaPDiS, asi que esto es el documento del
consultorio (identificador unico, vigencia, firma y verificacion) con nota
legal explicita; la integracion ReNaPDiS (CUIR) queda como trabajo futuro.

- Tabla tenant turnos_recetas (migracion 2026_10_28_100000): codigo unico, FKs
  paciente/turno/profesional/user, tipo, CIE-10, items JSON, indicaciones,
  emitida_el/vence_el, estado (emitida/anulada), motivo de anulacion y firma
  SHA-256 encadenada por paciente (misma tecnica H6: alterar o insertar una fila
  rompe la cadena). Baja del paciente -> cascada; del profesional/turno -> se
  conserva.
- RecetaService: emitir (vigencia 30 dias para medicamentos / 60 para el resto,
  por Decreto 98/2023), anular (nunca se borra), firmar/verificar/calcularFirma,
  codigoUnico (12 caracteres en 3 bloques, alfabeto sin 0/O/1/I -> se transcribe
  a mano desde el papel) y urlVerificacion.
- Support\Qr: QR en SVG con bacon/bacon-qr-code (ya en el vendor por
  laravel/fortify; cero dependencias nuevas; sin GD ni Imagick).
- Pantalla /turnos/recetas (Livewire Recetas, role:admin,profesional; emite solo
  el profesional y requiere perfil vinculado): filtros por estado/vigencia,
  lista con badges, impresion y anulacion con motivo.
- /turnos/receta/{id} (admin+profesional): hoja imprimible autocontenido (CSS
  propio, sin CDNs), con QR, linea de firma y nota legal ReNaPDiS.
- Verificacion publica /receta/{codigo} (sin login): estado, fechas, consultorio,
  profesional + matricula y firma; nunca datos del paciente (Ley 25.326).
- Nav: link "Recetas" para admin y profesional.
- RecetaTest: 10 tests / 86 assertions PASS.

Suite completa: 87 tests / 583 assertions PASS, Pint 228 archivos PASS.

---

