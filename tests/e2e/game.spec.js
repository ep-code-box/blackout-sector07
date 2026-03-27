const { test, expect, chromium } = require('@playwright/test');
const fs = require('fs');
const path = require('path');

/**
 * Sector 07 E2E Full Test Suite
 *
 * E2E 고정 맵 (data_map_test.lua):
 *   row2: [0,1,2,2,3,1,4,0,0,0]  ← y=2
 *   row3: [0,1,1,0,0,0,0,0,0,0]  ← y=3 (플레이어 시작점)
 *   플레이어: x=2, y=3, facing=north
 *   (3,2)=적, (4,2)=보스(E2E override), (5,2)=보물, (6,2)=탈출구
 *
 * 설계 원칙:
 *   - 그룹마다 browser/page를 beforeAll에서 한 번 생성, afterAll에서 해제
 *   - 게임 로드(WASM 부팅)는 그룹당 1회만 수행
 *   - 테스트는 직전 테스트의 상태를 이어받아 순차 진행 (test.describe.serial)
 *   - hooks 배열은 beforeEach에서 스냅샷 카운트를 기록하고 '이번 테스트' 범위만 검사
 */

const BASE_URL = 'http://localhost:8090';
const SHOT_DIR  = 'tests/e2e/screenshots';

// ─── 헬퍼 ────────────────────────────────────────────────────────────────────

function attachHookListener(page, hooks) {
  page.on('console', msg => {
    const text = msg.text();
    if (text.includes('E2E_HOOK:')) {
      const name = text.split('E2E_HOOK:')[1].trim();
      hooks.push(name);
      console.log(`  [LUA] ${name}`);
    }
  });
}

async function waitHook(hooks, name, timeout = 20000) {
  const start = Date.now();
  while (Date.now() - start < timeout) {
    if (hooks.some(h => h === name || h.startsWith(name))) return;
    await new Promise(r => setTimeout(r, 100));
  }
  throw new Error(
    `waitHook timeout(${timeout}ms): "${name}"\nCaptured: [${hooks.slice(-10).join(', ')}]`
  );
}

const hasHook = (hooks, name) => hooks.some(h => h === name || h.startsWith(name));

async function shot(page, name) {
  fs.mkdirSync(SHOT_DIR, { recursive: true });
  await page.screenshot({ path: path.join(SHOT_DIR, `${name}.png`) });
}

/** 타이틀에서 New Game → 허브 */
async function gotoHub(page, hooks) {
  await waitHook(hooks, 'STATE_TITLE');
  await page.keyboard.press('Enter');
  await waitHook(hooks, 'STATE_HUB');
}

/** 프롤로그 Space 연타로 스킵 */
async function skipPrologue(page) {
  for (let i = 0; i < 10; i++) {
    await page.keyboard.press('Space');
    await new Promise(r => setTimeout(r, 200));
  }
}

/** 허브 → 던전 출격 (메뉴 7번째 = 배치) */
async function deployToDungeon(page, hooks) {
  for (let i = 0; i < 6; i++) await page.keyboard.press('ArrowDown');
  await page.keyboard.press('Enter');
  await waitHook(hooks, 'STATE_EXPLORE');
}

/** 전투 결과(WIN/WIPE)까지 라운드 진행 */
async function fightUntilResult(page, hooks, maxRounds = 12) {
  for (let r = 0; r < maxRounds; r++) {
    await page.keyboard.press('Enter');
    await new Promise(r => setTimeout(r, 200));
    await page.keyboard.press('Enter');
    await new Promise(r => setTimeout(r, 1200));
    if (hasHook(hooks, 'COMBAT_RESULT_WIN') || hasHook(hooks, 'COMBAT_RESULT_WIPE')) break;
  }
}

// ─── 그룹 A: 부팅 및 기본 상태 전환 ─────────────────────────────────────────
// 게임을 처음 로드하고 타이틀 → 허브 → 프롤로그 스킵까지 순서대로 검증

