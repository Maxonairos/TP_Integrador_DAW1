#!/usr/bin/env bash
# Pruebas visibles · Enunciado 4 · Complejo deportivo (90 puntos)
DIA="$(fecha '+12 days')"
h() { echo "${DIA}T$1:00"; }          # h 10:00 → 2026-…T10:00:00

grupo "B · CRUD de canchas"
req POST /api/canchas '{"nombre":"Cancha 1","deporte":"Fútbol 5","precioHora":30000}'
check 4 "POST /api/canchas crea → 201" 'es 201'
check 2 "POST devuelve Location /api/canchas/{id}" 'location_ok "/api/canchas/"'
K1="$(nuevo_id)"
check 2 "La respuesta trae el id" '[ -n "$K1" ]'
req GET /api/canchas
check 2 "GET /api/canchas → 200 con una lista" 'es 200 && es_array'
req GET "/api/canchas/$K1"
check 2 "GET /api/canchas/{id} → 200 con la cancha" 'es 200 && campo_es .nombre "Cancha 1"'
req GET /api/canchas/999999
check 2 "GET de una cancha inexistente → 404" 'es 404'
req PUT "/api/canchas/$K1" '{"nombre":"Cancha 1 techada","deporte":"Fútbol 5","precioHora":35000}'
check 3 "PUT /api/canchas/{id} → 200 con los datos nuevos" 'es 200 && campo_es .nombre "Cancha 1 techada"'
req POST /api/canchas '{"nombre":"Borrar","deporte":"Pádel","precioHora":1000}'; KB="$(nuevo_id)"
req DELETE "/api/canchas/$KB"
check 2 "DELETE /api/canchas/{id} → 204" 'es 204'
req GET "/api/canchas/$KB"
check 1 "La cancha borrada ya no existe → 404" 'es 404'

grupo "C · Validación y errores"
req POST /api/canchas '{"nombre":"","deporte":"","precioHora":-1}'
check 3 "Cancha inválida (campos vacíos, precio negativo) → 400" 'es 400'
check 2 "El error tiene formato ProblemDetail" 'es_json_problem'
check 2 "El error indica el campo precioHora en \"errores\"" 'tiene_error_en precioHora'
req POST /api/clientes "{\"nombre\":\"Valida\",\"telefono\":\"3825000000\"}"; CV="$(nuevo_id)"
req POST /api/reservas "{\"canchaId\":$K1,\"clienteId\":$CV,\"inicio\":\"$(h 20:00)\",\"horas\":5}"
check 3 "Reserva de 5 horas (máximo 3) → 400 con error en horas" 'es 400 && tiene_error_en horas'
req GET /api/canchas/abc
check 2 "Id no numérico (/api/canchas/abc) → 400" 'es 400'
req POST /api/canchas '{"nombre": "roto"'
check 3 "JSON mal formado → 400" 'es 400'

grupo "D · Relaciones y 404"
req POST /api/clientes '{"nombre":"Ana Díaz","telefono":"3825123456"}'
check 2 "POST /api/clientes → 201" 'es 201'
C1="$(nuevo_id)"
req POST /api/reservas "{\"canchaId\":$K1,\"clienteId\":$C1,\"inicio\":\"$(h 10:00)\",\"horas\":2}"
check 3 "POST /api/reservas → 201 con estado PENDIENTE" 'es 201 && campo_es .estado PENDIENTE'
R1="$(nuevo_id)"
req POST /api/reservas "{\"canchaId\":999999,\"clienteId\":$C1,\"inicio\":\"$(h 08:00)\",\"horas\":1}"
check 2 "Reserva de una cancha inexistente → 404" 'es 404'
req POST /api/reservas "{\"canchaId\":$K1,\"clienteId\":999999,\"inicio\":\"$(h 08:00)\",\"horas\":1}"
check 1 "Reserva de un cliente inexistente → 404" 'es 404'
req GET /api/canchas/999999/reservas
check 2 "GET /api/canchas/{id}/reservas de una cancha inexistente → 404" 'es 404'

grupo "E · Reglas de negocio"
req GET "/api/reservas/$R1"
check 4 "El precio total lo calcula el sistema: 35000 × 2 h = 70000" 'es 200 && numero_es .precioTotal 70000'
req POST /api/reservas "{\"canchaId\":$K1,\"clienteId\":$C1,\"inicio\":\"$(h 11:00)\",\"horas\":1}"
check 6 "No se superponen reservas en la misma cancha (11:00 choca con 10:00–12:00) → 409" 'es 409'
req POST /api/reservas "{\"canchaId\":$K1,\"clienteId\":$C1,\"inicio\":\"$(h 12:00)\",\"horas\":1}"
check 4 "Una reserva que empieza justo cuando termina otra es válida → 201" 'es 201'
req PATCH "/api/reservas/$R1/estado" '{"estado":"CANCELADA"}'
req POST /api/reservas "{\"canchaId\":$K1,\"clienteId\":$C1,\"inicio\":\"$(h 11:00)\",\"horas\":1}"
check 6 "Una reserva cancelada libera el horario → 201" 'es 201'

grupo "F · Estados de la reserva"
req POST /api/reservas "{\"canchaId\":$K1,\"clienteId\":$C1,\"inicio\":\"$(h 16:00)\",\"horas\":1}"; R2="$(nuevo_id)"
req PATCH "/api/reservas/$R2/estado" '{"estado":"FINALIZADA"}'
check 4 "No se saltean estados: PENDIENTE → FINALIZADA → 409" 'es 409'
req PATCH "/api/reservas/$R2/estado" '{"estado":"CONFIRMADA"}'
check 3 "PENDIENTE → CONFIRMADA → 200" 'es 200 && campo_es .estado CONFIRMADA'
req PATCH "/api/reservas/$R2/estado" '{"estado":"PENDIENTE"}'
check 4 "No se vuelve atrás: CONFIRMADA → PENDIENTE → 409" 'es 409'
req PATCH "/api/reservas/$R2/estado" '{}'
check 2 "PATCH sin estado → 400" 'es 400'
req PATCH /api/reservas/999999/estado '{"estado":"CONFIRMADA"}'
check 2 "PATCH de una reserva inexistente → 404" 'es 404'

grupo "G · Consultas"
req GET "/api/canchas/$K1/reservas?fecha=$DIA"
check 5 "GET /api/canchas/{id}/reservas?fecha=AAAA-MM-DD → las de ese día" 'es 200 && largo_min 3 && todos_empiezan .inicio "$DIA"'
req GET "/api/clientes/$C1/reservas"
check 5 "GET /api/clientes/{id}/reservas → las 4 reservas de ese cliente" 'es 200 && largo_es 4'
