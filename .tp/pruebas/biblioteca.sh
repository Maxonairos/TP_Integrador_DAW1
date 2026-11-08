#!/usr/bin/env bash
# Pruebas visibles · Enunciado 1 · Biblioteca (90 puntos)
DEV="$(fecha '+20 days')"

grupo "B · CRUD de libros"
req POST /api/libros "{\"titulo\":\"Rayuela\",\"autor\":\"Julio Cortázar\",\"isbn\":\"ISBN-A$RND\"}"
check 4 "POST /api/libros crea → 201" 'es 201'
check 2 "POST devuelve Location /api/libros/{id}" 'location_ok "/api/libros/"'
L1="$(nuevo_id)"
check 2 "La respuesta trae el id" '[ -n "$L1" ]'
req GET /api/libros
check 2 "GET /api/libros → 200 con una lista" 'es 200 && es_array'
req GET "/api/libros/$L1"
check 2 "GET /api/libros/{id} → 200 con el libro" 'es 200 && campo_es .titulo Rayuela'
req GET /api/libros/999999
check 2 "GET de un libro inexistente → 404" 'es 404'
req PUT "/api/libros/$L1" "{\"titulo\":\"Rayuela (2.ª ed.)\",\"autor\":\"Julio Cortázar\",\"isbn\":\"ISBN-A$RND\"}"
check 3 "PUT /api/libros/{id} → 200 con los datos nuevos" 'es 200 && campo_es .titulo "Rayuela (2.ª ed.)"'
req POST /api/libros "{\"titulo\":\"Borrar\",\"autor\":\"X\",\"isbn\":\"ISBN-B$RND\"}"; LB="$(nuevo_id)"
req DELETE "/api/libros/$LB"
check 2 "DELETE /api/libros/{id} → 204" 'es 204'
req GET "/api/libros/$LB"
check 1 "El libro borrado ya no existe → 404" 'es 404'

grupo "C · Validación y errores"
req POST /api/libros '{"titulo":"","autor":"","isbn":""}'
check 3 "Libro con campos vacíos → 400" 'es 400'
check 2 "El error tiene formato ProblemDetail" 'es_json_problem'
check 2 "El error indica el campo titulo en \"errores\"" 'tiene_error_en titulo'
req POST /api/socios "{\"nombre\":\"Valida\",\"email\":\"valida$RND@mail.com\"}"; SV="$(nuevo_id)"
req POST /api/libros "{\"titulo\":\"Valida\",\"autor\":\"X\",\"isbn\":\"ISBN-V$RND\"}"; LV="$(nuevo_id)"
req POST /api/prestamos "{\"libroId\":$LV,\"socioId\":$SV,\"fechaDevolucion\":\"2020-01-01\"}"
check 3 "Préstamo con fecha de devolución pasada → 400 con error en fechaDevolucion" 'es 400 && tiene_error_en fechaDevolucion'
req GET /api/libros/abc
check 2 "Id no numérico (/api/libros/abc) → 400" 'es 400'
req POST /api/libros '{"titulo": "roto"'
check 3 "JSON mal formado → 400" 'es 400'

grupo "D · Relaciones y 404"
req POST /api/socios "{\"nombre\":\"Ana Díaz\",\"email\":\"ana$RND@mail.com\"}"
check 2 "POST /api/socios → 201" 'es 201'
S1="$(nuevo_id)"
req POST /api/libros "{\"titulo\":\"Ficciones\",\"autor\":\"Borges\",\"isbn\":\"ISBN-C$RND\"}"; L3="$(nuevo_id)"
req POST /api/prestamos "{\"libroId\":$L3,\"socioId\":$S1,\"fechaDevolucion\":\"$DEV\"}"
check 3 "POST /api/prestamos → 201 con estado ACTIVO" 'es 201 && campo_es .estado ACTIVO'
P1="$(nuevo_id)"
req POST /api/prestamos "{\"libroId\":999999,\"socioId\":$S1,\"fechaDevolucion\":\"$DEV\"}"
check 2 "Préstamo de un libro inexistente → 404" 'es 404'
req POST /api/prestamos "{\"libroId\":$L1,\"socioId\":999999,\"fechaDevolucion\":\"$DEV\"}"
check 1 "Préstamo a un socio inexistente → 404" 'es 404'
req GET /api/socios/999999/prestamos
check 2 "GET /api/socios/{id}/prestamos de un socio inexistente → 404" 'es 404'

