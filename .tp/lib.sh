#!/usr/bin/env bash
# Funciones comunes de las pruebas del TP. No modificar.
BASE="${BASE_URL:-http://localhost:8080}"
STATUS="-"; BODY=""; LOCATION=""; CTYPE=""
PUNTOS=0; MAXIMO=0; GRUPO=""; GRUPO_P=0; GRUPO_M=0
RESUMEN="${GITHUB_STEP_SUMMARY:-/dev/null}"
TMP="$(mktemp -d)"
OK="✅"; NO="❌"

# req MÉTODO RUTA [JSON]  → deja STATUS, BODY y LOCATION
req() {
  local metodo="$1" ruta="$2" datos="${3:-}"
  local args=(-s -o "$TMP/body" -D "$TMP/headers" -w '%{http_code}' -X "$metodo" "$BASE$ruta" --max-time 15)
  if [ -n "$datos" ]; then args+=(-H 'Content-Type: application/json' --data "$datos"); fi
  rm -f "$TMP/body" "$TMP/headers"
  STATUS="$(curl "${args[@]}" 2>/dev/null)"; STATUS="${STATUS:0:3}"; [ -z "$STATUS" ] && STATUS=000
  BODY="$(cat "$TMP/body" 2>/dev/null)"
  LOCATION="$(grep -i '^location:' "$TMP/headers" 2>/dev/null | head -1 | cut -d' ' -f2- | tr -d '\r')"
  CTYPE="$(grep -i '^content-type:' "$TMP/headers" 2>/dev/null | head -1 | cut -d' ' -f2- | tr -d '\r')"
}

# json '.campo'  → valor del cuerpo de la última respuesta ("" si no hay)
json() { echo "$BODY" | jq -r "$1 // empty" 2>/dev/null; }

# id de lo que se acaba de crear
nuevo_id() { json '.id'; }

grupo() {
  cerrar_grupo
  GRUPO="$1"; GRUPO_P=0; GRUPO_M=0
  echo ""; echo "== $GRUPO"
}
cerrar_grupo() {
  if [ -n "$GRUPO" ]; then
    echo "| $GRUPO | $GRUPO_P / $GRUPO_M |" >> "$TMP/tabla"
  fi
}

# check PUNTOS "descripción" 'condición'   (la condición se evalúa como código bash)
check() {
  local pts="$1" desc="$2" cond="$3"
  MAXIMO=$((MAXIMO + pts)); GRUPO_M=$((GRUPO_M + pts))
  if eval "$cond" >/dev/null 2>&1; then
    PUNTOS=$((PUNTOS + pts)); GRUPO_P=$((GRUPO_P + pts))
    echo "  $OK [$pts] $desc"
    echo "- $OK $desc" >> "$TMP/detalle"
  else
    local extra=""; [ "$STATUS" != "-" ] && extra=" — se obtuvo HTTP $STATUS"
    echo "  $NO [0/$pts] $desc$extra"
    echo "- $NO $desc$extra" >> "$TMP/detalle"
  fi
}

# Atajos de condiciones
es() { [ "$STATUS" = "$1" ]; }
es_json_problem() { echo "$BODY" | jq -e '.status and (.title or .detail)' ; }
tiene_error_en() { echo "$BODY" | jq -e --arg c "$1" '.errores[$c] != null' ; }
es_array() { echo "$BODY" | jq -e 'type == "array"' ; }
largo_es() { [ "$(echo "$BODY" | jq 'length' 2>/dev/null)" = "$1" ]; }
largo_min() { [ "$(echo "$BODY" | jq 'length' 2>/dev/null || echo 0)" -ge "$1" ]; }
numero_es() { echo "$BODY" | jq -e --argjson n "$2" "($1 | tonumber) == \$n"; }
todos_empiezan() { echo "$BODY" | jq -e --arg v "$2" "all(.[]; ($1 | tostring) | startswith(\$v))"; }
todos_contienen() { echo "$BODY" | jq -e --arg v "$2" "all(.[]; ($1 | ascii_downcase) | contains(\$v | ascii_downcase))"; }
# sufijo aleatorio para datos únicos
RND="$(( (RANDOM % 900) + 100 ))"
campo_es() { [ "$(json "$1")" = "$2" ]; }
location_ok() { [ -n "$LOCATION" ] && echo "$LOCATION" | grep -q "$1"; }
todos_con() { echo "$BODY" | jq -e --arg v "$2" "all(.[]; $1 == \$v)"; }

# Fechas relativas (formato ISO que espera Spring)
fecha_hora() { date -d "$1" '+%Y-%m-%dT%H:%M:%S'; }      # fecha_hora '+10 days 10:00'
fecha()      { date -d "$1" '+%Y-%m-%d'; }

finalizar() {
  cerrar_grupo
  echo ""; echo "PUNTAJE AUTOMÁTICO: $PUNTOS / $MAXIMO"
  {
    echo "## Pruebas de la API — enunciado: ${ENUNCIADO:-?}"
    echo ""; echo "**Puntaje: $PUNTOS / $MAXIMO**"; echo ""
    echo "| Grupo | Puntos |"; echo "| :--- | :--- |"
    cat "$TMP/tabla" 2>/dev/null
    echo ""; echo "<details><summary>Detalle de cada prueba</summary>"; echo ""
    cat "$TMP/detalle" 2>/dev/null
    echo ""; echo "</details>"
  } >> "$RESUMEN"
  echo "$PUNTOS/$MAXIMO" > "${PUNTAJE_FILE:-/dev/null}"
}
