-- 통합 번역 데이터베이스 (Unified Translations)
local translations = {
    -- 타이틀 화면
    ["title_game_name"] = { ko = "블랙아웃: 섹터 07", en = "BLACKOUT: SECTOR 07" },
    ["menu_new_game"] = { ko = "새로운 시작", en = "NEW OPERATION" },
    ["menu_load_game"] = { ko = "데이터 복구", en = "RESTORE DATA" },
    ["menu_options"] = { ko = "시스템 설정", en = "OPTIONS" },
    ["menu_exit"] = { ko = "연결 종료", en = "EXIT" },
    ["ui_no_save_found"] = { ko = "저장된 데이터를 찾을 수 없습니다.", en = "NO SAVE DATA DETECTED" },

    -- 공통 UI
    ["ui_attack"] = { ko = "공격", en = "ATTACK" },
    ["ui_defend"] = { ko = "방어", en = "DEFEND" },
    ["ui_flee"] = { ko = "퇴각", en = "FLEE" },
    ["ui_back"] = { ko = "뒤로", en = "BACK" },
    ["ui_close"] = { ko = "닫기", en = "CLOSE" },
    ["ui_active"] = { ko = "행동 중", en = "ACTIVE" },
    ["ui_terminal"] = { ko = "터미널", en = "TERMINAL" },

    -- 탐험 & HUD
    ["ui_radar_title"] = { ko = "레이더: 섹터 스캔", en = "RADAR: SECTOR SCAN" },
    ["ui_uplink_title"] = { ko = "분대 통신망", en = "SQUAD UPLINK" },
    ["ui_objective"] = { ko = "목표", en = "OBJECTIVE" },
    ["ui_pos_data"] = { ko = "위치", en = "POS_DATA" },
    ["ui_orientation"] = { ko = "방향", en = "ORIENTATION" },
    ["ui_neural_link"] = { ko = "신경망 연결 상태", en = "NEURAL LINK STABILITY" },
    ["ui_system_alert"] = { ko = "시스템 경고", en = "SYSTEM ALERT" },

    -- 펍 (허브) UI
    ["ui_squad_status"] = { ko = "부대 전투 현황", en = "SQUAD STATUS" },
    ["ui_mission_archive"] = { ko = "미션 기록", en = "MISSION ARCHIVE" },
    ["ui_central_command"] = { ko = "중앙 제어", en = "CENTRAL COMMAND" },
    ["ui_system_comms"] = { ko = "시스템 통신", en = "SYSTEM COMMS" },
    ["ui_uplink_stable"] = { ko = "연결: 안정됨", en = "UPLINK: STABLE" },
    ["ui_latency"] = { ko = "지연시간", en = "LATENCY" },
    ["ui_credits"] = { ko = "크레딧", en = "CREDITS" },

    -- 스탯 & 전투 UI
    ["ui_biometric_diag"] = { ko = "생체 진단 // 대상", en = "BIOMETRIC DIAGNOSTIC // SUBJECT" },
    ["ui_core_biometrics"] = { ko = "핵심 생체 데이터", en = "CORE BIOMETRICS" },
    ["ui_combat_perf"] = { ko = "전투 성능", en = "COMBAT PERFORMANCE" },
    ["ui_perk_deck"] = { ko = "활성 특성 덱", en = "ACTIVE PERK DECK" },
    ["ui_no_perks"] = { ko = "연결된 특성 없음", en = "NO PERKS LINKED" },
    ["ui_uncalibrated_pts"] = { ko = "미분배 포인트", en = "UNCALIBRATED POINTS" },
    ["ui_class"] = { ko = "직업", en = "CLASS" },
    ["ui_level"] = { ko = "레벨", en = "LV" },
    ["ui_sync_rate"] = { ko = "신경 동기화율", en = "NEURAL SYNC RATE" },

    ["stat_atk"] = { ko = "공격력", en = "ATK_PWR" },
    ["stat_def"] = { ko = "물리 방어력", en = "PHYS_DEF" },
    ["stat_crit"] = { ko = "치명타 확률", en = "CRIT_CHANCE" },
    ["stat_evade"] = { ko = "회피율", en = "EVASION" },
    ["stat_mem"] = { ko = "메모리 용량", en = "MEMORY_CAP" },

    ["ui_tactical_interface"] = { ko = "전술 분대 인터페이스", en = "TACTICAL SQUAD INTERFACE" },
    ["ui_skill_intel"] = { ko = "스킬 정보", en = "SKILL INTEL" },
    ["ui_commands"] = { ko = "명령", en = "COMMANDS" },
    ["ui_cost"] = { ko = "소모", en = "COST" },

    -- 기존 메뉴들
    ["hub_title"] = { ko = "지하 펍 허브", en = "DIVE BAR HUB" },
    ["hub_menu_rest"] = { ko = "[휴식] 에너지 충전 (HP/SP 회복)", en = "[Rest] Recharge (HP/SP Full)" },
    ["hub_menu_roster"] = { ko = "[편성] 용병 로스터 관리", en = "[Roster] Manage Mercenaries" },
    ["hub_menu_shop"] = { ko = "[상점] 리퍼닥 사이버웨어", en = "[Shop] Ripperdoc Cyberware" },
    ["hub_menu_status"] = { ko = "[정보] 부대원 상세 정보", en = "[Status] Squad Details" },
    ["hub_menu_skills"] = { ko = "[스킬] 사이버웨어 및 능력치", en = "[Skills] Cyberware & Skills" },
    ["hub_menu_save"] = { ko = "[저장] 데이터 백업", en = "[Save] Backup Data" },
    ["hub_menu_deploy"] = { ko = "[출격] 던전으로 진입", en = "[Deploy] Into the Dungeon" },
    ["hub_dialogue_welcome"] = { 
        ko = "바텐더: '살아 돌아왔군. 한 잔 마시고 찌그러진 곳이나 펴라고.'", 
        en = "BARTENDER: 'Back in one piece, huh? Grab a drink and fix those dents.'" 
    },
    ["hub_dialogue_rested"] = { 
        ko = "바텐더: '몸 상태는 좀 어때? 이제 가서 제 할 일이나 하라고.'", 
        en = "BARTENDER: 'Feeling fresh? Now get out there and do your job.'" 
    },
    ["hub_dialogue_stats"] = { 
        ko = "바텐더: '능력치를 점검하는 중인가?'", 
        en = "BARTENDER: 'Checking your stats, are we?'" 
    },
    ["hub_mission_log"] = { ko = "미션 로그", en = "MISSION LOG" },
    ["hub_skill_db"] = { ko = "부대 스킬 데이터베이스", en = "SQUAD SKILL DATABASE" },

    -- Hub 하드코딩 메시지
    ["hub_msg_skill_calibrated"] = { ko = "바텐더: '%s // %s 캘리브레이션 완료.'", en = "BARTENDER: '%s // %s CALIBRATION COMPLETE.'" },
    ["hub_msg_no_skill_pts"] = { ko = "바텐더: '스킬 포인트가 없잖아. 더 싸워야 해.'", en = "BARTENDER: 'No skill points. Go fight more.'" },
    ["hub_msg_stat_invested"] = { ko = "바텐더: '[%s] %s'", en = "BARTENDER: '[%s] %s'" },
    ["hub_msg_stat_denied"] = { ko = "바텐더: '안 돼. %s'", en = "BARTENDER: 'Negative. %s'" },
    ["hub_msg_promote_success"] = { ko = "바텐더: '%s // %s 축하한다.'", en = "BARTENDER: '%s // %s. Congratulations.'" },
    ["hub_msg_promote_fail"] = { ko = "바텐더: '조건이 안 됐어. %s'", en = "BARTENDER: 'Requirements not met. %s'" },
    ["hub_msg_ripper_target"] = { ko = "리퍼닥: '누구한테 이식할까?'", en = "RIPPERDOC: 'Who gets the implant?'" },
    ["hub_msg_party_empty"] = { ko = "바텐더: '파티를 편성해라.'", en = "BARTENDER: 'Form a party first.'" },
    ["hub_msg_save_success"] = { ko = "시스템: '%s'", en = "SYSTEM: '%s'" },

    -- 탐험
    ["exp_mode"] = { ko = "탐험 모드", en = "EXPLORATION MODE" },
    ["exp_coords"] = { ko = "현재 좌표", en = "COORDINATES" },
    ["exp_enemy_detected"] = { ko = "! 적 개체 감지 !", en = "! ENEMY DETECTED !" },
    ["exp_engage_prompt"] = { ko = "[SPACE]를 눌러 교전 시작", en = "Press [SPACE] to Engage" },

    -- 전투 로그
    ["log_battle_start"] = { ko = "전투 개시: ", en = "BATTLE COMMENCED: " },
    ["log_victory"] = { ko = "승리! 적 개체를 무력화했습니다.", en = "VICTORY! Enemy neutralized." },
    ["log_encounter"] = { ko = "교전 확인: %s", en = "ENCOUNTER: %s" },
    ["log_victory_reward"] = { ko = "VICTORY. +%dC / SPACE", en = "VICTORY. +%dC / SPACE" },
    ["log_squad_wiped"] = { ko = "분대 전멸. 후송 중... / SPACE", en = "SQUAD WIPED. EVACUATING... / SPACE" },
    ["log_treasure"] = { ko = "상자에서 %d 크레딧을 획득했습니다.", en = "Obtained %d credits from the chest." },
    ["log_reflex_counter"] = { ko = " // 리플렉스 반격: %d DMG!", en = " // REFLEX COUNTER: %d DMG!" },

    -- 직업 (Classes)
    ["class_solo"] = { ko = "솔로 (Solo)", en = "SOLO" },
    ["class_reflexer"] = { ko = "리플렉서 (Reflexer)", en = "REFLEXER" },
    ["class_techie"] = { ko = "테크니션 (Techie)", en = "TECHIE" },
    ["class_netrunner"] = { ko = "넷러너 (Netrunner)", en = "NETRUNNER" },
    ["class_ripperdoc"] = { ko = "스트리트 닥터 (Ripperdoc)", en = "RIPPERDOC" },

    -- 스킬 (Skills)
    ["skill_attack"]           = { ko = "표준 공격",      en = "STANDARD ATTACK" },
    ["skill_defend"]           = { ko = "방어 태세",      en = "DEFENSIVE STANCE" },
    ["skill_punch"]            = { ko = "근거리 파쇄",      en = "MELEE SMASH" },
    ["skill_adrenaline"] = { ko = "아드레날린 펌프", en = "ADRENALINE PUMP" },
    ["skill_taunt"] = { ko = "고기 방패", en = "MEAT SHIELD" },
    ["skill_slice"] = { ko = "단분자 베기", en = "MONO-SLICE" },
    ["skill_sandevistan"] = { ko = "산데비스탄 가속", en = "SANDEVISTAN" },
    ["skill_suppress"] = { ko = "제압 사격", en = "SUPPRESSIVE FIRE" },
    ["skill_shotgun"] = { ko = "산탄 사격", en = "SHOTGUN BLAST" },
    ["skill_synapse"] = { ko = "시냅스 과열", en = "SYNAPSE BURNOUT" },
    ["skill_shutdown"] = { ko = "시스템 셧다운", en = "SYSTEM SHUTDOWN" },
    ["skill_nano"] = { ko = "나노봇 사출", en = "NANOBOT INJECTION" },
    ["skill_stim"] = { ko = "전투 자극제", en = "COMBAT STIM" },
    ["skill_target_mark"] = { ko = "표적 지정", en = "TARGET MARKED" },
    ["skill_suppress_all"] = { ko = "광역 제압", en = "SUPPRESS ALL" },
    ["skill_berserker_rage"] = { ko = "버서커 격분", en = "BERSERKER RAGE" },
    ["skill_sentinel_wall"] = { ko = "센추리온 방벽", en = "SENTINEL WALL" },
    ["skill_blade_vortex"] = { ko = "칼날 소용돌이", en = "BLADE VORTEX" },
    ["skill_shadow_kill"]      = { ko = "그림자 살해",      en = "SHADOW KILL" },
    ["skill_armor_pierce"]     = { ko = "장갑 관통탄",      en = "ARMOR PIERCE" },
    ["skill_drone_swarm"]      = { ko = "드론 군단",        en = "DRONE SWARM" },
    ["skill_mass_shutdown"]    = { ko = "대규모 셧다운",    en = "MASS SHUTDOWN" },
    ["skill_brain_fry"]        = { ko = "뇌 소각",          en = "BRAIN FRY" },
    ["skill_emergency_revive"] = { ko = "긴급 소생",        en = "EMERGENCY REVIVE" },
    ["skill_overclock"]        = { ko = "오버클럭",         en = "OVERCLOCK" },

    -- 적 이름 (Enemy IDs)
    ["enemy_drone"] = { ko = "보안 드론", en = "SECURITY DRONE" },
    ["enemy_psycho"] = { ko = "사이버 사이코", en = "CYBER PSYCHO" },
    ["boss_seraphina"] = { ko = "세라피나", en = "Seraphina" },
    ["AURORA_08"] = { ko = "오로라", en = "Aurora" },
    ["LUNA_VENUS"] = { ko = "루나 베누스", en = "Luna Venus" },
    ["ASTRAL_CORE"] = { ko = "아스트라 코어", en = "Astral Core" },
    ["RB-01"] = { ko = "루비 - 핏빛 왈츠의 여왕", en = "Ruby - Queen of the Crimson Waltz" },
    ["CORE-01"] = { ko = "코어 - 데이터 여제", en = "Core - The Data Empress" },
    ["B1-012"] = { ko = "세레나", en = "Serena" },
    ["BG-012"] = { ko = "시퀀스 딜러", en = "Sequence Dealer" },

    -- 캐릭터 이름
    ["system"] = { ko = "SYSTEM", en = "SYSTEM" },
    ["npc_bartender"] = { ko = "BARTENDER", en = "BARTENDER" },
    ["merc_01_luna"] = { ko = "LUNA", en = "LUNA" },
    ["merc_02_helena"] = { ko = "HELENA", en = "HELENA" },
    ["merc_03_mio"] = { ko = "MIO", en = "MIO" },
    ["merc_07_kira"] = { ko = "KIRA", en = "KIRA" },

    -- 스토리 챕터 1: 블랙아웃 - 각성
    ["story_ch1_title"] = { ko = "CHAPTER 1: 네온의 그림자", en = "CHAPTER 1: Neon Shadows" },
    ["story_ch1_intro1"] = { ko = "[시스템 소음... 치직...] // 신경망 동기화율 12%... 24%... 재부팅 중...", en = "[System Noise... Static...] // Neural sync at 12%... 24%... Rebooting..." },
    ["story_ch1_intro2"] = { ko = "루나: '...여긴 어디지? 머릿속이... 마치 불타는 전선 뭉치가 들어있는 것 같아.'", en = "Luna: '...Where am I? My head feels like... a bundle of burning wires.'" },
    ["story_ch1_event1"] = { ko = "바텐더: '정신이 드나, 쥐새끼. 뇌세포가 절반은 타버린 줄 알았는데 운이 좋군. 기억은 나나? 아니면 그 잘난 이름이라도 까먹었어?'", en = "Bartender: 'Wake up, rat. I thought half your brain cells were fried. Lucky you. Do you remember anything? Or did you even forget that fancy name of yours?'" },
    ["story_ch1_event2"] = { ko = "바텐더: '섹터 07 외곽에 아스트라 코프의 버려진 연구소가 하나 있어. 10년 전 '블랙아웃'의 진실이 담긴 원본 데이터가 거기 있지. 널 살려준 대가는 톡톡히 치러야 할 거다.'", en = "Bartender: 'There's an abandoned Astra Corp lab on the edge of Sector 07. The original data from the Blackout 10 years ago is there. You're going to pay back the favor of being alive.'" },
    ["story_ch1_luna_re1"] = { ko = "루나: '내가 왜 당신 말을 들어야 하지? 내 목 뒤에 달린 이 칩... 당신이 심어둔 건가?'", en = "Luna: 'Why should I listen to you? This chip in my neck... did you put it there?'" },
    ["story_ch1_event3"] = { ko = "바텐더: '질문할 시간 없다. 경비 드론들이 벌써 네 생체 신호를 감지했어. 살고 싶으면 총부터 잡아라. 팩토리 심층부로 가려면 입구를 지키는 '워처'부터 박살내.'", en = "Bartender: 'No time for questions. Security drones already picked up your signal. Grab your gun if you want to live. Smash the Watcher at the entrance to reach the deep sector.'" },
    ["story_ch1_system_boot"] = { ko = "[SYSTEM] 시각 피드백 최적화 완료. 전술 오버레이를 기동합니다. // 행운을 빕니다, 루나.", en = "[SYSTEM] Visual feedback optimized. Activating tactical overlay. // Good luck, Luna." },

    -- 스토리 챕터 2: 기억의 파편
    ["story_ch2_title"] = { ko = "CHAPTER 2: 금속의 비명", en = "CHAPTER 2: Screams of Metal" },
    ["story_ch2_event1"] = { ko = "루나: '드론은 처리했어. 하지만 연구소 상태가 이상해. 벽면의 케이블들이 마치 살아있는 혈관처럼 꿈틀거리고 있어. 그리고 저기... 바닥에 흐르는 이건 피인가?'", en = "Luna: 'Drones cleared. But this lab is weird. The cables on the walls are pulsing like veins. And that... is that blood on the floor?'" },
    ["story_ch2_event2"] = { ko = "헬레나: '쉿, 목소리 낮춰. 'Prey'가 도망친 지 얼마 안 됐어. 아스트라에서 보낸 청소부인가? 아니면... 나처럼 버려진 찌꺼기인가?'", en = "Helena: 'Shush, keep it down. The prey just fled. Are you a cleaner sent by Astra? Or... discarded scrap like me?'" },
    ["story_ch2_luna_re1"] = { ko = "루나: '난 그저 내가 누군지 알고 싶을 뿐이야. 방해한다면 너도 이 고철 더미들처럼 만들어주지.'", en = "Luna: 'I just want to know who I am. If you get in my way, I'll turn you into scrap like the rest of these.'" },
    ["story_ch2_helena_re1"] = { ko = "헬레나: '후후, 눈빛은 살아있군. 마음에 들어. 난 헬레나다. 탈주한 해커 놈을 쫓고 있지. 놈의 뇌 속엔 '진짜 코어'의 좌표가 있어. 혼자보단 둘이 낫겠지. 링크를 수락해라.'", en = "Helena: 'Heh, I like those eyes. Name's Helena. I'm tracking a rogue hacker. His brain has the coordinates to the true core. Two is better than one. Accept the link.'" },
    ["story_ch2_join_msg"] = { ko = "[SYSTEM] 전술 네트워크 확장 중... 헬레나의 바이오칩이 감지되었습니다. 동기화하시겠습니까?", en = "[SYSTEM] Expanding tactical network... Helena's bio-chip detected. Synchronize?" },
    ["story_ch2_choice_accept"] = { ko = "헬레나와 신경망을 연결한다 (파티 합류)", en = "Connect neural link with Helena (Join Party)" },
    ["story_ch2_event3"] = { ko = "헬레나: '좋은 선택이야. 이제부터 우린 한 배를 탄 거다. 저기 보여? 환기구 안으로 숨어 들어간 해커의 흔적이야. 놈이 시스템을 완전히 잠그기 전에 잡아야 해!'", en = "Helena: 'Good choice. We're in the same boat now. See that? Signs of the hacker hiding in the vents. We need to catch him before he locks down the system!'" },

    -- 스토리 챕터 3
    ["story_ch3_title"] = { ko = "CHAPTER 3: 조작된 진실", en = "CHAPTER 3: Fabricated Truth" },
    ["story_ch3_goal"] = { ko = "역추적해 온 아스트라 코프의 기업 집행관(corp_enforcer)을 처치하라.", en = "Eliminate the Astra Corp Enforcer tracing your signal." },
    ["story_ch3_event1"] = { ko = "[시스템] 해커의 중추 신경계에서 잔류 데이터를 강제 추출합니다. 암화화된 '프로젝트: 에덴'의 도면이 확인됩니다.", en = "[SYSTEM] Forcibly extracting remnant data from the hacker's central nervous system. Encrypted blueprints of 'Project: Eden' confirmed." },
    ["story_ch3_event2"] = { ko = "이 도면... 내 머릿속에 이식된 가짜 기억의 배경과 똑같아. 내가 인간이 아니라... 아스트라의 배양조에서 만들어진 부품이라고?", en = "These blueprints... they match the background of the fake memories implanted in my head. I'm not human... I'm just a part made in Astra's vats?" },
    ["story_ch3_event3"] = { ko = "이제야 현실을 직시했군. 내 목덜미에도 똑같은 바코드가 찍혀 있지. 난 미오다. 코프의 개들을 썰어버릴 시간이야.", en = "Finally facing reality. I have the same barcode stamped on the back of my neck. I'm Mio. Time to slice up the Corp's dogs." },
    ["story_ch3_join_msg"] = { ko = "미오의 단분자 블레이드가 파티에 합류했습니다.", en = "Mio's mono-molecular blade has joined the party." },
    ["story_ch3_choice_accept"] = { ko = "피의 복수에 동참한다", en = "Join the bloody revenge" },
    ["story_ch3_choice_betray"] = { ko = "미오를 거부하고 아카시 코프에 좌표를 판다 (+600C)", en = "Refuse Mio and sell the coordinates to Astra Corp (+600C)" },
    ["story_ch3_event4"] = { ko = "감상에 젖을 시간 없다! 해커의 사망 신호가 역추적 당했어. 아스트라 코프의 '집행관'들이 들이닥친다! 전원 전투 준비!", en = "No time for sentimentality! The hacker's death signal was backtraced. Astra Corp's 'Enforcers' are breaching! All units, prepare for combat!" },

    -- 스토리 챕터 4
    ["story_ch4_title"] = { ko = "CHAPTER 4: 고기 분쇄기", en = "CHAPTER 4: The Meat Grinder" },
    ["story_ch4_goal"] = { ko = "폐기장에 갇혀 폭주하는 사이버 사이코(cyber_psycho) 부대를 섬멸하라.", en = "Annihilate the rampaging Cyber Psycho squad locked in the scrapyard." },
    ["story_ch4_event1"] = { ko = "집행관들은 처리했지만... 코어룸 아래에서 끔찍한 비명소리가 들려. 마치 수천 명의 뇌가 한꺼번에 타들어가는 것 같은...", en = "Enforcers neutralized... but there are horrific screams coming from below the core room. Like thousands of brains burning at once..." },
    ["story_ch4_event2"] = { ko = "접속 경고! 거대한 바이러스 덩어리들이 몰려와요! 저건 실패한 실험체들... '사이버 사이코' 부대예요! 제가 방화벽을 칠게요!", en = "Connection Warning! Massive viral clusters approaching! Those are failed test subjects... the 'Cyber Psycho' squad! I'll put up a firewall!" },
    ["story_ch4_join_msg"] = { ko = "키라의 전뇌 해킹 지원이 활성화되었습니다.", en = "Kira's cyber-hacking support is now active." },
    ["story_ch4_choice_accept"] = { ko = "네트워크 방어를 맡긴다", en = "Entrust network defense" },
    ["story_ch4_event3"] = { ko = "저 괴물들은 한때 너희와 같은 '인간'이었다. 코어에 도달하려면 저 고기 분쇄기를 뚫고 지나가는 수밖에 없어. 살아남아라!", en = "Those monsters were once 'human' like you. To reach the core, you have no choice but to break through that meat grinder. Survive!" },

    -- 스토리 챕터 5
    ["story_ch5_title"] = { ko = "CHAPTER 5: 심연의 끝", en = "CHAPTER 5: The Edge of the Abyss" },
    ["story_ch5_goal"] = { ko = "모든 진실이 밝혀졌습니다. 도시의 운명을 결정하십시오.", en = "All truths have been revealed. Decide the fate of the city." },
    ["story_ch5_event1"] = { ko = "메인 서버 터미널 접속 성공. 아스트라 코프의 시민 신경망 지배 프로젝트, 전체 삭제 권한을 확보했습니다.", en = "Main server terminal access successful. Astra Corp's Citizen Neural Domination Project: full deletion privileges secured." },
    ["story_ch5_event2"] = { ko = "수백만 명의 뇌가 이 코어에 연결되어 강제로 통제받고 있었어... 스위치 하나면 이 끔찍한 도시의 시스템을 영원히 꺼버릴 수 있어.", en = "Millions of brains are connected to this core, forcibly controlled... With one switch, we can turn off this horrific city's system forever." },
    ["story_ch5_event3"] = { ko = "잠깐! 그 데이터를 파괴하지 말고 내게 넘겨라. 내가 그 권력을 쥐게 되면, 너희에겐 평생 쓰다 남을 부와 자유를 주마. 선택해라!", en = "Wait! Don't destroy that data, hand it over to me. If I hold that power, I'll give you wealth and freedom for a lifetime. Choose!" },
    ["story_ch5_choice_prompt"] = { ko = "눈앞에 놓인 운명의 스위치. 당신의 결단은?", en = "The switch of fate lies before you. What is your decision?" },
    ["story_ch5_choice_shutdown"] = { ko = "모든 데이터를 파괴하고 도시를 암흑으로 몰아넣는다 (혁명)", en = "Destroy all data and plunge the city into darkness (Revolution)" },
    ["story_ch5_choice_betray"]   = { ko = "데이터를 바텐더에게 넘기고 대가를 받는다 (배신)", en = "Hand the data to the Bartender and collect the reward (Betrayal)" },

    -- 엔딩
    ["ending_hope_title"] = { ko = "ENDING: 네온의 혁명가", en = "ENDING: Neon Revolutionary" },
    ["ending_hope_text"] = { ko = "스위치가 내려가자, 귀를 찢는 폭음과 함께 섹터 07을 넘어 도시 전체의 전력이 차단되었습니다. 억압받던 수백만의 신경망이 풀려났고, 통제 불능의 완벽한 어둠 속에서 루나는 처음으로 인간다운 옅은 미소를 지었습니다. 네온사인이 꺼진 내일의 도시는 혼돈이겠지만, 적어도 그것은 '진짜' 현실일 것입니다.", en = "As the switch was flipped, a deafening explosion cut all power beyond Sector 07, blacking out the entire city. Millions of oppressed neural networks were freed, and in the uncontrollable, perfect darkness, Luna wore a faint, truly human smile for the first time. The city of tomorrow, void of neon, will be chaos, but at least it will be a 'real' reality." },
    ["ending_betrayal_title"] = { ko = "ENDING: 황금빛 노예", en = "ENDING: Golden Slave" },
    ["ending_betrayal_text"] = { ko = "당신의 손가락이 '전송' 버튼을 눌렀습니다. 바텐더는 약속대로 막대한 크레딧을 입금했고, 당신은 최고급 펜트하우스에서 인공적인 안락함을 누리게 되었습니다. 하지만 루나와 다른 동료들의 생사는 영영 알 수 없게 되었고, 창밖의 네온사인은 여전히 누군가의 뇌를 태우며 빛나고 있습니다.", en = "Your finger pressed the 'Transmit' button. The bartender transferred massive credits as promised, and you came to enjoy artificial comfort in a top-tier penthouse. However, the fate of Luna and the others remains forever unknown, and the neon signs outside the window continue to shine, burning someone else's brain." },

    -- 전멸 이벤트
    ["story_wipe_title"] = { ko = "SYSTEM: 강제 연결 해제", en = "SYSTEM: Forced Disconnect" },
    ["story_wipe_event1"] = { ko = "[CRITICAL] 분대 전멸 확인. 트라우마 팀 자동 호출. 자산 보존을 위해 현재 크레딧의 50%가 수수료로 차감됩니다.", en = "[CRITICAL] Squad wipe confirmed. Trauma Team dispatched. 50% of current credits deducted for asset preservation." },
    ["story_wipe_event2"] = { ko = "이봐! 거의 죽을 뻔했잖아! 수리비로 내 지갑이 가벼워지는 꼴을 꼭 봐야겠어? 정신 똑바로 차려!", en = "Hey! You almost kicked the bucket! Do you have to see my wallet get lighter for your repairs? Wake up!" }
}

return translations