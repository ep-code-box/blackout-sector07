#!/bin/bash

# auto/scripts/sync_all.sh
# 팩토리 레포(auto)의 작업물을 게임 레포(blackout-sector07)로 동기화합니다.

# 1. 클라이언트 코드 및 에셋 (필수 파일만 루트로)
echo "🚀 게임 코드 및 에셋 동기화 중 (Pure Game Mode)..."
rsync -av --progress \
    --exclude='.DS_Store' \
    --exclude='game_data.db' \
    --exclude='test_runner.lua' \
    --exclude='test_assets.lua' \
    client/ ../blackout-sector07/

# 2. 테스트 및 빌드 인프라 동기화
echo "🛠 테스트 및 빌드 도구 동기화 중..."
rsync -av --progress --exclude='node_modules' --exclude='playwright-report' tests/ ../blackout-sector07/tests/
rsync -av --progress scripts/ ../blackout-sector07/scripts/
cp package.json package-lock.json playwright.config.js ../blackout-sector07/ 2>/dev/null || true

# 3. CI 설정 파일
if [ -d ".github/workflows" ]; then
    mkdir -p ../blackout-sector07/.github/workflows
    cp .github/workflows/*.yml ../blackout-sector07/.github/workflows/
fi

echo "✅ [PURE SYNC] 게임 소스 동기화가 완료되었습니다!"
