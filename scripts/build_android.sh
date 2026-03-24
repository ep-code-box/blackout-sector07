#!/bin/bash

# 안드로이드 빌드 자동화 스크립트 (Love2D 11.5)
BUILD_DIR="make/android_build"
LOVE_ANDROID_REPO="https://github.com/love2d/love-android.git"
GAME_LOVE="make/build/sector07.love"

echo "🚀 Starting Android Build Process..."

# JDK 17 강제 설정 로직 (Homebrew 및 시스템 경로 체크)
if [ -d "/opt/homebrew/opt/openjdk@17" ]; then
    export JAVA_HOME="/opt/homebrew/opt/openjdk@17"
    export PATH="$JAVA_HOME/bin:$PATH"
    echo "☕ Using Homebrew OpenJDK 17: $JAVA_HOME"
elif [ -d "/usr/local/opt/openjdk@17" ]; then
    export JAVA_HOME="/usr/local/opt/openjdk@17"
    export PATH="$JAVA_HOME/bin:$PATH"
    echo "☕ Using Homebrew OpenJDK 17 (Intel): $JAVA_HOME"
elif /usr/libexec/java_home -v 17 >/dev/null 2>&1; then
    export JAVA_HOME=$(/usr/libexec/java_home -v 17)
    echo "☕ Using System JDK 17: $JAVA_HOME"
else
    echo "⚠️  JDK 17 not found. Trying with default Java."
fi

# 1. .love 파일 생성 확인
if [ ! -f "$GAME_LOVE" ]; then
    echo "📦 Packaging game sources..."
    python3 scripts/package_love.py
fi

# 2. 빌드 저장소 준비
if [ ! -d "$BUILD_DIR" ]; then
    echo "📂 Cloning love-android repository..."
    git clone "$LOVE_ANDROID_REPO" "$BUILD_DIR"
    cd "$BUILD_DIR"
    git checkout 11.5
    git submodule update --init --recursive
    cd ..
else
    echo "✅ Build directory already exists. Ensuring submodules are up to date..."
    cd "$BUILD_DIR"
    git checkout 11.5
    git submodule update --init --recursive
    cd ..
fi

# 3. 게임 소스 이식
echo "🔧 Embedding $GAME_LOVE..."
mkdir -p "$BUILD_DIR/app/src/embed/assets/"
cp "$GAME_LOVE" "$BUILD_DIR/app/src/embed/assets/game.love"

# 4. 빌드 실행
echo "🏗️ Running Gradle build..."
cd "$BUILD_DIR"
chmod +x gradlew
# 임베드 모드로 디버그 APK 생성 (태스크명 수정: RecordDebug)
./gradlew assembleEmbedNoRecordDebug

if [ $? -eq 0 ]; then
    echo "------------------------------------------------"
    echo "✨ APK Build Complete!"
    echo "📍 Path: $BUILD_DIR/app/build/outputs/apk/embedNoRecord/debug/app-embed-noRecord-debug.apk"
    echo "------------------------------------------------"
else
    echo "❌ Build failed. Ensure JDK 17 and Android SDK are configured."
fi
