#!/bin/bash
set -euo pipefail

# 현재 실행 중인 스크립트의 실제 경로 (symlink 포함 처리)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ─────────────────────────────
# 🔧 인자 처리: -s [CONFIG_DIR]
# ─────────────────────────────
SILENT_MODE=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    -s|--silent)
      SILENT_MODE=1
      shift
      ;;
    *)
      shift
      ;;
  esac
done

# ─────────────────────────────
# 📌 루트 마커 목록
# ─────────────────────────────
ROOT_MARKERS=(
  ".project-root"
  "build.gradle"
  "settings.gradle"
  ".gitignore"
  "pom.xml"
)

# ─────────────────────────────
# 📌 사용자 입력 함수: y/n/x (bash 3.x 호환)
# ─────────────────────────────
confirm_git_init() {
  while true; do
    read -rp "✅ 이 디렉토리에서 Git 초기화를 진행할까요? (Y/n/x): " confirm
    confirm=$(echo "${confirm:-y}" | tr '[:upper:]' '[:lower:]')
    case "$confirm" in
      y) break ;;
      n) read -rp "📂 수동으로 루트 디렉토리를 입력하세요: " PROJECT_ROOT; break ;;
      x) echo "❌ 사용자가 작업을 취소했습니다."; exit 1 ;;
      *) echo "⚠️ 잘못된 입력입니다. [Y/n/x] 중 하나를 입력하세요." ;;
    esac
  done
}

# ─────────────────────────────
# 🔍 루트 디렉토리 탐색
# ─────────────────────────────
CURRENT_DIR=$(pwd)
PROJECT_ROOT=""

while [ "$CURRENT_DIR" != "/" ]; do
  for marker in "${ROOT_MARKERS[@]}"; do
    if [ -e "$CURRENT_DIR/$marker" ]; then
      PROJECT_ROOT="$CURRENT_DIR"
      break 2
    fi
  done
  CURRENT_DIR=$(dirname "$CURRENT_DIR")
done

# ─────────────────────────────
# 📂 루트 디렉토리 확인
# ─────────────────────────────
if [ "$SILENT_MODE" -eq 1 ]; then
  if [ -z "$PROJECT_ROOT" ]; then
    echo "❌ Silent 모드에서는 루트 디렉토리 자동 탐색 실패 시 중단됩니다."
    exit 1
  fi
  echo "🔍 [Silent] 탐색된 루트 디렉토리: $PROJECT_ROOT"
else
  if [ -z "$PROJECT_ROOT" ]; then
    echo "❌ 루트 마커 파일이 탐색되지 않았습니다."
    read -rp "📂 수동으로 루트 디렉토리를 입력하세요: " PROJECT_ROOT
  else
    echo "🔍 탐색된 루트 디렉토리: $PROJECT_ROOT"
    confirm_git_init
  fi
fi

# ─────────────────────────────
# 📌 디렉토리 이동
# ─────────────────────────────
cd "$PROJECT_ROOT" || { echo "❌ 디렉토리 접근 실패: $PROJECT_ROOT"; exit 1; }
echo "📌 Git 작업 디렉토리: $(pwd)"

# ─────────────────────────────
# 📄 config.env 로드 (항상 현재 디렉토리 기준)
# ─────────────────────────────
CONFIG_FILE="./config.env"

if [ -f "$CONFIG_FILE" ]; then
  echo "📄 config.env 파일을 로드합니다..."
  set -a
  source "$CONFIG_FILE"
  set +a

  REQUIRED_VARS=(
    "GIT_USER_NAME"
    "GIT_USER_EMAIL"
    "GIT_REMOTE_URL"
    "GIT_COMMIT_MESSAGE"
    "GIT_DEFAULT_BRANCH"
  )

  MISSING_VARS=()
  for var in "${REQUIRED_VARS[@]}"; do
    if [ -z "${!var:-}" ]; then
      MISSING_VARS+=("$var")
    fi
  done

  if [ "${#MISSING_VARS[@]}" -gt 0 ]; then
    echo "❌ 다음 필수 환경 변수가 설정되지 않았습니다:"
    for v in "${MISSING_VARS[@]}"; do
      echo "   - $v"
    done
    echo "📄 $CONFIG_FILE 를 확인하거나 config.sh를 다시 실행하세요."
    exit 1
  fi
else
  echo "⚠️ config.env 파일이 현재 디렉토리에 없습니다: $CONFIG_FILE"
  exit 1
fi

# ─────────────────────────────
# ⚠️ 기존 Git 여부 확인
# ─────────────────────────────
if [ -d ".git" ]; then
  echo "⚠️ 이미 Git 저장소입니다. 작업을 중단합니다."
  exit 1
fi

# ─────────────────────────────
# 🚀 Git 초기화
# ─────────────────────────────
git init
echo "✅ Git 저장소 초기화 완료!"

# ─────────────────────────────
# 👤 사용자 정보 설정
# ─────────────────────────────
if ! git config --global user.name >/dev/null 2>&1; then
  git config --global user.name "${GIT_USER_NAME:-}"
fi

if ! git config --global user.email >/dev/null 2>&1; then
  git config --global user.email "${GIT_USER_EMAIL:-}"
fi

# ─────────────────────────────
# 🗃️ 커밋
# ─────────────────────────────
git add .

if [ -z "$GIT_COMMIT_MESSAGE" ]; then
  echo "❌ 커밋 메시지가 비어 있습니다."
  exit 1
else
  git commit -m "$GIT_COMMIT_MESSAGE"
  echo "🎉 커밋 완료: $GIT_COMMIT_MESSAGE"
fi

# ─────────────────────────────
# 🌐 리모트 설정
# ─────────────────────────────
if ! git remote -v | grep -q origin; then
  git remote add origin "$GIT_REMOTE_URL"
  echo "✅ 리모트 origin 추가: $GIT_REMOTE_URL"
else
  echo "ℹ️ 이미 origin 리모트가 존재합니다:"
  git remote -v
fi

# ─────────────────────────────
# ☁️ 브랜치 및 푸시
# ─────────────────────────────
git branch -M "$GIT_DEFAULT_BRANCH"
echo "☁️ 리모트로 푸시 중..."
git push -u origin "$GIT_DEFAULT_BRANCH"

echo "🚀 Git 초기화 및 푸시 완료!"
