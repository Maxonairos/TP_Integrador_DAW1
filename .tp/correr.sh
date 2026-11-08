#!/usr/bin/env bash
# Corre los controles del repositorio y las pruebas de la API del enunciado elegido.
# Uso: bash .tp/correr.sh   (con la aplicación corriendo en http://localhost:8080)

cd "$(dirname "$0")/.."
source .tp/lib.sh
ENUNCIADO="$(grep -v '^#' .tp/enunciado.txt | grep -v '^[[:space:]]*$' | tail -1 | tr -d '[:space:]' | tr 'A-Z' 'a-z')"
export ENUNCIADO
case "$ENUNCIADO" in
  biblioteca|gimnasio|taller|canchas|eventos) ;;
  *) echo "❌ Elegí tu enunciado en .tp/enunciado.txt (biblioteca, gimnasio, taller, canchas o eventos)."
     echo "## ❌ Falta elegir el enunciado en .tp/enunciado.txt" >> "$RESUMEN"; exit 1 ;;
esac
echo "Enunciado: $ENUNCIADO  ·  API: $BASE"
source .tp/estructura.sh
if [ "${SOLO_ESTRUCTURA:-0}" != "1" ]; then
  source ".tp/pruebas/$ENUNCIADO.sh"
fi
finalizar
