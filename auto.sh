#!/bin/bash
set -euo pipefail

#############################################
# Git 초기화 및 원격 푸시 자동화 스크립트
# - config.env 존재 시 자동 로드
# - 없으면 사용자 입력 유도
# - 루트 마커 기준 상위 디렉토리 탐색
# - .gitignore 자동 생성 없음
# - 기존 Git 저장소일 경우 종료
#############################################

# 📌 루트 마커 목록
ROOT_MARKERS=(
  ".project-root"
  "build.gradle"
  "settings.gradle"
  ".gitignore"
  "pom.xml"
)

# 🔍 루트 디렉토리 탐색
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

# 📂 루트 디렉토리 설정
if [ -z "$PROJECT_ROOT" ]; then
  echo "❌ 루트 디렉토리를 찾지 못했습니다. 현재 디렉토리에서 실행합니다."
  PROJECT_ROOT=$(pwd)
else
  echo "📂 프로젝트 루트 탐색됨: $PROJECT_ROOT"
fi

cd "$PROJECT_ROOT"

# 📄 config.env 로드 또는 수동 입력
CONFIG_FILE="./config.env"
if [ -f "$CONFIG_FILE" ]; then
  echo "📄 config.env 사용:"
  cat "$CONFIG_FILE"
  set -a; source "$CONFIG_FILE"; set +a
else
  echo "⚙️ config.env 없음 → 사용자에게 직접 입력 받습니다"
  DEFAULT_NAME=$(git config --global user.name || true)
  DEFAULT_EMAIL=$(git config --global user.email || true)

  read -rp "👤 이름 [${DEFAULT_NAME:-}]: " GIT_USER_NAME
  GIT_USER_NAME=${GIT_USER_NAME:-$DEFAULT_NAME}

  read -rp "📧 이메일 [${DEFAULT_EMAIL:-}]: " GIT_USER_EMAIL
  GIT_USER_EMAIL=${GIT_USER_EMAIL:-$DEFAULT_EMAIL}

  if [ -z "$GIT_USER_NAME" ] || [ -z "$GIT_USER_EMAIL" ]; then
    echo "❌ 이름과 이메일은 필수입니다."
    exit 1
  fi

  read -rp "🌐 리모트 URL: " GIT_REMOTE_URL
  read -rp "📝 커밋 메시지: " GIT_COMMIT_MESSAGE
  read -rp "🌿 브랜치 [main]: " GIT_DEFAULT_BRANCH
  GIT_DEFAULT_BRANCH=${GIT_DEFAULT_BRANCH:-main}
fi

# 🚫 기존 Git 저장소 여부 확인
if [ -d .git ]; then
  echo "ℹ️ 이미 Git 저장소입니다. 작업을 중단합니다."
  exit 0
fi

# 🚀 Git 초기화 및 사용자 정보 설정
git init
git config user.name "$GIT_USER_NAME"
git config user.email "$GIT_USER_EMAIL"

# 🗃️ 파일 스테이징 및 커밋
git add .
if [ -z "$GIT_COMMIT_MESSAGE" ]; then
  echo "❌ 커밋 메시지가 비어 있습니다."
  exit 1
fi
git commit -m "$GIT_COMMIT_MESSAGE"
echo "🎉 커밋 완료: $GIT_COMMIT_MESSAGE"

# 🌐 origin 설정
if ! git remote -v | grep -q origin; then
  git remote add origin "$GIT_REMOTE_URL"
  echo "✅ origin 리모트 추가 완료"
else
  echo "ℹ️ origin 리모트가 이미 존재합니다."
fi

# ☁️ 브랜치 설정 및 푸시
git branch -M "$GIT_DEFAULT_BRANCH"
echo "☁️ 리모트 브랜치로 푸시 중..."
git push -u origin "$GIT_DEFAULT_BRANCH"

echo "✅ Git 초기화 및 푸시 완료!"