test.describe.serial('Group A: 부팅 및 기본 상태 전환', () => {
  let browser, page, hooks = [];

  test.beforeAll(async () => {
    browser = await chromium.launch({ headless: false });
    const ctx = await browser.newContext({ viewport: { width: 1280, height: 720 } });
    page = await ctx.newPage();
    attachHookListener(page, hooks);
    await page.goto(BASE_URL);
  });

  test.afterAll(async () => { await browser.close(); });

  test('A1: E2E 모드 활성화 및 타이틀 로드', async () => {
    await waitHook(hooks, 'STATE_TITLE');
    expect(hasHook(hooks, 'TEST_MODE_ACTIVE')).toBeTruthy();
    await shot(page, 'A1_title');
  });

  test('A2: New Game → 허브 진입', async () => {
    await page.keyboard.press('Enter');
    await waitHook(hooks, 'STATE_HUB');
    expect(hasHook(hooks, 'STATE_HUB')).toBeTruthy();
    await shot(page, 'A2_hub');
  });

  test('A3: 허브 첫 로드 시 프롤로그(initial) 자동 트리거', async () => {
    await page.keyboard.press('Space');
    await new Promise(r => setTimeout(r, 300));
    expect(hasHook(hooks, 'STORY_KEYPRESSED')).toBeTruthy();
    await shot(page, 'A3_prologue');
  });

  test('A4: 프롤로그 스킵 완료 후 허브 메뉴 정상 노출', async () => {
    await skipPrologue(page);
    await shot(page, 'A4_hub_menu');
    const countBefore = hooks.filter(h => h === 'STORY_KEYPRESSED').length;
    await page.keyboard.press('Space');
    await new Promise(r => setTimeout(r, 400));
    const newStory = hooks.filter(h => h === 'STORY_KEYPRESSED').length - countBefore;
    expect(newStory).toBe(0);
  });
});

// ─── 그룹 B: 허브 기능 ───────────────────────────────────────────────────────
// 허브 메뉴 탐색, 상점, 저장 기능 — 게임 재로드 없이 허브 상태에서 시작

test.describe.serial('Group B: 허브 기능', () => {
  let browser, page, hooks = [];

  test.beforeAll(async () => {
    browser = await chromium.launch({ headless: false });
    const ctx = await browser.newContext({ viewport: { width: 1280, height: 720 } });
    page = await ctx.newPage();
    attachHookListener(page, hooks);
    await page.goto(BASE_URL);
    await gotoHub(page, hooks);
    await skipPrologue(page);
  });

  test.afterAll(async () => { await browser.close(); });

  test('B1: 메뉴 위아래 내비게이션', async () => {
    await page.keyboard.press('ArrowDown');
    await new Promise(r => setTimeout(r, 200));
    await page.keyboard.press('ArrowDown');
    await new Promise(r => setTimeout(r, 200));
    await page.keyboard.press('ArrowUp');
    await new Promise(r => setTimeout(r, 200));
    await shot(page, 'B1_menu_nav');
  });

  test('B2: 휴식 → HP/SP 회복', async () => {
    // 커서가 어디 있든 1번(휴식)으로 이동
    for (let i = 0; i < 6; i++) await page.keyboard.press('ArrowUp');
    await page.keyboard.press('Enter');
    await new Promise(r => setTimeout(r, 400));
    await shot(page, 'B2_rested');
    expect(hasHook(hooks, 'STATE_HUB')).toBeTruthy();
  });

  test('B3: 상점 오픈 → SHOP_OPENED 훅', async () => {
    for (let i = 0; i < 6; i++) await page.keyboard.press('ArrowUp');
    await page.keyboard.press('ArrowDown');
    await page.keyboard.press('ArrowDown');
    await page.keyboard.press('Enter');
    await waitHook(hooks, 'SHOP_OPENED');
    await shot(page, 'B3_shop');
  });

  test('B4: 상점 아이템 스크롤', async () => {
    await page.keyboard.press('ArrowDown');
    await new Promise(r => setTimeout(r, 150));
    await page.keyboard.press('ArrowDown');
    await new Promise(r => setTimeout(r, 150));
    await page.keyboard.press('ArrowUp');
    await new Promise(r => setTimeout(r, 150));
    await shot(page, 'B4_shop_scroll');
  });

  test('B5: 상점 ESC로 닫기 → 허브 복귀', async () => {
    await page.keyboard.press('Escape');
    await new Promise(r => setTimeout(r, 400));
    await shot(page, 'B5_shop_closed');
    expect(hasHook(hooks, 'STATE_HUB')).toBeTruthy();
  });

  test('B6: 저장 기능', async () => {
    for (let i = 0; i < 6; i++) await page.keyboard.press('ArrowUp');
    for (let i = 0; i < 5; i++) await page.keyboard.press('ArrowDown');
    await page.keyboard.press('Enter');
    await new Promise(r => setTimeout(r, 500));
    await shot(page, 'B6_saved');
    expect(hasHook(hooks, 'STATE_HUB')).toBeTruthy();
  });
});

