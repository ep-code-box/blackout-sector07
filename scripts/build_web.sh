#!/bin/bash

# scripts/build_web.sh
# 패키징 및 love.js 웹 빌드를 수행합니다.

echo "🚀 웹 빌드(love.js) 프로세스 시작..."

# 1. 출력 디렉토리 준비
mkdir -p make/web_build
rm -rf make/web_build/*

# 2. 클라이언트 코드 패키징 (.love 파일 생성)
echo "📦 클라이언트 코드 패키징 중..."
cd client
zip -9 -r ../make/game.love .
cd ..

# 3. love.js 실행 (npx 사용)
echo "🌐 love.js 컴파일 중..."
# --t 지정하여 타이틀 설정, 메모리 확장(기본값보다 크게)
npx love.js make/game.love make/web_build -t "Sector 07" -m 268435456

# 4. index.html 수정 (E2E 테스트용 인자 전달 및 Console Hook 연결)
echo "🔧 E2E 테스트용 index.html 수정 중..."
# love.js 출력물인 index.html의 Module.arguments에 --e2e 인자를 추가합니다.
sed -i.bak 's/arguments: \["\.\/game.love"\]/arguments: [".\/game.love", "--e2e"]/g' make/web_build/index.html

# Module 객체에 print 함수를 명시적으로 연결하여 Playwright가 캡처할 수 있게 합니다.
sed -i.bak '/INITIAL_MEMORY:/a\
        print: (function() { return function(text) { if (arguments.length > 1) text = Array.prototype.slice.call(arguments).join(" "); console.log(text); }; })(),' make/web_build/index.html

rm -f make/web_build/index.html.bak

echo "✅ 웹 빌드 완료! (make/web_build)"
