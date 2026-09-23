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