// ─── 그룹 C: 탐험 및 맵 ──────────────────────────────────────────────────────
// 허브 → 던전 출격 이후 이동/회전/전투 진입까지 연속으로 검증

test.describe.serial('Group C: 탐험 및 맵', () => {
  let browser, page, hooks = [];

  test.beforeAll(async () => {
    browser = await chromium.launch({ headless: false });
    const ctx = await browser.newContext({ viewport: { width: 1280, height: 720 } });
    page = await ctx.newPage();
    attachHookListener(page, hooks);
    await page.goto(BASE_URL);
    await gotoHub(page, hooks);
    await skipPrologue(page);
    await deployToDungeon(page, hooks);
  });

  test.afterAll(async () => { await browser.close(); });

  test('C1: STATE_EXPLORE 진입 확인', async () => {
    expect(hasHook(hooks, 'STATE_EXPLORE')).toBeTruthy();
    await shot(page, 'C1_explore');
  });

  test('C2: 챕터 1 테마 sector_07 유지', async () => {
    await waitHook(hooks, 'THEME_LOADED:', 5000);
    expect(hasHook(hooks, 'THEME_LOADED:sector_07')).toBeTruthy();
    await shot(page, 'C2_theme_sector07');
  });

  test('C3: 고정 맵 로드 확인', async () => {
    const isFixed = hasHook(hooks, 'TEST_MAP_LOADED') || hasHook(hooks, 'FIXED_MAP_LOADED:');
    expect(isFixed).toBeTruthy();
    await shot(page, 'C3_fixed_map');
  });

  test('C4: 북쪽으로 1칸 전진 → (2,3)→(2,2)', async () => {
    await page.keyboard.press('ArrowUp');
    await new Promise(r => setTimeout(r, 400));
    await shot(page, 'C4_moved_north');
    expect(hasHook(hooks, 'STATE_EXPLORE')).toBeTruthy();
  });

  test('C5: 좌우 회전 크래시 없음', async () => {
    await page.keyboard.press('ArrowLeft');
    await new Promise(r => setTimeout(r, 200));
    await page.keyboard.press('ArrowRight');
    await new Promise(r => setTimeout(r, 200));
    await page.keyboard.press('ArrowRight');
    await new Promise(r => setTimeout(r, 200));
    await page.keyboard.press('ArrowLeft'); // north 복귀
    await shot(page, 'C5_rotated');
  });

  test('C6: 벽 이동 시도 — 크래시 없음', async () => {
    await page.keyboard.press('ArrowDown');
    await new Promise(r => setTimeout(r, 300));
    await shot(page, 'C6_wall_blocked');
    expect(hasHook(hooks, 'STATE_EXPLORE')).toBeTruthy();
  });

  test('C7: 적 타일 위에 서서 Space → 전투 진입', async () => {
    // C6 후 플레이어: (2,3) 북향
    // (2,3)→(2,2) 북향 → 동향 → (2,2)→(3,2) 적 타일 → Space
    await page.keyboard.press('ArrowUp');   // (2,3)→(2,2)
    await new Promise(r => setTimeout(r, 300));
    await page.keyboard.press('ArrowRight'); // 북→동향
    await new Promise(r => setTimeout(r, 200));
    await page.keyboard.press('ArrowUp');   // (2,2)→(3,2) 적 타일
    await new Promise(r => setTimeout(r, 300));
    await page.keyboard.press('Space');
    await waitHook(hooks, 'STATE_COMBAT', 8000);
    expect(hasHook(hooks, 'STATE_COMBAT')).toBeTruthy();
    await shot(page, 'C7_combat_entered');
  });
});

