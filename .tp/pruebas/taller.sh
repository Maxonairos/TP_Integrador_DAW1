#!/usr/bin/env bash
# Pruebas visibles · Enunciado 3 · Taller mecánico (90 puntos)
pat() { printf 'AB%03dCD' "$(( (RND * 7 + $1) % 1000 ))"; }   # patente única por corrida (formato AB123CD)

req POST /api/clientes "{\"nombre\":\"Carlos Ruiz\",\"telefono\":\"3825123456\"}"; C1="$(nuevo_id)"

grupo "B · CRUD de vehículos"
P1="$(pat 1)"
req POST /api/vehiculos "{\"patente\":\"$P1\",\"marca\":\"Fiat\",\"modelo\":\"Cronos\",\"clienteId\":$C1}"
check 4 "POST /api/vehiculos crea → 201" 'es 201'
check 2 "POST devuelve Location /api/vehiculos/{id}" 'location_ok "/api/vehiculos/"'
V1="$(nuevo_id)"
check 2 "La respuesta trae el id" '[ -n "$V1" ]'
req GET /api/vehiculos
check 2 "GET /api/vehiculos → 200 con una lista" 'es 200 && es_array'
req GET "/api/vehiculos/$V1"
check 2 "GET /api/vehiculos/{id} → 200 con el vehículo" 'es 200 && campo_es .patente "$P1"'
req GET /api/vehiculos/999999
check 2 "GET de un vehículo inexistente → 404" 'es 404'
req PUT "/api/vehiculos/$V1" "{\"patente\":\"$P1\",\"marca\":\"Fiat\",\"modelo\":\"Cronos 1.3\",\"clienteId\":$C1}"
check 3 "PUT /api/vehiculos/{id} → 200 con los datos nuevos" 'es 200 && campo_es .modelo "Cronos 1.3"'
req POST /api/vehiculos "{\"patente\":\"$(pat 2)\",\"marca\":\"X\",\"modelo\":\"Y\",\"clienteId\":$C1}"; VB="$(nuevo_id)"
req DELETE "/api/vehiculos/$VB"
check 2 "DELETE /api/vehiculos/{id} → 204" 'es 204'
req GET "/api/vehiculos/$VB"
check 1 "El vehículo borrado ya no existe → 404" 'es 404'

grupo "C · Validación y errores"
req POST /api/vehiculos '{"patente":"123","marca":"","modelo":"","clienteId":null}'
check 3 "Vehículo inválido (patente mal formada, campos vacíos) → 400" 'es 400'
check 2 "El error tiene formato ProblemDetail" 'es_json_problem'
check 2 "El error indica el campo patente en \"errores\"" 'tiene_error_en patente'
req POST /api/ordenes '{}'
check 3 "Orden sin datos → 400 con error en vehiculoId" 'es 400 && tiene_error_en vehiculoId'
req GET /api/vehiculos/abc
check 2 "Id no numérico (/api/vehiculos/abc) → 400" 'es 400'
req POST /api/vehiculos '{"patente": "roto"'
check 3 "JSON mal formado → 400" 'es 400'

grupo "D · Relaciones y 404"
req POST /api/clientes "{\"nombre\":\"Ana Díaz\",\"telefono\":\"3825000000\"}"
check 2 "POST /api/clientes → 201" 'es 201'
C2="$(nuevo_id)"
req POST /api/ordenes "{\"vehiculoId\":$V1,\"descripcion\":\"Cambio de aceite\"}"
check 3 "POST /api/ordenes → 201 con estado INGRESADO" 'es 201 && campo_es .estado INGRESADO'
O1="$(nuevo_id)"
req POST /api/ordenes '{"vehiculoId":999999,"descripcion":"X"}'
check 2 "Orden para un vehículo inexistente → 404" 'es 404'
req POST /api/vehiculos "{\"patente\":\"$(pat 3)\",\"marca\":\"X\",\"modelo\":\"Y\",\"clienteId\":999999}"
check 1 "Vehículo de un cliente inexistente → 404" 'es 404'
req GET /api/clientes/999999/vehiculos
check 2 "GET /api/clientes/{id}/vehiculos de un cliente inexistente → 404" 'es 404'

grupo "E · Reglas de negocio"
req POST /api/ordenes "{\"vehiculoId\":$V1,\"descripcion\":\"Frenos\"}"
check 6 "Un vehículo con una orden abierta no puede tener otra → 409" 'es 409'
req POST /api/vehiculos "{\"patente\":\"$P1\",\"marca\":\"Otro\",\"modelo\":\"Otro\",\"clienteId\":$C2}"
check 6 "Patente repetida → 409" 'es 409'
req PATCH "/api/ordenes/$O1/estado" '{"estado":"EN_REPARACION"}'
req PATCH "/api/ordenes/$O1/estado" '{"estado":"TERMINADO"}'
req PATCH "/api/ordenes/$O1/estado" '{"estado":"ENTREGADO"}'
check 4 "No se entrega una orden sin costo final → 409" 'es 409'
req PUT "/api/ordenes/$O1" '{"descripcion":"Cambio de aceite y filtro","costoFinal":45000}'
req PATCH "/api/ordenes/$O1/estado" '{"estado":"ENTREGADO"}'
check 4 "Con costo final cargado (PUT) se puede entregar → 200" 'es 200 && campo_es .estado ENTREGADO'

grupo "F · Estados de la orden"
req POST /api/vehiculos "{\"patente\":\"$(pat 4)\",\"marca\":\"VW\",\"modelo\":\"Gol\",\"clienteId\":$C2}"; V2="$(nuevo_id)"
req POST /api/ordenes "{\"vehiculoId\":$V2,\"descripcion\":\"Embrague\"}"; O2="$(nuevo_id)"
req PATCH "/api/ordenes/$O2/estado" '{"estado":"TERMINADO"}'
check 4 "No se saltean estados: INGRESADO → TERMINADO → 409" 'es 409'
req PATCH "/api/ordenes/$O2/estado" '{"estado":"EN_REPARACION"}'
check 3 "INGRESADO → EN_REPARACION → 200" 'es 200 && campo_es .estado EN_REPARACION'
req PATCH "/api/ordenes/$O2/estado" '{"estado":"CANCELADO"}'
check 4 "Solo se cancela desde INGRESADO: EN_REPARACION → CANCELADO → 409" 'es 409'
req PATCH "/api/ordenes/$O2/estado" '{}'
check 2 "PATCH sin estado → 400" 'es 400'
req PATCH /api/ordenes/999999/estado '{"estado":"EN_REPARACION"}'
check 2 "PATCH de una orden inexistente → 404" 'es 404'

grupo "G · Consultas"
req GET "/api/clientes/$C2/vehiculos"
check 5 "GET /api/clientes/{id}/vehiculos → el vehículo de ese cliente" 'es 200 && largo_es 1'
req GET "/api/ordenes?estado=EN_REPARACION"
check 5 "GET /api/ordenes?estado=EN_REPARACION → solo esas" 'es 200 && largo_min 1 && todos_con .estado EN_REPARACION'
