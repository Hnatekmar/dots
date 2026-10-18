#!/bin/bash
# Generate one image with Qwen-Image-2.1-Turbo on the dev cluster (sd.cpp
# A1111 endpoint). Prints the seed and writes a PNG.
set -euo pipefail

ENDPOINT="${QWEN21_URL:-https://llm.dev-k8s.srv.hnatekmar.dev/qwen21}"
# Turbo's distilled schedule. The A1111 API has no field for sigmas, so they
# ride inside the prompt as sd_cpp_extra_args. Without them the output is mush.
TURBO_SIGMAS="1.0,0.978453,0.95418,0.926626,0.89508,0.845148,0.704534,0.414568,0.0"

OUT=""
PROMPT=""
WIDTH=1024
HEIGHT=1024
SEED=""
NEGATIVE=""

usage() {
    cat <<'EOF'
Usage: generate.sh -o OUT.png "prompt"

Options:
  -o, --out PATH      Output image path (required)
  -W, --width N       Width, divisible by 32 (default 1024)
  -H, --height N      Height, divisible by 32 (default 1024)
  -s, --seed N        Seed (default: random)
  -n, --negative TEXT Negative prompt
  -h, --help          Show this help
EOF
}

while [ $# -gt 0 ]; do
    case "$1" in
        -o|--out) OUT="${2:?--out needs a path}"; shift 2 ;;
        -W|--width) WIDTH="${2:?--width needs a number}"; shift 2 ;;
        -H|--height) HEIGHT="${2:?--height needs a number}"; shift 2 ;;
        -s|--seed) SEED="${2:?--seed needs a number}"; shift 2 ;;
        -n|--negative) NEGATIVE="${2:?--negative needs text}"; shift 2 ;;
        -h|--help) usage; exit 0 ;;
        --) shift; break ;;
        -*) echo "Unknown option: $1" >&2; usage >&2; exit 2 ;;
        *) PROMPT="$1"; shift ;;
    esac
done
[ $# -gt 0 ] && PROMPT="$*"

[ -n "$PROMPT" ] || { echo "ERROR: prompt is required" >&2; usage >&2; exit 2; }
[ -n "$OUT" ] || { echo "ERROR: --out is required" >&2; usage >&2; exit 2; }
for dim in "$WIDTH" "$HEIGHT"; do
    case "$dim" in ''|*[!0-9]*) echo "ERROR: size must be a number: $dim" >&2; exit 2 ;; esac
    [ $((dim % 32)) -eq 0 ] || { echo "ERROR: $dim is not divisible by 32" >&2; exit 2; }
done
[ -n "$SEED" ] || SEED=$(( (RANDOM * 32768 + RANDOM) % 1000000000 ))

TMP_JSON="$(mktemp)"
trap 'rm -f "$TMP_JSON"' EXIT

# Build the request body in python: JSON escaping of an arbitrary prompt in
# bash is a losing game.
PAYLOAD="$(python3 - "$PROMPT" "$NEGATIVE" "$WIDTH" "$HEIGHT" "$SEED" "$TURBO_SIGMAS" <<'PY'
import json, sys

prompt, negative, width, height, seed, sigmas = sys.argv[1:7]
sig = [float(x) for x in sigmas.split(",")]
extra = json.dumps({"sample_params": {"custom_sigmas": sig}}, separators=(",", ":"))
body = {
    "prompt": f"{prompt} <sd_cpp_extra_args>{extra}</sd_cpp_extra_args>",
    "width": int(width),
    "height": int(height),
    "steps": 8,
    "cfg_scale": 1.0,
    "sampler_name": "euler",
    "seed": int(seed),
}
if negative:
    body["negative_prompt"] = negative
print(json.dumps(body))
PY
)"

echo "==> Generating ${WIDTH}x${HEIGHT} seed=$SEED" >&2
HTTP_CODE="$(curl -sS -m 300 -o "$TMP_JSON" -w '%{http_code}' \
    "$ENDPOINT/sdapi/v1/txt2img" \
    -H 'Content-Type: application/json' \
    -d "$PAYLOAD")" || {
    echo "ERROR: cannot reach $ENDPOINT" >&2
    echo "       The qwen21 deployment scales to zero (SCALE toggle row 5)." >&2
    exit 1
}

if [ "$HTTP_CODE" != "200" ]; then
    echo "ERROR: HTTP $HTTP_CODE from $ENDPOINT" >&2
    head -c 600 "$TMP_JSON" >&2
    echo >&2
    echo "       A 502/503/504 usually means the deployment is scaled to zero." >&2
    exit 1
fi

mkdir -p "$(dirname "$OUT")"
python3 - "$TMP_JSON" "$OUT" <<'PY'
import base64, json, sys

with open(sys.argv[1]) as fh:
    images = json.load(fh).get("images") or []
if not images:
    sys.exit("ERROR: response contains no images")
blob = images[0].split(",", 1)[-1]
with open(sys.argv[2], "wb") as fh:
    fh.write(base64.b64decode(blob))
PY

echo "wrote $OUT (seed $SEED)"