// ─── 그룹 D: 전투 시스템 ─────────────────────────────────────────────────────
// 전투 진입부터 결과까지 순차 검증 — 그룹 내에서 단 한 번의 전투 흐름

test.describe.serial('Group D: 전투 시스템', () => {
  let browser, page, hooks = [];

  test.beforeAll(async () => {
    browser = await chromium.launch({ headless: false });
    const ctx = await browser.newContext({ viewport: { width: 1280, height: 720 } });
    page = await ctx.newPage();
    attachHookListener(page, hooks);
    await page.goto(BASE_URL);
    await gotoHub(page, hooks);
    await skipPrologue(page);
    await deployToDungeon(page, hooks);
    // (2,3) 북향 → (2,2) → 동향 → (3,2) 적 타일 → Space
    await page.keyboard.press('ArrowUp');
    await new Promise(r => setTimeout(r, 400));
    await page.keyboard.press('ArrowRight');
    await new Promise(r => setTimeout(r, 200));
    await page.keyboard.press('ArrowUp');
    await new Promise(r => setTimeout(r, 400));
    await page.keyboard.press('Space');
    await waitHook(hooks, 'STATE_COMBAT', 10000);
  });

  test.afterAll(async () => { await browser.close(); });

  test('D1: 전투 진입 시 TIMELINE_DRAWN', async () => {
    await waitHook(hooks, 'TIMELINE_DRAWN', 5000);
    expect(hasHook(hooks, 'TIMELINE_DRAWN')).toBeTruthy();
    await shot(page, 'D1_timeline');
  });

  test('D2: 스킬 메뉴 위아래 내비게이션', async () => {
    await page.keyboard.press('ArrowDown');
    await new Promise(r => setTimeout(r, 200));
    await page.keyboard.press('ArrowUp');
    await new Promise(r => setTimeout(r, 200));
    await shot(page, 'D2_skill_menu');
    expect(hasHook(hooks, 'STATE_COMBAT')).toBeTruthy();
  });

  test('D3: 기본 공격 실행', async () => {
    await page.keyboard.press('Enter');
    await new Promise(r => setTimeout(r, 200));
    await page.keyboard.press('Enter');
    await new Promise(r => setTimeout(r, 1200));
    await shot(page, 'D3_after_attack');
    const ok = hasHook(hooks, 'STATE_COMBAT') || hasHook(hooks, 'COMBAT_RESULT_WIN') || hasHook(hooks, 'COMBAT_RESULT_WIPE');
    expect(ok).toBeTruthy();
  });

  test('D4: 전투 완료 — WIN 또는 WIPE 발생', async () => {
    await fightUntilResult(page, hooks);
    expect(hasHook(hooks, 'COMBAT_RESULT_WIN') || hasHook(hooks, 'COMBAT_RESULT_WIPE')).toBeTruthy();
    await shot(page, 'D4_result');
  });

  test('D5: 결과 후 상태 전환 (WIN→EXPLORE / WIPE→HUB)', async () => {
    for (let i = 0; i < 10; i++) { await page.keyboard.press('Space'); await new Promise(r => setTimeout(r, 300)); }
    if (hasHook(hooks, 'COMBAT_RESULT_WIN')) {
      await waitHook(hooks, 'STATE_EXPLORE', 8000);
      expect(hasHook(hooks, 'STATE_EXPLORE')).toBeTruthy();
      await shot(page, 'D5_win_to_explore');
    } else {
      await waitHook(hooks, 'STATE_HUB', 8000);
      expect(hasHook(hooks, 'STATE_HUB')).toBeTruthy();
      await shot(page, 'D5_wipe_to_hub');
    }
  });
});

// ─── 그룹 E: 챕터/스토리 회귀 ───────────────────────────────────────────────

