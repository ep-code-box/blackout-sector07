# 🌃 Cyberpunk DRPG: 통합 엔진 매뉴얼 (v5.0)

이 프로젝트는 **AI 시나리오 작가**, **AI 일러스트레이터**, 그리고 **게임 엔진**이 유기적으로 결합된 하이브리드 개발 환경입니다.

---

## 1. 📜 시나리오 엔진 (`core/story_engine.py`)
Gemma 3 모델(Ollama)을 사용하여 게임의 서사와 퀘스트를 창조합니다.

### 🛠️ 작동 원리
1.  `client/assets/story_queue/` 폴더를 감시합니다.
2.  아이디어가 담긴 JSON이 들어오면 현재 세계관 맥락(`data_story.lua`)을 분석하여 퀘스트를 작성합니다.
3.  결과를 게임 데이터에 주입하고, **아트 엔진**에게 보스 이미지를 그리라고 명령(토스)합니다.

### 📥 입력 형식 (`story_queue/*.json`)
```json
{
  "keyword": "하수구의 메카 수녀"
}
```

### 🚀 실행 방법
```bash
python core/story_engine.py
```

---

## 2. 🎨 아트 엔진 (`core/art_factory.py`)
Stable Diffusion과 Rembg를 사용하여 게임 에셋을 생성합니다.

### 🛠️ 핵심 기능
- **다중 모델 지원**: 큐 JSON의 `model` 필드로 지정.
- **에셋 모드(Mode)**:
    - `monster`/`npc`: 512x896, 누끼(그린스크린) 처리 + 얼굴 크롭(`_face.png`) 자동 생성.
    - `face`: 256x256, 얼굴 클로즈업 단독 생성.
    - `map`: 768x512, 1인칭 배경용.
    - `tile`/`item`/`ui`: 512x512, 정사각형.
- **원본 보관**: 배경 제거 전 원본은 `client/art/raw/`에, 최종본은 `client/assets/images/`에 저장됩니다.
- **Hot-Reload**: 실행 중 `core/factory_config.json`을 수정하면 다음 큐 처리 시 자동 반영됩니다.

### 🤖 지원 모델

| 키 | 파일 | 특징 |
|---|---|---|
| `meina` (기본값) | meinahentai_v5Final | 에치/섹시 특화 |
| `v12` | meinamix_v12Final | 범용 애니메이션 |
| `aom` | abyssorangemix3AOM3 | anatomy 안정적, 에치 |
| `aam` | aamAnyloraAnimeMix | 깔끔한 애니 스타일 |
| `lcm` | aamAnyloraAnimeMix LCM | 고속 생성 (6스텝) |
| `manga` | mangamaster_style_v5 | 만화/일러스트 스타일 |

### 📥 입력 형식 (`client/art/queue/*.json`)

단일 에셋:
```json
{
  "name": "boss_seraphina",
  "mode": "monster",
  "model": "meina",
  "prompt": "cyborg succubus, red wings, latex armor, glowing circuits"
}
```

배치 처리 (파일 하나에 여러 에셋):
```json
[
  { "name": "npc_bartender", "mode": "npc", "model": "aom", "prompt": "..." },
  { "name": "npc_hacker",    "mode": "npc", "model": "aom", "prompt": "..." }
]
```

### ✍️ 프롬프트 작성 가이드

**최종 프롬프트 구성 순서:**
```
GLOBAL_STYLE → 사용자 prompt → CHAR_STYLE(pos)
```

사용자 `prompt`가 중간에 위치하므로 **앞쪽에 쓸수록 더 강하게 반영**됩니다. 의상, 체형, 헤어, 표정 등 캐릭터 고유 특징을 구체적으로 쓸수록 좋아요.

**CHAR_STYLE에 이미 있는 것 — prompt에서 생략:**

| 항목 | 고정값 |
|---|---|
| 기본 설정 | `1girl`, `solo`, `ecchi` |
| 구도 | `full body`, `standing`, `zoom out` |
| 배경 | 크로마키 (자동 적용) |
| 품질 | `masterpiece`, `best quality` |

> ⚠️ **77토큰 제한** — CLIP 모델은 77토큰을 초과하면 뒷부분을 잘라냅니다. 사용자 prompt는 **30토큰 이내**를 권장합니다. `ashamed`, `inward toes`, `fidgeting`, `feet visible` 등 자세/감정 태그는 필요할 때 prompt에 직접 넣으세요.

**좋은 예시:**
```
powerful female boss, long silver hair, extremely tight bodysuit,
unzipped top showing cleavage, dominant smirk, glowing neon highlights
```

**img2img로 같은 캐릭터 연출 변형:**
```json
{
  "name": "seraphina_pose2",
  "mode": "monster",
  "base_image": "monster/boss_seraphina.png",
  "strength": 0.6,
  "prompt": "covering chest, looking away, embarrassed"
}
```
`strength` 낮을수록 원본 유지 (0.4~0.7 권장).

**강도 조절:**
```
(latex bodysuit:1.5), (cleavage:1.3)
```
기본값 1.0, 권장 범위 0.8~1.8.

### 🚀 실행 방법
```bash
python core/art_factory.py
```

---

## 3. 🕹️ 게임 클라이언트 (`client/`)
Love2D 기반의 1인칭 DRPG 엔진입니다.

### 🛠️ 아키텍처
- **상태 머신**: `Hub`(펍), `Explore`(탐험), `Combat`(전투) 상태가 분리되어 있습니다.
- **모듈화 UI**: 각 화면의 UI 렌더링은 `client/ui/` 폴더에 독립적으로 설계되어 있습니다.
- **i18n**: `translations.lua`를 통해 모든 텍스트를 통합 관리합니다.

### ⌨️ 조작 및 팁
- **방향키**: 메뉴 이동 및 던전 걷기.
- **Space/Enter**: 선택 및 교전.
- **R 키**: **[필살기]** 게임 도중 AI가 새로 그린 이미지를 실시간으로 불러옵니다.

### 🚀 실행 방법
```bash
love client
```

---

## 💡 개발 워크플로우 (조깅 루틴)
1. `story_queue`에 만들고 싶은 보스 아이디어를 몇 개 던져 넣는다.
2. `story_engine.py`와 `art_factory.py`를 켜둔다.
3. 조깅을 다녀온다. 🏃‍♂️
4. `love client`를 켜고 방금 만들어진 세계를 탐험한다!
