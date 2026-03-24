# 🌃 Cyberpunk DRPG Project

본 프로젝트는 **사이버펑크 테마의 1인칭 던전 크롤러(DRPG)** 개발을 위한 고성능 아트 생성 파이프라인과 게임 엔진 프로토타입을 통합한 환경입니다.

---

## 📂 프로젝트 구조 (Project Layout)

- **`client/art/`**: 이미지 리소스 및 생성 큐 관리
  - `queue/`: 생성할 에셋의 JSON 설정을 넣는 곳 (몬스터, 맵, NPC)
  - `raw/`: AI가 생성한 원본 이미지 (배경 제거 전)
  - `archive/`: 생성이 완료된 설정 파일들이 보관되는 곳
- **`client/assets/images/`**: 게임에서 실제로 사용하는 가공된 이미지들
- **`client/`**: Love2D (Lua) 기반 게임 클라이언트 엔진
- **`core/`**: 프로젝트의 심장 (아트 생성 엔진 `art_factory.py`)
- **`models/`**: AI 모델 파일 (.safetensors) 보관 폴더

---

## 🤖 필수 AI 모델 다운로드 (Model Download Guide)

아트 팩토리(`art_factory.py`)를 가동하기 위해 아래 모델들을 다운로드하여 `models/` 폴더에 넣어야 합니다.

### 1. 메인 체크포인트 (Checkpoints)
| 모델명 | 파일명 (권장) | 용도 | 다운로드 링크 |
| :--- | :--- | :--- | :--- |
| **MeinaHentai V5** | `meinahentai_v5Final.safetensors` | 기본 캐릭터 및 몬스터 | [Civitai](https://civitai.com/models/12606) |
| **MeinaMix V12** | `meinamix_v12Final.safetensors` | 범용 애니메이션 스타일 | [Civitai](https://civitai.com/models/7240) |
| **AOM3** | `abyssorangemix3AOM3_aom3a1b.safetensors` | 배경 및 고퀄리티 일러스트 | [HuggingFace](https://huggingface.co/WarriorMama777/OrangeMixs) |
| **AnyLora Mix** | `aamAnyloraAnimeMixAnime_v1.safetensors` | 가벼운 고속 생성 | [Civitai](https://civitai.com/models/23900) |
| **Manga Master** | `mangamaster_style_v5_illustrious...` | SDXL 기반 고해상도 (선택) | [Civitai](https://civitai.com/models/134081) |

### 2. 필수 VAE (Variational AutoEncoder)
색감이 빠지는 현상을 방지하기 위해 반드시 필요합니다.
*   **VAE**: `vaeFtMse840000EmaPruned_vaeFtMse840k.safetensors`
*   **다운로드**: [HuggingFace (stabilityai)](https://huggingface.co/stabilityai/sd-vae-ft-mse-original/tree/main)

---

## 🎨 아트 파이프라인 (Art Pipeline)

### 1. 에셋 생성 방법
`client/art/queue/` 폴더에 `.json` 파일을 생성하여 넣으면 AI가 자동으로 감지해 이미지를 만듭니다.

**예시 (client/art/queue/cyber_boss.json):**
```json
{
  "name": "cyber_boss",
  "mode": "monster",
  "prompt": "heavy armored cyborg samurai, plasma sword, red neon eyes, sparks flying"
}
```

### 2. 지원 모드 (Modes)
- **`monster`**: 기괴하고 멋진 괴물/메카닉 (얼굴 크롭 지원)
- **`map`**: 1인칭 던전 배경 (1280x720 와이드 최적화)
- **`npc`**: 사이버펑크 스타일 캐릭터 (사람 위주, 얼굴 크롭 지원)
- **`ui`**: 인터페이스 요소 (배경 제거 지원)

---

## 🚀 실행 방법 (Quick Start)

### 1. 아트 엔진 실행 (이미지 자동 생성기)
```bash
source venv/bin/activate
cd core
python art_factory.py
```

### 2. 게임 클라이언트 실행
```bash
love client
```

---

## 🛠️ 기술적 특징 (Technical Details)
- **Resolution**: **1280x720 HD Widescreen** 완전 대응.
- **Engine**: LÖVE (Lua) 기반 객체 지향형 아키텍처.
- **System**: SQLite3 데이터베이스 연동으로 수만 개의 데이터 관리 가능.
- **Narrative**: 분기형 스토리 엔진(Narrative Fate Engine) 탑재.
