#!/usr/bin/env bash
# Pruebas visibles · Enunciado 5 · Eventos (90 puntos)
FE="$(fecha_hora '+30 days 21:00')"

grupo "B · CRUD de eventos"
req POST /api/eventos "{\"nombre\":\"Recital Rock $RND\",\"fecha\":\"$FE\",\"capacidad\":100,\"precio\":15000}"
check 4 "POST /api/eventos crea → 201" 'es 201'
check 2 "POST devuelve Location /api/eventos/{id}" 'location_ok "/api/eventos/"'
E1="$(nuevo_id)"
check 2 "La respuesta trae el id" '[ -n "$E1" ]'
req GET /api/eventos
check 2 "GET /api/eventos → 200 con una lista" 'es 200 && es_array'
req GET "/api/eventos/$E1"
check 2 "GET /api/eventos/{id} → 200 con el evento" 'es 200 && campo_es .nombre "Recital Rock $RND"'
req GET /api/eventos/999999
check 2 "GET de un evento inexistente → 404" 'es 404'
req PUT "/api/eventos/$E1" "{\"nombre\":\"Recital Rock $RND (nueva fecha)\",\"fecha\":\"$FE\",\"capacidad\":120,\"precio\":15000}"
check 3 "PUT /api/eventos/{id} → 200 con los datos nuevos" 'es 200 && numero_es .capacidad 120'
req POST /api/eventos "{\"nombre\":\"Borrar\",\"fecha\":\"$FE\",\"capacidad\":10,\"precio\":0}"; EB="$(nuevo_id)"
req DELETE "/api/eventos/$EB"
check 2 "DELETE /api/eventos/{id} → 204" 'es 204'
req GET "/api/eventos/$EB"
check 1 "El evento borrado ya no existe → 404" 'es 404'

grupo "C · Validación y errores"
req POST /api/eventos '{"nombre":"","fecha":"2020-01-01T20:00:00","capacidad":0,"precio":-5}'
check 3 "Evento inválido (nombre vacío, fecha pasada, capacidad 0, precio negativo) → 400" 'es 400'
check 2 "El error tiene formato ProblemDetail" 'es_json_problem'
check 2 "El error indica el campo capacidad en \"errores\"" 'tiene_error_en capacidad'
req POST /api/asistentes '{"nombre":"Ana","email":"no-es-un-mail"}'
check 3 "Asistente con email inválido → 400 con error en email" 'es 400 && tiene_error_en email'
req GET /api/eventos/abc
check 2 "Id no numérico (/api/eventos/abc) → 400" 'es 400'
req POST /api/eventos '{"nombre": "roto"'
check 3 "JSON mal formado → 400" 'es 400'

grupo "D · Relaciones y 404"
req POST /api/asistentes "{\"nombre\":\"Ana Díaz\",\"email\":\"ana$RND@mail.com\"}"
check 2 "POST /api/asistentes → 201" 'es 201'
AS1="$(nuevo_id)"
req POST /api/entradas "{\"eventoId\":$E1,\"asistenteId\":$AS1}"
check 3 "POST /api/entradas → 201 con estado RESERVADA" 'es 201 && campo_es .estado RESERVADA'
T1="$(nuevo_id)"
req POST /api/entradas "{\"eventoId\":999999,\"asistenteId\":$AS1}"
check 2 "Entrada para un evento inexistente → 404" 'es 404'
req POST /api/entradas "{\"eventoId\":$E1,\"asistenteId\":999999}"
check 1 "Entrada para un asistente inexistente → 404" 'es 404'
req GET /api/eventos/999999/entradas
check 2 "GET /api/eventos/{id}/entradas de un evento inexistente → 404" 'es 404'

grupo "E · Reglas de negocio"
req POST /api/entradas "{\"eventoId\":$E1,\"asistenteId\":$AS1}"
check 6 "Un asistente no tiene dos entradas activas para el mismo evento → 409" 'es 409'
req POST /api/eventos "{\"nombre\":\"Teatro chico $RND\",\"fecha\":\"$FE\",\"capacidad\":2,\"precio\":5000}"; E2="$(nuevo_id)"
for n in 1 2 3; do req POST /api/asistentes "{\"nombre\":\"Asistente $n\",\"email\":\"a$n-$RND@mail.com\"}"; eval "AX$n=\$(nuevo_id)"; done
req POST /api/entradas "{\"eventoId\":$E2,\"asistenteId\":$AX1}"; TY="$(nuevo_id)"
req POST /api/entradas "{\"eventoId\":$E2,\"asistenteId\":$AX2}"
req POST /api/entradas "{\"eventoId\":$E2,\"asistenteId\":$AX3}"
check 6 "No se venden más entradas que la capacidad → 409" 'es 409'
req PATCH "/api/entradas/$TY/estado" '{"estado":"ANULADA"}'
req POST /api/entradas "{\"eventoId\":$E2,\"asistenteId\":$AX3}"
check 4 "Una entrada anulada libera el lugar → 201" 'es 201'
req DELETE "/api/eventos/$E2"
check 4 "Un evento con entradas no se puede borrar → 409" 'es 409'

grupo "F · Estados de la entrada"
req PATCH "/api/entradas/$T1/estado" '{"estado":"USADA"}'
check 4 "No se saltean estados: RESERVADA → USADA → 409" 'es 409'
req PATCH "/api/entradas/$T1/estado" '{"estado":"PAGADA"}'
check 3 "RESERVADA → PAGADA → 200" 'es 200 && campo_es .estado PAGADA'
req PATCH "/api/entradas/$T1/estado" '{"estado":"RESERVADA"}'
check 4 "No se vuelve atrás: PAGADA → RESERVADA → 409" 'es 409'
req PATCH "/api/entradas/$T1/estado" '{}'
check 2 "PATCH sin estado → 400" 'es 400'
req PATCH /api/entradas/999999/estado '{"estado":"PAGADA"}'
check 2 "PATCH de una entrada inexistente → 404" 'es 404'

grupo "G · Consultas"
req GET "/api/eventos/$E2/entradas"
check 5 "GET /api/eventos/{id}/entradas → las 3 entradas de ese evento" 'es 200 && largo_es 3'
req GET "/api/eventos?nombre=teatro"
check 5 "GET /api/eventos?nombre=teatro → solo los que contienen “teatro”" 'es 200 && largo_min 1 && todos_contienen .nombre teatro'
