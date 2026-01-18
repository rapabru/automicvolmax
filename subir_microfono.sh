#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Uso: subir_microfono.sh [porcentaje]

Sube el volumen del micrófono (entrada) en sistemas Linux.

Argumentos:
  porcentaje  Incremento en porcentaje (por defecto: 10%).

Ejemplos:
  ./subir_microfono.sh        # sube 10%
  ./subir_microfono.sh 5      # sube 5%
USAGE
}

increment="${1:-10}"

if [[ "${increment}" == "-h" || "${increment}" == "--help" ]]; then
  usage
  exit 0
fi

if ! [[ "${increment}" =~ ^[0-9]+$ ]]; then
  echo "Error: el porcentaje debe ser un número entero." >&2
  usage >&2
  exit 1
fi

if command -v pactl >/dev/null 2>&1; then
  # PipeWire/PulseAudio
  default_source="$(pactl info | awk -F': ' '/Default Source/ {print $2}')"
  if [[ -z "${default_source}" ]]; then
    echo "Error: no se pudo determinar la fuente de entrada por defecto." >&2
    exit 1
  fi
  pactl set-source-volume "${default_source}" "+${increment}%"
  echo "Micrófono '${default_source}' incrementado en +${increment}% (pactl)."
  exit 0
fi

if command -v amixer >/dev/null 2>&1; then
  # ALSA
  amixer -q set Capture "${increment}%+"
  echo "Micrófono incrementado en +${increment}% (amixer)."
  exit 0
fi

echo "Error: no se encontró 'pactl' ni 'amixer'." >&2
exit 1
