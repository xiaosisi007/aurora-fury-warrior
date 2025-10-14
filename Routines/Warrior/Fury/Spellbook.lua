--[[--------------------------------------------------------------------
    TT狂战 · 技能书
----------------------------------------------------------------------]]

local MythicWarrior = ...

-- 创建技能
local NewSpell = Aurora.SpellHandler.NewSpell

Aurora.SpellHandler.PopulateSpellbook({
    spells = {
        -- 主要输出技能（近战）- 只使用 ignoreFacing 加快施法
        Bloodthirst = NewSpell(23881, {
            ignoreFacing = true,  -- 忽略朝向检查，直接施放
        }),
        RagingBlow = NewSpell(85288, {
            ignoreFacing = true,
        }),
        Rampage = NewSpell(184367, {
            ignoreFacing = true,
        }),
        Execute = NewSpell(5308, {
            ignoreFacing = true,
        }),
        Whirlwind = NewSpell(190411, {
            ignoreFacing = true,  -- AOE技能，忽略朝向
        }),
        
        -- 大技能
        Recklessness = NewSpell(1719),
        Avatar = NewSpell(107574),
        Bladestorm = NewSpell(446035, {
            ignoreFacing = true,
        }),
        ThunderousRoar = NewSpell(384318, {
            ignoreFacing = true,
        }),
        
        -- 辅助技能
        EnragingRegeneration = NewSpell(184364),
        VictoryRush = NewSpell(34428),  -- 胜利在望（回复30%生命值）
        BattleShout = NewSpell(6673),   -- 战斗怒吼（队友增益BUFF）
        
        -- 中断技能
        Pummel = NewSpell(6552, {       -- 拳击（主要中断，15码，15秒CD）
            ignoreFacing = true,
        }),
        StormBolt = NewSpell(107570),   -- 风暴之锤（远程中断，40码，30秒CD）
        Shockwave = NewSpell(46968, {   -- 震荡波（AOE中断+眩晕，10码，40秒CD）
            ignoreFacing = true,
        }),
        
        -- SimC相关技能
        Bloodbath = NewSpell(335096, {  -- 浴血
            ignoreFacing = true,
        }),
        Onslaught = NewSpell(315720, {  -- 猛攻
            ignoreFacing = true,
        }),
        ChampionsSpear = NewSpell(376079, { -- 冠军之矛
            isSkillshot = true,
        }),
        OdynsFury = NewSpell(385059, {  -- 奥丁之怒
            ignoreFacing = true,
        }),
        
        -- 天赋检测（虚拟技能，用于isknown判断）
        RecklessAbandon = NewSpell(396749),    -- 鲁莽放弃
        AngerManagement = NewSpell(152278),    -- 怒气管理
        TitanicRage = NewSpell(394329),        -- 泰坦之怒
        Tenderize = NewSpell(389774),          -- 温柔
        ViciousContempt = NewSpell(383885),    -- 恶意轻蔑
        Uproar = NewSpell(391572),             -- 喧哗
        Bloodborne = NewSpell(385703),         -- 血生
        MeatCleaver = NewSpell(280392)         -- 血肉顺劈（天赋）
    },
    auras = {
        -- Buff
        Enrage = 184362,
        MeatCleaver = 85739,
        SuddenDeath = 280776,
        AshenJuggernaut = 392537,        -- 灰烬主宰（Slayer核心BUFF，正确ID）
        Recklessness = 1719,
        Avatar = 107574,
        BattleShout = 6673,              -- 战斗怒吼BUFF
        BrutalFinish = 446918,           -- 残暴终结（正确ID）
        SlaughteringStrikes = 393931,    -- 屠戮打击（正确ID）
        Opportunist = 456120,            -- 机会主义者（触发BUFF）
        Bloodcraze = 393951,             -- 血腥疯狂（嗜血层数BUFF，ID正确）
        Bladestorm = 446035,             -- 剑刃风暴BUFF（用于检查是否在风暴中）
        
        -- Debuff
        ExecutionersWill = 457131,
        Overwhelmed = 445836,            -- 不堪一击（屠戮者4件套效果）
        MarkedForExecution = 445584,     -- 处刑印记（Slayer核心Debuff）
        ChampionsMight = 386286,         -- 冠军之力（Debuff）
        BloodbathDot = 113344,           -- 浴血DoT
    },
    talents = {
        -- 这里可以添加天赋ID，如果需要判断
    },
}, "WARRIOR", 2, "TTFury")

return MythicWarrior
