#!/usr/bin/env bash
# Pruebas visibles · Enunciado 2 · Gimnasio (90 puntos)
F1="$(fecha_hora '+10 days 18:00')"; DIA1="$(fecha '+10 days')"

grupo "B · CRUD de actividades"
req POST /api/actividades "{\"nombre\":\"Spinning\",\"fechaHora\":\"$F1\",\"cupo\":20}"
check 4 "POST /api/actividades crea → 201" 'es 201'
check 2 "POST devuelve Location /api/actividades/{id}" 'location_ok "/api/actividades/"'
A1="$(nuevo_id)"
check 2 "La respuesta trae el id" '[ -n "$A1" ]'
req GET /api/actividades
check 2 "GET /api/actividades → 200 con una lista" 'es 200 && es_array'
req GET "/api/actividades/$A1"
check 2 "GET /api/actividades/{id} → 200 con la actividad" 'es 200 && campo_es .nombre Spinning'
req GET /api/actividades/999999
check 2 "GET de una actividad inexistente → 404" 'es 404'
req PUT "/api/actividades/$A1" "{\"nombre\":\"Spinning avanzado\",\"fechaHora\":\"$F1\",\"cupo\":25}"
check 3 "PUT /api/actividades/{id} → 200 con los datos nuevos" 'es 200 && campo_es .nombre "Spinning avanzado"'
req POST /api/actividades "{\"nombre\":\"Borrar\",\"fechaHora\":\"$F1\",\"cupo\":5}"; AB="$(nuevo_id)"
req DELETE "/api/actividades/$AB"
check 2 "DELETE /api/actividades/{id} → 204" 'es 204'
req GET "/api/actividades/$AB"
check 1 "La actividad borrada ya no existe → 404" 'es 404'

grupo "C · Validación y errores"
req POST /api/actividades '{"nombre":"","fechaHora":"2020-01-01T10:00:00","cupo":0}'
check 3 "Actividad inválida (nombre vacío, fecha pasada, cupo 0) → 400" 'es 400'
check 2 "El error tiene formato ProblemDetail" 'es_json_problem'
check 2 "El error indica el campo cupo en \"errores\"" 'tiene_error_en cupo'
req POST /api/inscripciones '{}'
check 3 "Inscripción sin datos → 400 con error en actividadId" 'es 400 && tiene_error_en actividadId'
req GET /api/actividades/abc
check 2 "Id no numérico (/api/actividades/abc) → 400" 'es 400'
req POST /api/actividades '{"nombre": "roto"'
check 3 "JSON mal formado → 400" 'es 400'

grupo "D · Relaciones y 404"
req POST /api/socios "{\"nombre\":\"Ana Díaz\",\"email\":\"ana$RND@mail.com\"}"
check 2 "POST /api/socios → 201" 'es 201'
S1="$(nuevo_id)"
req POST /api/inscripciones "{\"actividadId\":$A1,\"socioId\":$S1}"
check 3 "POST /api/inscripciones → 201 con estado CONFIRMADA" 'es 201 && campo_es .estado CONFIRMADA'
I1="$(nuevo_id)"
req POST /api/inscripciones "{\"actividadId\":999999,\"socioId\":$S1}"
check 2 "Inscripción a una actividad inexistente → 404" 'es 404'
req POST /api/inscripciones "{\"actividadId\":$A1,\"socioId\":999999}"
check 1 "Inscripción de un socio inexistente → 404" 'es 404'
req GET /api/actividades/999999/inscripciones
check 2 "GET /api/actividades/{id}/inscripciones de una actividad inexistente → 404" 'es 404'

grupo "E · Reglas de negocio"
req POST /api/inscripciones "{\"actividadId\":$A1,\"socioId\":$S1}"
check 6 "El mismo socio no se inscribe dos veces a la misma actividad → 409" 'es 409'
req POST /api/actividades "{\"nombre\":\"Yoga\",\"fechaHora\":\"$F1\",\"cupo\":2}"; A2="$(nuevo_id)"
for n in 1 2 3; do req POST /api/socios "{\"nombre\":\"Socio $n\",\"email\":\"s$n-$RND@mail.com\"}"; eval "SX$n=\$(nuevo_id)"; done
req POST /api/inscripciones "{\"actividadId\":$A2,\"socioId\":$SX1}"; IY="$(nuevo_id)"
req POST /api/inscripciones "{\"actividadId\":$A2,\"socioId\":$SX2}"
req POST /api/inscripciones "{\"actividadId\":$A2,\"socioId\":$SX3}"
check 6 "Con el cupo completo no se puede inscribir → 409" 'es 409'
req PATCH "/api/inscripciones/$IY/estado" '{"estado":"CANCELADA"}'
req POST /api/inscripciones "{\"actividadId\":$A2,\"socioId\":$SX3}"
check 4 "Una inscripción cancelada libera el lugar → 201" 'es 201'
FPRONTO="$(fecha_hora '+1 hour')"
req POST /api/actividades "{\"nombre\":\"Ya empieza\",\"fechaHora\":\"$FPRONTO\",\"cupo\":5}"; A3="$(nuevo_id)"
req POST /api/inscripciones "{\"actividadId\":$A3,\"socioId\":$S1}"; IP="$(nuevo_id)"
req PATCH "/api/inscripciones/$IP/estado" '{"estado":"CANCELADA"}'
check 4 "No se cancela con menos de 2 horas de anticipación → 409" 'es 409'

grupo "F · Estados de la inscripción"
req PATCH "/api/inscripciones/$I1/estado" '{"estado":"CANCELADA"}'
check 4 "CONFIRMADA → CANCELADA → 200" 'es 200 && campo_es .estado CANCELADA'
req PATCH "/api/inscripciones/$I1/estado" '{"estado":"ASISTIO"}'
check 4 "CANCELADA es final: CANCELADA → ASISTIO → 409" 'es 409'
req POST /api/inscripciones "{\"actividadId\":$A1,\"socioId\":$SX1}"; I2="$(nuevo_id)"
req PATCH "/api/inscripciones/$I2/estado" '{"estado":"ASISTIO"}'
check 3 "CONFIRMADA → ASISTIO → 200" 'es 200 && campo_es .estado ASISTIO'
req PATCH "/api/inscripciones/$I2/estado" '{}'
check 2 "PATCH sin estado → 400" 'es 400'
req PATCH /api/inscripciones/999999/estado '{"estado":"CANCELADA"}'
check 2 "PATCH de una inscripción inexistente → 404" 'es 404'

grupo "G · Consultas"
req GET "/api/actividades/$A2/inscripciones"
check 5 "GET /api/actividades/{id}/inscripciones → las 3 inscripciones de esa actividad" 'es 200 && largo_es 3'
req GET "/api/actividades?fecha=$DIA1"
check 5 "GET /api/actividades?fecha=AAAA-MM-DD → solo las de ese día" 'es 200 && largo_min 2 && todos_empiezan .fechaHora "$DIA1"'
