#!/usr/bin/env bash
set -euo pipefail

UPSTREAM="https://github.com/seatsurfing/seatsurfing.git"
PINNED_TAG="v1.99.2"
PATCHES_DIR="$(cd "$(dirname "$0")" && pwd)"

usage() {
  echo "Usage: $(basename "$0") [-c] [-m <manifest>] [-e <environment>] [-t <tag>] [-o <output-dir>]"
  echo ""
  echo "  -c               Check mode: apply patches in a temporary checkout and remove it afterwards"
  echo "  -m <manifest>    Simple key=value manifest with environment tags"
  echo "  -e <environment>  Manifest environment to use (default: development)"
  echo "  -t <tag>         Upstream tag to clone (overrides manifest and default)"
  echo "  -o <output-dir>  Directory to clone into (default: ./seatsurfing-<tag>-patched)"
  echo "  -h               Show this help"
  exit 1
}

TAG="$PINNED_TAG"
MANIFEST=""
ENVIRONMENT="development"
OUTPUT_DIR=""
TAG_EXPLICIT=false
CHECK_MODE=false

while getopts "cm:e:t:o:h" opt; do
  case $opt in
    c) CHECK_MODE=true ;;
    m) MANIFEST="$OPTARG" ;;
    e) ENVIRONMENT="$OPTARG" ;;
    t) TAG="$OPTARG" ; TAG_EXPLICIT=true ;;
    o) OUTPUT_DIR="$OPTARG" ;;
    h) usage ;;
    *) usage ;;
  esac
done

if [[ -n "$MANIFEST" && "$TAG_EXPLICIT" == false ]]; then
  if [[ ! -f "$MANIFEST" ]]; then
    echo "Error: manifest '${MANIFEST}' does not exist."
    exit 1
  fi

  manifest_tag="$(awk -F= -v env="$ENVIRONMENT" '
    BEGIN { found = 0 }
    /^[[:space:]]*#/ { next }
    /^[[:space:]]*$/ { next }
    {
      key = $1
      gsub(/^[[:space:]]+|[[:space:]]+$/, "", key)
      value = substr($0, index($0, "=") + 1)
      gsub(/^[[:space:]]+|[[:space:]]+$/, "", value)
      if (key == env) {
        print value
        found = 1
        exit
      }
    }
    END { if (!found) exit 1 }
  ' "$MANIFEST")"

  if [[ -z "$manifest_tag" ]]; then
    echo "Error: environment '${ENVIRONMENT}' was not found in manifest '${MANIFEST}'."
    exit 1
  fi

  TAG="$manifest_tag"
fi

TEMP_DEST=""
if [[ "$CHECK_MODE" == true && -z "$OUTPUT_DIR" ]]; then
  TEMP_DEST="$(mktemp -d "${TMPDIR:-/tmp}/seatsurfing-patch-check.XXXXXX")"
  DEST="${TEMP_DEST}/seatsurfing-${TAG}-patched"
  cleanup() {
    rm -rf "$TEMP_DEST"
  }
  trap cleanup EXIT
elif [[ -n "$OUTPUT_DIR" ]]; then
  DEST="$OUTPUT_DIR"
else
  DEST="$(pwd)/seatsurfing-${TAG}-patched"
fi

if [[ -d "$DEST" ]]; then
  echo "Error: destination '${DEST}' already exists. Remove it or choose a different output directory."
  exit 1
fi

mkdir -p "$(dirname "$DEST")"

echo "Cloning seatsurfing ${TAG}..."
git clone --branch "${TAG}" "${UPSTREAM}" "${DEST}"

cd "${DEST}"
if [[ "$CHECK_MODE" == true ]]; then
  git config user.name "Seatsurfing Patch CI"
  git config user.email "seatsurfing-patch-ci@users.noreply.github.com"
fi

apply_dir() {
  local section="$1"
  local dir="${PATCHES_DIR}/${section}"
  if [[ ! -d "$dir" ]]; then
    echo "No patches found for section: ${section}"
    return
  fi
  local patches=("$dir"/*.patch)
  if [[ ! -e "${patches[0]}" ]]; then
    echo "No patches found in ${dir}"
    return
  fi
  echo ""
  echo "Applying ${section} patches..."
  for patch in "${patches[@]}"; do
    echo "  $(basename "$patch")"
    if ! git am --3way --whitespace=fix "$patch"; then
      echo "Error: failed to apply $(basename "$patch")."
      echo "Resolve the conflict, then run 'git am --continue' in this checkout or regenerate the patch against ${TAG}."
      exit 1
    fi
  done
}

apply_dir server
apply_dir ui

echo ""
echo "Rebuilding and committing translations from i18n patches..."
python3 "${PATCHES_DIR}/rebuild-translations.py" "${DEST}" "${PATCHES_DIR}"

echo ""
echo "Done. Patched environment ready at: ${DEST}"
if [[ -n "$MANIFEST" ]]; then
  echo "Manifest: ${MANIFEST} (${ENVIRONMENT})"
fi
echo "Upstream tag: ${TAG}"
if [[ "$CHECK_MODE" == true ]]; then
  echo "Patch check passed."
fi
