-- 스토리 챕터 시드 데이터 (DB 마이그레이션용)
return {
    chapters = {
        {
            id = 1, chapter_order = 1,
            trigger_type = "initial", trigger_id = "",
            title = "story_ch1_title",
            events = {
                { order=1, speaker="npc_bartender", portrait="npc_bartender", side="right", text="story_ch1_event1" },
                { order=2, speaker="npc_bartender", portrait="npc_bartender", side="right", text="story_ch1_event2" },
                { order=3, speaker="system",        portrait="ui_frame_holo", side="left",  text="story_ch1_event3" },
            }
        },
        {
            id = 2, chapter_order = 2,
            trigger_type = "boss_kill", trigger_id = "drone_security",
            title = "story_ch2_title",
            events = {
                { order=1, speaker="merc_01_luna",   portrait="merc_01_luna",   side="left",  text="story_ch2_event1" },
                { order=2, speaker="merc_02_helena", portrait="merc_02_helena", side="right", text="story_ch2_event2" },
                { order=3, speaker="system", portrait="ui_frame_holo", side="left", text="story_ch2_join_msg",
                  is_choice_node=true,
                  choices = {
                      { order=1, text="story_ch2_choice_accept", actions={{type="unlock_merc", id="merc_02"}} }
                  }
                },
                { order=4, speaker="npc_bartender", portrait="npc_bartender", side="right", text="story_ch2_event3" },
            }
        },
        {
            id = 3, chapter_order = 3,
            trigger_type = "boss_kill", trigger_id = "hacker_rogue",
            title = "story_ch3_title",
            events = {
                { order=1, speaker="system",       portrait="ui_frame_holo", side="left",  text="story_ch3_event1" },
                { order=2, speaker="merc_01_luna", portrait="merc_01_luna",  side="left",  text="story_ch3_event2" },
                { order=3, speaker="merc_03_mio",  portrait="merc_03_mio",   side="right", text="story_ch3_event3" },
                { order=4, speaker="system", portrait="ui_frame_holo", side="left", text="story_ch3_join_msg",
                  is_choice_node=true,
                  choices = {
                      { order=1, text="story_ch3_choice_accept", actions={{type="unlock_merc", id="merc_03"}} },
                      { order=2, text="story_ch3_choice_betray",
                        actions={{type="set_flag", key="betrayal_path", val=true}, {type="give_credits", val=600}} }
                  }
                },
                { order=5, speaker="npc_bartender", portrait="npc_bartender", side="right", text="story_ch3_event4" },
            }
        },
        {
            id = 4, chapter_order = 4,
            trigger_type = "boss_kill", trigger_id = "corp_enforcer",
            title = "story_ch4_title",
            events = {
                { order=1, speaker="merc_01_luna", portrait="merc_01_luna", side="left",  text="story_ch4_event1" },
                { order=2, speaker="merc_07_kira", portrait="merc_07_kira", side="right", text="story_ch4_event2" },
                { order=3, speaker="system", portrait="ui_frame_holo", side="left", text="story_ch4_join_msg",
                  is_choice_node=true,
                  choices = {
                      { order=1, text="story_ch4_choice_accept", actions={{type="unlock_merc", id="merc_07"}} }
                  }
                },
                { order=4, speaker="npc_bartender", portrait="npc_bartender", side="right", text="story_ch4_event3" },
            }
        },
        {
            id = 5, chapter_order = 5,
            trigger_type = "boss_kill", trigger_id = "cyber_psycho",
            title = "story_ch5_title",
            events = {
                { order=1, speaker="system",        portrait="ui_frame_holo", side="left",  text="story_ch5_event1" },
                { order=2, speaker="merc_01_luna",  portrait="merc_01_luna",  side="left",  text="story_ch5_event2" },
                { order=3, speaker="npc_bartender", portrait="npc_bartender", side="right", text="story_ch5_event3" },
                { order=4, speaker="system", portrait="ui_frame_holo", side="left", text="story_ch5_choice_prompt",
                  is_choice_node=true,
                  choices = {
                      { order=1, text="story_ch5_choice_shutdown",
                        actions={{type="set_flag", key="ending", val="hope"}, {type="end_game"}} },
                      { order=2, text="story_ch5_choice_betray",
                        actions={{type="set_flag", key="ending", val="betrayal"}, {type="end_game"}} }
                  }
                },
            }
        },
        {
            id = 6, chapter_order = 6,
            trigger_type = "wipe", trigger_id = "",
            title = "story_wipe_title",
            events = {
                { order=1, speaker="system",        portrait="ui_frame_holo", side="left",  text="story_wipe_event1" },
                { order=2, speaker="npc_bartender", portrait="npc_bartender", side="right", text="story_wipe_event2" },
            }
        },
    }
}
