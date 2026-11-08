# TP Integrador · DAW1 — <Nombre del sistema>

**Alumno/a:** Apellido, Nombre · **Legajo:** 00000
**Enunciado elegido:** <biblioteca | gimnasio | taller | canchas | eventos>


## Descripción

<Dos o tres líneas: qué hace el sistema y para quién.>

## Cómo ejecutarlo

Requisitos: Java 21 (Maven viene incluido con `mvnw`).

```bash
./mvnw spring-boot:run
```

La API queda en `http://localhost:8080/api`. La base H2 se guarda en `data/` (no se sube al repositorio).
Consola H2: `http://localhost:8080/h2-console`.

## Modelo

| Entidad | Atributos principales | Relaciones |
|---|---|---|
| <Entidad1> | id, ... | ... |
| <Entidad2> | id, ... | ... |
| <Entidad3> | id, estado, ... | N a 1 con <Entidad1> y <Entidad2> |

Estados de <Entidad3>: `ESTADO_A → ESTADO_B | ESTADO_C`, ...

## Endpoints

| Método | Ruta | Descripción | Respuestas |
|---|---|---|---|
| GET | /api/... | Lista ... | 200 |
| GET | /api/.../{id} | Busca por id | 200, 404 |
| POST | /api/... | Crea | 201, 400, 404, 409 |
| PUT | /api/.../{id} | Modifica | 200, 400, 404, 409 |
| DELETE | /api/.../{id} | Borra | 204, 404, 409 |
| PATCH | /api/.../{id}/estado | Cambia el estado | 200, 400, 404, 409 |

## Reglas de negocio

1. <Regla 1 y qué código devuelve>
2. <Regla 2>

## Pruebas

En `pruebas.http` están todas las peticiones de ejemplo (se ejecutan desde IntelliJ).
