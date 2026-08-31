#!/usr/bin/env bash
# Convierte el resumen ejecutivo Markdown a PDF.
# Uso: ./scripts/05_generate_pdf.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
INPUT="$PROJECT_DIR/data/resumen_ejecutivo.md"
OUTPUT="$PROJECT_DIR/data/resumen_ejecutivo.pdf"
CSS="$SCRIPT_DIR/pdf.css"

command -v pandoc >/dev/null 2>&1 || {
  echo "Error: pandoc no está instalado." >&2
  exit 1
}
command -v wkhtmltopdf >/dev/null 2>&1 || {
  echo "Error: wkhtmltopdf no está instalado." >&2
  exit 1
}

TEMP_HTML="$(mktemp --tmpdir pui-resumen-XXXXXX.html)"
trap 'rm -f "$TEMP_HTML"' EXIT

pandoc "$INPUT" \
  --standalone \
  --css="$CSS" \
  -t html5 \
  -o "$TEMP_HTML" \
  -V lang=es \
  --metadata title="Resumen Ejecutivo PUI"

wkhtmltopdf \
  --enable-local-file-access \
  --orientation Landscape \
  --page-size A3 \
  --margin-top 10mm \
  --margin-right 8mm \
  --margin-bottom 10mm \
  --margin-left 8mm \
  --zoom 0.9 \
  "$TEMP_HTML" "$OUTPUT"

echo "PDF generado: $OUTPUT"