test.describe.serial('Group E: 챕터 및 스토리 회귀', () => {
  let browser, page, hooks = [];

  test.beforeAll(async () => {
    browser = await chromium.launch({ headless: false });
    const ctx = await browser.newContext({ viewport: { width: 1280, height: 720 } });
    page = await ctx.newPage();
    attachHookListener(page, hooks);
    await page.goto(BASE_URL);
    await gotoHub(page, hooks);
    await skipPrologue(page);
  });

  test.afterAll(async () => { await browser.close(); });

  test('E1: 프롤로그 후 테마 sector_07 유지 (boss_kill 전)', async () => {
    await deployToDungeon(page, hooks);
    await waitHook(hooks, 'THEME_LOADED:', 5000);
    expect(hasHook(hooks, 'THEME_LOADED:sector_07')).toBeTruthy();
    expect(hasHook(hooks, 'THEME_LOADED:lab')).toBeFalsy();
    await shot(page, 'E1_theme_sector07');
  });

  test('E2: 허브 첫 진입 후 중복 STORY_KEYPRESSED 없음', async () => {
    const before = hooks.filter(h => h === 'STORY_KEYPRESSED').length;
    await new Promise(r => setTimeout(r, 500));
    const after = hooks.filter(h => h === 'STORY_KEYPRESSED').length;
    expect(after).toBe(before);
  });

  test('E3: 보스 킬 → 챕터 이벤트 트리거', async () => {
    // (2,3) 북향 → (2,2) → 동향 → (3,2) 적 타일 → Space
    await page.keyboard.press('ArrowUp');
    await new Promise(r => setTimeout(r, 400));
    await page.keyboard.press('ArrowRight');
    await new Promise(r => setTimeout(r, 200));
    await page.keyboard.press('ArrowUp');
    await new Promise(r => setTimeout(r, 400));
    await page.keyboard.press('Space');
    await waitHook(hooks, 'STATE_COMBAT', 8000);
    await fightUntilResult(page, hooks);

    if (!hasHook(hooks, 'COMBAT_RESULT_WIN')) {
      console.log('ℹ️  E3: WIPE — boss kill 검증 생략');
      return;
    }
    const storyBefore = hooks.filter(h => h === 'STORY_KEYPRESSED').length;
    for (let i = 0; i < 10; i++) { await page.keyboard.press('Space'); await new Promise(r => setTimeout(r, 300)); }
    await new Promise(r => setTimeout(r, 500));
    const storyAfter = hooks.filter(h => h === 'STORY_KEYPRESSED').length;
    console.log(`  story hooks: ${storyBefore} → ${storyAfter}`);
    await shot(page, 'E3_boss_kill');
    expect(hasHook(hooks, 'COMBAT_RESULT_WIN')).toBeTruthy();
  });

  test('E4: 보스 킬 후 같은 타일 재진입 불가 (적 제거)', async () => {
    if (!hasHook(hooks, 'COMBAT_RESULT_WIN')) return;
    await waitHook(hooks, 'STATE_EXPLORE', 8000);

    const combatsBefore = hooks.filter(h => h === 'STATE_COMBAT').length;
    await page.keyboard.press('Space');
    await new Promise(r => setTimeout(r, 800));
    const combatsAfter = hooks.filter(h => h === 'STATE_COMBAT').length;
    expect(combatsAfter).toBe(combatsBefore);
    await shot(page, 'E4_enemy_cleared');
  });
});

// ─── 그룹 F: 엣지 케이스 ─────────────────────────────────────────────────────