grupo "E · Reglas de negocio"
req POST /api/socios "{\"nombre\":\"Otro\",\"email\":\"otro$RND@mail.com\"}"; SO="$(nuevo_id)"
req POST /api/prestamos "{\"libroId\":$L3,\"socioId\":$SO,\"fechaDevolucion\":\"$DEV\"}"
check 6 "Un libro ya prestado no se puede volver a prestar → 409" 'es 409'
req POST /api/socios "{\"nombre\":\"Lector\",\"email\":\"lector$RND@mail.com\"}"; S2="$(nuevo_id)"
for n in 1 2 3 4; do
  req POST /api/libros "{\"titulo\":\"Libro $n\",\"autor\":\"X\",\"isbn\":\"ISBN-$n-$RND\"}"; eval "LX$n=\$(nuevo_id)"
done
req POST /api/prestamos "{\"libroId\":$LX1,\"socioId\":$S2,\"fechaDevolucion\":\"$DEV\"}"; PA="$(nuevo_id)"
req POST /api/prestamos "{\"libroId\":$LX2,\"socioId\":$S2,\"fechaDevolucion\":\"$DEV\"}"
req POST /api/prestamos "{\"libroId\":$LX3,\"socioId\":$S2,\"fechaDevolucion\":\"$DEV\"}"
req POST /api/prestamos "{\"libroId\":$LX4,\"socioId\":$S2,\"fechaDevolucion\":\"$DEV\"}"
check 6 "Un socio con 3 préstamos sin devolver no puede pedir otro → 409" 'es 409'
req PATCH "/api/prestamos/$PA/estado" '{"estado":"DEVUELTO"}'
req POST /api/prestamos "{\"libroId\":$LX4,\"socioId\":$S2,\"fechaDevolucion\":\"$DEV\"}"
check 4 "Al devolver uno, el socio puede volver a pedir → 201" 'es 201'
req POST /api/libros "{\"titulo\":\"Copia\",\"autor\":\"X\",\"isbn\":\"ISBN-C$RND\"}"
check 4 "ISBN repetido → 409" 'es 409'

grupo "F · Estados del préstamo"
req PATCH "/api/prestamos/$P1/estado" '{"estado":"VENCIDO"}'
check 4 "ACTIVO → VENCIDO → 200" 'es 200 && campo_es .estado VENCIDO'
req PATCH "/api/prestamos/$P1/estado" '{"estado":"DEVUELTO"}'
check 3 "VENCIDO → DEVUELTO → 200" 'es 200 && campo_es .estado DEVUELTO'
req PATCH "/api/prestamos/$P1/estado" '{"estado":"ACTIVO"}'
check 4 "DEVUELTO es final: DEVUELTO → ACTIVO → 409" 'es 409'
req PATCH "/api/prestamos/$P1/estado" '{}'
check 2 "PATCH sin estado → 400" 'es 400'
req PATCH /api/prestamos/999999/estado '{"estado":"DEVUELTO"}'
check 2 "PATCH de un préstamo inexistente → 404" 'es 404'

grupo "G · Consultas"
req GET "/api/socios/$S2/prestamos"
check 5 "GET /api/socios/{id}/prestamos → los 4 préstamos de ese socio" 'es 200 && largo_es 4'
req GET "/api/prestamos?estado=DEVUELTO"
check 5 "GET /api/prestamos?estado=DEVUELTO → solo devueltos" 'es 200 && largo_min 2 && todos_con .estado DEVUELTO'
