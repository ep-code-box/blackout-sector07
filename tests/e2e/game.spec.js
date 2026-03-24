const { test, expect } = require('@playwright/test');
const fs = require('fs');
const path = require('path');

/**
 * Sector 07 E2E 시나리오 기반 테스트 (스크린샷 포함)
 */
test.describe('Sector 07 E2E Scenarios with Visual Check', () => {
  let hooks = [];
  const screenshotDir = 'tests/e2e/screenshots';

  test.beforeAll(async () => {
    if (!fs.existsSync(screenshotDir)) {
      fs.mkdirSync(screenshotDir, { recursive: true });
    }
  });

  test.beforeEach(async ({ page }) => {
    hooks = [];
    page.on('console', msg => {
      const text = msg.text();
      if (text.includes('E2E_HOOK:')) {
        const hookName = text.split('E2E_HOOK:')[1].trim();
        hooks.push(hookName);
        console.log(`[LUA] ${hookName}`);
      }
    });
    await page.goto('http://localhost:8080');
  });

  const waitForHook = async (page, hookName, timeout = 10000) => {
    const start = Date.now();
    while (Date.now() - start < timeout) {
      if (hooks.includes(hookName)) return true;
      await page.waitForTimeout(200);
    }
    throw new Error(`Timeout waiting for hook: ${hookName}. Captured: ${hooks.join(', ')}`);
  };

  const takeShot = async (page, name) => {
    const filePath = path.join(screenshotDir, `${name}.png`);
    await page.screenshot({ path: filePath });
    console.log(`📸 Screenshot saved: ${filePath}`);
  };

  // --- 시나리오 1: 프롤로그 및 허브 진입 ---
  test('Scenario 1: Prologue and Hub Initialization', async ({ page }) => {
    await waitForHook(page, 'STATE_TITLE');
    await takeShot(page, '01_title_screen');
    
    await page.keyboard.press('Enter'); // New Game
    await waitForHook(page, 'STATE_HUB');
    
    await takeShot(page, '02_prologue_start');
    
    console.log('Skipping prologue...');
    for (let i = 0; i < 5; i++) {
      await page.keyboard.press('Space');
      await page.waitForTimeout(300);
    }
    
    await takeShot(page, '03_hub_main');
    expect(hooks.includes('STATE_HUB')).toBeTruthy();
  });

  // --- 시나리오 2: 고정 맵 탐험 및 확정 전투 승리 ---
  test('Scenario 2: Fixed Map Combat and Recruitment', async ({ page }) => {
    await waitForHook(page, 'STATE_TITLE');
    await page.keyboard.press('Enter');
    await waitForHook(page, 'STATE_HUB');
    for (let i = 0; i < 10; i++) await page.keyboard.press('Space');

    // 던전 출격
    for (let i = 0; i < 6; i++) await page.keyboard.press('ArrowDown');
    await page.keyboard.press('Enter');
    await waitForHook(page, 'STATE_EXPLORE');
    await takeShot(page, '04_explore_start');

    // 전진하여 적 조우
    await page.keyboard.press('ArrowUp');
    await page.waitForTimeout(500);
    await page.keyboard.press('ArrowUp');
    await page.waitForTimeout(500);
    await takeShot(page, '05_before_combat');
    
    await page.keyboard.press('Space'); // 적 조우 실행
    await waitForHook(page, 'STATE_COMBAT');
    await takeShot(page, '06_combat_start');

    // 전투 진행 (SP 게이지 소모 확인용 스크린샷 포함)
    console.log('Executing attacks...');
    await page.keyboard.press('Enter'); // 공격 선택
    await page.waitForTimeout(200);
    await page.keyboard.press('Enter'); // 타겟 확정
    await page.waitForTimeout(1000);
    await takeShot(page, '07_combat_after_attack'); // SP 바 확인용

    for (let i = 0; i < 5; i++) {
      await page.keyboard.press('Enter');
      await page.waitForTimeout(200);
      await page.keyboard.press('Enter');
      await page.waitForTimeout(1500); 
      if (hooks.includes('COMBAT_RESULT_WIN')) break;
    }

    await waitForHook(page, 'COMBAT_RESULT_WIN');
    await takeShot(page, '08_combat_victory');
    
    await page.keyboard.press('Space');
    await page.waitForTimeout(1000);
    await takeShot(page, '09_recruitment_dialogue'); // 영입 대화 텍스트 확인
    
    for (let i = 0; i < 5; i++) {
        await page.keyboard.press('Space');
        await page.waitForTimeout(300);
    }
    
    await waitForHook(page, 'STATE_EXPLORE');
    await takeShot(page, '10_back_to_explore');
  });
});
