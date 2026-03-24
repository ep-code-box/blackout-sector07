#!/bin/bash

# auto/scripts/sync_assets.sh
# 팩토리에서 생성된 에셋을 게임 레포지토리(blackout-sector07)로 동기화합니다.

SOURCE_DIR="client/assets/images"
TARGET_DIR="../blackout-sector07/assets/images"

if [ ! -d "$TARGET_DIR" ]; then
    echo "❌ 대상 디렉토리를 찾을 수 없습니다: $TARGET_DIR"
    exit 1
fi

echo "🔄 에셋 동기화 중: $SOURCE_DIR -> $TARGET_DIR"

# rsync를 사용하여 변경된 파일만 효율적으로 복사
rsync -av --progress "$SOURCE_DIR/" "$TARGET_DIR/"

echo "✅ 동기화 완료!"
