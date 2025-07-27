# auto.sh

간단한 Git 자동화 스크립트입니다.  
`config.env` 파일이 있으면 자동으로 사용하며, 없으면 사용자에게 정보를 입력받아 Git 저장소를 초기화하고 커밋 및 푸시합니다.

---

## 📦 기능

- Git 저장소 자동 초기화 (`git init`)
- 커밋 및 원격 푸시 (`git commit`, `git push`)
- `config.env` 자동 감지 및 사용
- `.git` 디렉토리 존재 시 자동 종료
- `.gitignore`나 `config.env` 파일은 생성하지 않음

---

## 📄 config.env 형식 (선택)

```env
GIT_USER_NAME="Your Name"
GIT_USER_EMAIL="you@example.com"
GIT_REMOTE_URL="https://github.com/your/repo.git"
GIT_COMMIT_MESSAGE="initial commit"
GIT_DEFAULT_BRANCH="main"
```

🛠 사용법
config.env가 없으면 필요한 정보를 직접 입력받습니다.
.git 디렉토리가 이미 있다면 작업은 즉시 종료됩니다.

```bash
wget https://raw.githubusercontent.com/Warbler14/autogit/main/auto.sh
chmod +x auto.sh
./auto.sh
rm -f auto.sh
```
