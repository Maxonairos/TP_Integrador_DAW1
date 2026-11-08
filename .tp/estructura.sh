#!/usr/bin/env bash
# Controles del repositorio (no levantan la aplicación). 10 puntos.
grupo "A · Repositorio y estructura"
JAVA="src/main/java"
check 1 "Existe un paquete controller" '[ -n "$(find $JAVA -type d -name controller 2>/dev/null)" ]'
check 1 "Existe un paquete service"    '[ -n "$(find $JAVA -type d -name service 2>/dev/null)" ]'
check 1 "Existe un paquete repository" '[ -n "$(find $JAVA -type d -name repository 2>/dev/null)" ]'
check 1 ".gitignore excluye data/ y target/" 'grep -qE "^/?data/?" .gitignore && grep -qE "^/?target/?" .gitignore'
check 1 "La base H2 (*.mv.db) no está en el repositorio" '[ -z "$(git ls-files | grep -E "\.mv\.db$|\.trace\.db$")" ]'
case "$ENUNCIADO" in biblioteca) REC=libros;; gimnasio) REC=actividades;; taller) REC=vehiculos;; canchas) REC=canchas;; eventos) REC=eventos;; esac
check 2 "README.md completado (sin los <…> de la plantilla y con la tabla de endpoints)" '[ -f README.md ] && [ "$(wc -l < README.md)" -gt 20 ] && grep -q "/api/$REC" README.md && ! grep -q "<Nombre del sistema>" README.md'
check 2 "Archivo .http (o colección Postman) con peticiones a /$REC" '[ -n "$(git ls-files | grep -iE "\.http$|postman.*\.json$")" ] && git ls-files -z | grep -zE "\.http$|postman.*\.json$" | xargs -0 grep -l "/$REC" >/dev/null 2>&1'
check 1 "Usa spring-boot-starter-validation" 'grep -q "spring-boot-starter-validation" pom.xml'

COMMITS="$(git rev-list --count HEAD 2>/dev/null || echo 0)"
DIAS="$(git log --format=%ad --date=short 2>/dev/null | sort -u | wc -l)"
echo "  ℹ Commits: $COMMITS en $DIAS días distintos"
echo "- ℹ Historial: $COMMITS commits en $DIAS días distintos (se revisa en la corrección)" >> "$TMP/detalle"
