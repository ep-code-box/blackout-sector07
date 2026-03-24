# LÖVE2D 유용한 라이브러리 목록

> 출처: https://github.com/love2d-community/awesome-love2d
> 프로젝트에 필요할 것으로 보이는 라이브러리 위주로 정리

---

## Helpers (게임 유틸리티 묶음)

| 라이브러리 | 설명 |
|---|---|
| **batteries** | Lua 표준 라이브러리 확장 + 게임에 유용한 자료구조/알고리즘 모음 |
| **hump** | 게임스테이트, 타이머/트윈, 벡터, 클래스, 시그널, 카메라 올인원 |
| **knife** | 클래스, 상태머신, 이벤트, 엔티티, 타이머 등 마이크로모듈 모음 |
| **lume** | Lua 게임 개발용 함수 모음 (map, filter, serialize, random 등) |
| **narrator** | Ink 스크립팅 언어 파서 — 분기 스토리/대화 시스템 구현용 |
| **Love dialogue** | 커스텀 스크립트 언어 기반 대화 라이브러리 |
| **roomy** | 화면 관리 라이브러리 |
| **SceneMan** | 스택 기반 씬/게임스테이트 매니저 (여러 씬 동시 실행 가능) |
| **shack** | 화면 흔들림, 회전 등 스크린 이펙트 |

---

## Animation (애니메이션)

| 라이브러리 | 설명 |
|---|---|
| **anim8** | 스프라이트시트 기반 프레임 애니메이션 라이브러리 |
| **Peachy** | Aseprite 파일(.ase/.aseprite)을 직접 파싱해서 재생 |
| **SYSL-Text** | 태그 기반 텍스트 애니메이션 + 자동 줄바꿈 |

---

## Camera (카메라)

| 라이브러리 | 설명 |
|---|---|
| **gamera** | 심플한 카메라 시스템 |
| **hump.camera** | 윈도우 락, 부드러운 카메라 이동 보간 포함 |
| **Brady** | 패럴랙스 스크롤링 지원 카메라 |

---

## UI (인터페이스)

| 라이브러리 | 설명 |
|---|---|
| **Slab** | 즉시 모드(immediate mode) GUI 툴킷 — 빠른 디버그 UI에 유용 |
| **SUIT** | 소형 즉시 모드 GUI |
| **Helium** | 고성능 retained UI 프레임워크, 커스터마이즈 가능 |
| **NLay** | 유연한 레이아웃 라이브러리 |
| **Lovely Toasts** | 플로팅 말풍선/텍스트 토스트 알림 |
| **Slicy** | 9-slice/9-patch 이미지 라이브러리 (UI 테두리 처리) |

---

## Tweening (보간 & 타이머)

| 라이브러리 | 설명 |
|---|---|
| **Flux** | 빠르고 가벼운 트윈 라이브러리 |
| **tween.lua** | jQuery animate 스타일 트윈/이징 함수 |
| **hump.timer** | 타이머 + 트윈 통합 (딜레이, 반복, 이징) |

---

## Input (입력)

| 라이브러리 | 설명 |
|---|---|
| **baton** | 키보드/게임패드 통합 입력 라이브러리 |
| **tactile** | 심플하고 유연한 입력 라이브러리 |

---

## Math (수학)

| 라이브러리 | 설명 |
|---|---|
| **MLib** | 수학 + 도형 교차 검출 라이브러리 |
| **hump.vector** | 강력한 2D 벡터 클래스 |
| **loaded_dice** | Walker-Vose alias 방법으로 가중 랜덤 (룻 테이블에 최적) |
| **shash** | 공간 해시 — 대량 오브젝트 충돌 탐지 최적화용 |

---

## Serialization (저장)

| 라이브러리 | 설명 |
|---|---|
| **binser** | 커스터마이즈 가능한 Lua 직렬화 |
| **Ser** | 빠르고 강력한 테이블 직렬화 |
| **Lady** | Ser 기반 세이브게임 저장/불러오기 |

---

## Entity (ECS)

| 라이브러리 | 설명 |
|---|---|
| **Concord** | 기능이 풍부한 ECS 라이브러리 |
| **tiny-ecs** | 간단하고 유연한 ECS |
| **nata** | OOP/ECS 혼합 엔티티 관리 |

---

## Tools (개발 도구)

| 도구 | 설명 |
|---|---|
| **Love2D Tile Map Editor** | LÖVE2D 전용 타일맵 에디터. PNG 타일셋 로드, 레이어 배치, 충돌 마킹, 오브젝트 배치, 애니메이션 타일 지원. `map_export.lua`로 내보내고 제공되는 `map_loader.lua`로 연동. https://recks-studio.itch.io/love2d-tile-map-editor |

---

## OO (객체지향)

| 라이브러리 | 설명 |
|---|---|
| **30log** | 가벼운 OOP 프레임워크 (클래스, 믹스인) |
| **LowerClass** | MiddleClass 스타일 OOP |

## Performance (프로파일링)

| 라이브러리 | 설명 |
|---|---|
| **jprof** | LÖVE 전용 프로파일러 |
| **AppleCake** | 상세 메트릭 + 스레드 지원 프로파일러 |

## Physics (물리)

| 라이브러리 | 설명 |
|---|---|
| **slick** | bump.lua 영감받은 폴리곤 충돌 라이브러리 |

## Shaders (셰이더)

| 라이브러리 | 설명 |
|---|---|
| **LoveShaderConverter** | Shadertoy 파일을 LÖVE GLSL로 변환 |
| **ShaderScan** | 셰이더 핫 리로드 + 에러 핸들링 |
| **ngrading** | 심플 컬러 그레이딩 |

## Testing (테스트)

| 라이브러리 | 설명 |
|---|---|
| **busted** | 단위 테스트 프레임워크 |

## Utilities (유틸)

| 라이브러리 | 설명 |
|---|---|
| **nativefs** | LÖVE 샌드박스 외부 파일 읽기/쓰기 |
| **splashy** | 스플래시 스크린 구현 |

---

## 프로젝트 추천 픽

현재 게임(사이버펑크 RPG) 구조 기준으로 특히 유용할 것들:

| 우선순위 | 라이브러리 | 이유 |
|---|---|---|
| ★★★ | **Flux** ✅ 적용됨 | FXManager 트윈 (fx_manager.lua) |
| ★★★ | **shack** ✅ 적용됨 | 피격/폭발 화면 흔들림 (state_combat.lua) |
| ★★★ | **anim8** ✅ 다운로드됨 | 전투 스프라이트 애니메이션 (스프라이트시트 준비 시 적용) |
| ★★★ | **narrator** | Ink 기반 분기 스토리 → story_manager 대체/보완 가능 |
| ★★★ | **loaded_dice** | 전리품/스킬 가중 랜덤 드롭 |
| ★★☆ | **baton** | 키보드+게임패드 통합 입력 |
| ★★☆ | **Slicy** | UI 9-patch 프레임 처리 |
| ★☆☆ | **Concord / tiny-ecs** | 적 AI/전투 시스템 확장 시 |