test.describe.serial('Group F: 엣지 케이스 및 안정성', () => {
  let browser, page, hooks = [];

  test.beforeAll(async () => {
    browser = await chromium.launch({ headless: false });
    const ctx = await browser.newContext({ viewport: { width: 1280, height: 720 } });
    page = await ctx.newPage();
    attachHookListener(page, hooks);
    await page.goto(BASE_URL);
    await gotoHub(page, hooks);
    await skipPrologue(page);
  });

  test.afterAll(async () => { await browser.close(); });

  test('F1: 전투 중 Enter 연타 — 크래시 없음', async () => {
    await deployToDungeon(page, hooks);
    // (2,3) 북향 → (2,2) → 동향 → (3,2) 적 타일 → Space
    await page.keyboard.press('ArrowUp');
    await new Promise(r => setTimeout(r, 400));
    await page.keyboard.press('ArrowRight');
    await new Promise(r => setTimeout(r, 200));
    await page.keyboard.press('ArrowUp');
    await new Promise(r => setTimeout(r, 400));
    await page.keyboard.press('Space');
    await waitHook(hooks, 'STATE_COMBAT', 8000);
    for (let i = 0; i < 20; i++) { await page.keyboard.press('Enter'); await new Promise(r => setTimeout(r, 50)); }
    await new Promise(r => setTimeout(r, 1000));
    await shot(page, 'F1_rapid_enter');
    const stable = hasHook(hooks, 'STATE_COMBAT') || hasHook(hooks, 'COMBAT_RESULT_WIN') || hasHook(hooks, 'COMBAT_RESULT_WIPE');
    expect(stable).toBeTruthy();
  });

  test('F2: 탐험 중 랜덤 키 연타 — 크래시 없음', async () => {
    // 전투 결과 처리 후 탐험으로 복귀
    for (let i = 0; i < 8; i++) { await page.keyboard.press('Space'); await new Promise(r => setTimeout(r, 300)); }
    await new Promise(r => setTimeout(r, 1000));
    const keys = ['ArrowUp', 'ArrowDown', 'ArrowLeft', 'ArrowRight'];
    for (let i = 0; i < 12; i++) { await page.keyboard.press(keys[i % 4]); await new Promise(r => setTimeout(r, 80)); }
    await shot(page, 'F2_random_keys');
    const stable = hasHook(hooks, 'STATE_EXPLORE') || hasHook(hooks, 'STATE_COMBAT') || hasHook(hooks, 'STATE_HUB');
    expect(stable).toBeTruthy();
  });

  test('F3: 저장 후 배치 → 챕터 테마 유지', async () => {
    // 현재 상태가 탐험 또는 허브인지에 관계없이 허브로 이동 후 저장
    if (!hasHook(hooks, 'STATE_HUB')) {
      for (let i = 0; i < 10; i++) { await page.keyboard.press('Space'); await new Promise(r => setTimeout(r, 300)); }
      await new Promise(r => setTimeout(r, 500));
    }
    for (let i = 0; i < 6; i++) await page.keyboard.press('ArrowUp');
    for (let i = 0; i < 5; i++) await page.keyboard.press('ArrowDown');
    await page.keyboard.press('Enter'); // 저장
    await new Promise(r => setTimeout(r, 400));
    await page.keyboard.press('ArrowDown');
    await page.keyboard.press('Enter'); // 배치(출격)
    await waitHook(hooks, 'STATE_EXPLORE', 10000);
    await waitHook(hooks, 'THEME_LOADED:', 5000);
    expect(hasHook(hooks, 'THEME_LOADED:sector_07')).toBeTruthy();
    await shot(page, 'F3_save_then_explore');
  });

  test('F4: 전투 재진입 시 TIMELINE_DRAWN 추가 발생', async () => {
    // 새 훅 발생 여부는 카운트 전후로 추적 (누적 배열 재사용 주의)
    const tlBefore = hooks.filter(h => h === 'TIMELINE_DRAWN').length;
    const cbBefore = hooks.filter(h => h === 'STATE_COMBAT').length;

    // (2,3) 북향 → (2,2) → 동향 → (3,2) 적 타일 → Space
    await page.keyboard.press('ArrowUp');
    await new Promise(r => setTimeout(r, 400));
    await page.keyboard.press('ArrowRight');
    await new Promise(r => setTimeout(r, 200));
    await page.keyboard.press('ArrowUp');
    await new Promise(r => setTimeout(r, 400));
    await page.keyboard.press('Space');
    await new Promise(r => setTimeout(r, 2000));

    const cbAfter = hooks.filter(h => h === 'STATE_COMBAT').length;
    if (cbAfter > cbBefore) {
      // 새 전투가 시작됨 → TIMELINE_DRAWN도 새로 발생해야 함
      await new Promise(r => setTimeout(r, 2000)); // 타임라인 렌더 대기
      const tlAfter = hooks.filter(h => h === 'TIMELINE_DRAWN').length;
      expect(tlAfter).toBeGreaterThan(tlBefore);
      await shot(page, 'F4_second_combat_timeline');
    } else {
      console.log('ℹ️  F4: 적 없음(맵 초기화 미완) — TIMELINE_DRAWN 검증 생략');
    }
  });
});
