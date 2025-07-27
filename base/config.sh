#!/bin/bash

set -e

###############################################
# Git 자동 설정 스크립트 (config.sh 생성기)
# - 사용자에게 Git 정보를 물어보고
# - 설정 파일을 현재 디렉토리에 config.sh 로 생성합니다.
###############################################

# ─────────────────────────────
# 🔧 기본값 입력 함수
# ─────────────────────────────
ask_with_default() {
  local prompt="$1"
  local default="$2"
  local input
  read -rp "$prompt [$default]: " input
  echo "${input:-$default}"
}

# ─────────────────────────────
# 🔍 Git 전역 사용자 정보 확인
# ─────────────────────────────
EXISTING_GIT_USER_NAME=$(git config --global user.name || echo "")
EXISTING_GIT_USER_EMAIL=$(git config --global user.email || echo "")

# ─────────────────────────────
# 📁 설정 파일 경로
# ─────────────────────────────
CONFIG_PATH="./config.sh"

# ─────────────────────────────
# ⚠️ 기존 설정 파일 덮어쓰기 확인
# ─────────────────────────────
if [ -f "$CONFIG_PATH" ]; then
  echo "⚠️ 이미 설정 파일이 존재합니다: $CONFIG_PATH"
  read -rp "덮어쓰시겠습니까? (y/N): " confirm
  if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
    echo "🚫 설정 생성을 취소합니다."
    exit 0
  fi
fi

echo ""
echo "🛠️ Git 정보 설정을 시작합니다. 값을 입력하거나 Enter를 눌러 기본값을 사용하세요."
echo ""

# ─────────────────────────────
# 👤 Git 사용자 이름 설정
# ─────────────────────────────
if [ -n "$EXISTING_GIT_USER_NAME" ]; then
  echo "👤 Git 전역 사용자 이름이 감지되었습니다: $EXISTING_GIT_USER_NAME"
  read -rp "이 값을 그대로 사용할까요? (Y/n): " use
  [[ "$use" =~ ^[Nn]$ ]] && \
    GIT_USER_NAME=$(ask_with_default "→ 사용자 이름 입력" "") || \
    GIT_USER_NAME="$EXISTING_GIT_USER_NAME"
else
  GIT_USER_NAME=$(ask_with_default "👤 Git 사용자 이름 입력" "")
fi

# ─────────────────────────────
# 📧 Git 사용자 이메일 설정
# ─────────────────────────────
if [ -n "$EXISTING_GIT_USER_EMAIL" ]; then
  echo "📧 Git 전역 사용자 이메일이 감지되었습니다: $EXISTING_GIT_USER_EMAIL"
  read -rp "이 값을 그대로 사용할까요? (Y/n): " use
  [[ "$use" =~ ^[Nn]$ ]] && \
    GIT_USER_EMAIL=$(ask_with_default "→ 사용자 이메일 입력" "") || \
    GIT_USER_EMAIL="$EXISTING_GIT_USER_EMAIL"
else
  GIT_USER_EMAIL=$(ask_with_default "📧 Git 사용자 이메일 입력" "")
fi

# ─────────────────────────────
# 🌐 원격 저장소 및 브랜치/커밋 설정
# ─────────────────────────────
GIT_REMOTE_URL=$(ask_with_default "🌐 Git 원격 저장소 URL (예: https://gitlab.com/사용자/저장소.git)" "$GIT_REMOTE_URL")
GIT_DEFAULT_BRANCH=$(ask_with_default "🌿 기본 브랜치 이름 (예: main, trunk)" "${GIT_DEFAULT_BRANCH:-main}")
GIT_COMMIT_MESSAGE=$(ask_with_default "📝 첫 커밋 메시지" "${GIT_COMMIT_MESSAGE:-First commit}")

# ─────────────────────────────
# 🧾 설정 파일 생성 (config.sh 형식)
# ─────────────────────────────
cat <<EOF > "$CONFIG_PATH"
#!/bin/bash
# Git 설정 정보 (자동 생성)

export GIT_USER_NAME="$GIT_USER_NAME"
export GIT_USER_EMAIL="$GIT_USER_EMAIL"
export GIT_REMOTE_URL="$GIT_REMOTE_URL"
export GIT_DEFAULT_BRANCH="$GIT_DEFAULT_BRANCH"
export GIT_COMMIT_MESSAGE="$GIT_COMMIT_MESSAGE"
EOF

chmod +x "$CONFIG_PATH"

# ─────────────────────────────
# ✅ 완료 안내
# ─────────────────────────────
echo ""
echo "✅ 설정이 완료되었습니다! 아래 파일이 생성되었습니다:"
echo "📄 $CONFIG_PATH"
echo ""
cat "$CONFIG_PATH"
