#!/bin/bash
set -e

# scripts/release.sh
# auto → blackout-sector07 싱크 후 버전 증가 릴리즈

GAME_REPO="../blackout-sector07"
PKG_JSON="package.json"

# ─── 1. auto 레포 커밋 ────────────────────────────────────────────────────────
echo "📋 auto 레포 변경사항 커밋 중..."
git add -A
git status --short

# 현재 버전 읽기
CURRENT_VER=$(node -p "require('./$PKG_JSON').version")
echo "현재 버전: $CURRENT_VER"

# 패치 버전 증가 (1.0.0 → 1.0.1)
IFS='.' read -r MAJOR MINOR PATCH <<< "$CURRENT_VER"
NEW_VER="$MAJOR.$MINOR.$((PATCH + 1))"
echo "새 버전: $NEW_VER"

# package.json 버전 업데이트
node -e "
const fs = require('fs');
const pkg = JSON.parse(fs.readFileSync('$PKG_JSON', 'utf8'));
pkg.version = '$NEW_VER';
fs.writeFileSync('$PKG_JSON', JSON.stringify(pkg, null, 2) + '\n');
"
git add $PKG_JSON

# 변경 파일이 있으면 커밋
if ! git diff --cached --quiet; then
    git commit -m "release: v$NEW_VER"
fi

# ─── 2. 게임 레포 싱크 ────────────────────────────────────────────────────────
echo "🔄 blackout-sector07 동기화 중..."
bash scripts/sync_all.sh

# ─── 3. 게임 레포 커밋 & 푸시 ────────────────────────────────────────────────
cd "$GAME_REPO"

git add -A
if ! git diff --cached --quiet; then
    git commit -m "release: v$NEW_VER"
fi

git push origin main

# ─── 4. 기존 latest 릴리즈 삭제 ──────────────────────────────────────────────
echo "🗑  기존 latest 릴리즈 정리 중..."
gh release delete latest --yes 2>/dev/null && git push --delete origin latest 2>/dev/null || true

# ─── 5. 새 릴리즈 생성 ────────────────────────────────────────────────────────
echo "🚀 v$NEW_VER 릴리즈 생성 중..."
gh release create "v$NEW_VER" \
    --title "v$NEW_VER" \
    --notes "## v$NEW_VER

### 변경 사항
- E2E 테스트 인프라 구축 (Playwright, 30개 테스트)
- UI 모듈화 (theme_primitives, theme_layout)
- DB 모듈화 (db_seed, db_query)
- 챕터 3/4 고정 맵 추가 (Street, Nexus)
- 허브 탈출구 미니맵 마커 및 오버레이
- 챕터 스토리 연계 퀘스트 수정 (hacker_rogue, corp_enforcer_elite)
" \
    --latest

echo "✅ 릴리즈 완료: v$NEW_VER"

cd - > /dev/null
echo ""
echo "auto 레포도 푸시 중..."
cd /Users/lastep/Code/auto
git push origin main
echo "✅ 완료"
