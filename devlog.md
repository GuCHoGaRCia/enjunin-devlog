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

