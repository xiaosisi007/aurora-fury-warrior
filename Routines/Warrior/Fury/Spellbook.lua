--[[--------------------------------------------------------------------
    TT狂战 · 技能书
----------------------------------------------------------------------]]

local MythicWarrior = ...

-- 创建技能
local NewSpell = Aurora.SpellHandler.NewSpell

Aurora.SpellHandler.PopulateSpellbook({
    spells = {
        -- ⚡ 极限优化：主要输出技能（近战）
        Bloodthirst = NewSpell(23881, {
            ignoreFacing = true,   -- 忽略朝向检查
            ignoreMoving = true,   -- 移动中可施放
            queued = true,         -- 允许技能排队
        }),
        RagingBlow = NewSpell(85288, {
            ignoreFacing = true,
            ignoreMoving = true,   -- 移动中可施放
            queued = true,         -- 允许技能排队
        }),
        Rampage = NewSpell(184367, {
            ignoreFacing = true,
            ignoreMoving = true,   -- 移动中可施放
            queued = true,
        }),
        Execute = NewSpell(5308, {
            ignoreFacing = true,
            ignoreMoving = true,   -- 移动中可施放
            queued = true,
        }),
        Whirlwind = NewSpell(190411, {
            ignoreFacing = true,
            ignoreMoving = true,   -- 移动中可施放
            queued = true,         -- AOE技能也允许排队
        }),
        
        -- ⚡⚡ 极限优化：大技能（爆发CD）
        Recklessness = NewSpell(1719, {
            queued = true,         -- 技能排队
            ignoreFacing = true,
            ignoreMoving = true,   -- 移动中可施放
            ignoreCasting = true,  -- ⚡ 可打断当前施法立即使用
        }),
        Avatar = NewSpell(107574, {
            queued = true,
            ignoreFacing = true,
            ignoreMoving = true,
            ignoreCasting = true,  -- ⚡ 可打断当前施法立即使用
        }),
        Bladestorm = NewSpell(446035, {
            queued = true,
            ignoreFacing = true,
            ignoreMoving = true,
            ignoreCasting = true,  -- ⚡ 可打断当前施法立即使用
        }),
        ThunderousRoar = NewSpell(384318, {
            queued = true,
            ignoreFacing = true,
            ignoreMoving = true,
            ignoreCasting = true,  -- ⚡ 可打断当前施法立即使用
        }),
        
        -- ⚡ 极限优化：辅助技能（生存/防御）
        EnragingRegeneration = NewSpell(184364, {
            ignoreFacing = true,
            ignoreMoving = true,
            ignoreCasting = true,     -- ⚡ 紧急生存技能，打断当前施法
            ignoreChanneling = true,  -- ⚡ 打断引导技能
        }),
        VictoryRush = NewSpell(34428, {
            ignoreFacing = true,
            ignoreMoving = true,
            ignoreCasting = true,     -- ⚡ 紧急生存技能
            ignoreChanneling = true,
        }),
        SpellReflection = NewSpell(23920, {
            ignoreFacing = true,
            ignoreMoving = true,
            ignoreCasting = true,     -- ⚡ 紧急防御技能
            ignoreChanneling = true,
        }),
        RallyCry = NewSpell(97462, {
            ignoreFacing = true,
            ignoreMoving = true,
            ignoreCasting = true,     -- ⚡ 紧急团队防御技能
            ignoreChanneling = true,
        }),
        BattleShout = NewSpell(6673, {
            ignoreFacing = true,
            ignoreMoving = true,
        }),
        
        -- ⚡ 极限优化：中断技能（打断优先级最高）
        Pummel = NewSpell(6552, {
            ignoreFacing = true,
            ignoreMoving = true,
            ignoreCasting = true,     -- ⚡ 打断必须能打断当前施法
            ignoreChanneling = true,
            queued = true,            -- ⚡ 允许排队，即时响应
        }),
        StormBolt = NewSpell(107570, {
            ignoreFacing = true,
            ignoreMoving = true,
            ignoreCasting = true,
            ignoreChanneling = true,
            queued = true,
        }),
        Shockwave = NewSpell(46968, {
            ignoreFacing = true,
            ignoreMoving = true,
            ignoreCasting = true,
            ignoreChanneling = true,
            queued = true,
        }),
        
        -- ⚡ 极限优化：SimC相关技能
        Bloodbath = NewSpell(335096, {
            ignoreFacing = true,
            ignoreMoving = true,
            queued = true,         -- ⚡ 允许排队
        }),
        Onslaught = NewSpell(315720, {
            ignoreFacing = true,
            ignoreMoving = true,
            queued = true,         -- ⚡ 允许排队
        }),
        ChampionsSpear = NewSpell(376079, {
            isSkillshot = true,
            ignoreFacing = true,
            ignoreMoving = true,
            queued = true,         -- ⚡ 技能射击也允许排队
        }),
        OdynsFury = NewSpell(385059, {
            ignoreFacing = true,
            ignoreMoving = true,
            queued = true,         -- ⚡ AOE爆发技能允许排队
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
        Victorious = 32216,              -- 胜利在望BUFF（击杀敌人后触发，20秒持续时间）
        
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
