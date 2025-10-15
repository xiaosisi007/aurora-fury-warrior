local player = Aurora.UnitManager:Get("player")

-- 检查是否为狂怒战士
if player then
    local isWarrior = (player.class2 == "WARRIOR")
    local isFury = (player.spec == 2)
    
    if not (isWarrior and isFury) then
        -- 不是狂怒战士，直接返回，不加载任何内容
        if isWarrior then
            -- 是战士但不是狂怒天赋
            -- print("|cffffff00[TT狂战]|r 当前不是狂怒天赋 (Spec ID: " .. tostring(player.spec) .. ")，模块未加载")
            -- print("|cffffff00[提示]|r 切换到狂怒天赋后 /reload 重新加载")
        else
            -- 不是战士职业
            -- print("|cffffff00[TT狂战]|r 当前职业不是战士 (Class: " .. tostring(player.class2 or "未知") .. ")，模块未加载")
        end
        
        -- 直接返回，阻止后续所有代码执行
        -- 不加载GUI、宏命令、Toggle、循环等任何内容
        return MythicWarrior
    end
    
    -- 通过检查，显示加载信息
    -- print("|cff00ff00[TT狂战]|r 检测到狂怒战士，正在加载模块...")
else
    -- player不存在时的兜底处理
    -- print("|cffff0000[TT狂战]|r 无法检测玩家信息，模块加载中止")
    return MythicWarrior
end

-- 获取技能和光环
local S = Aurora.SpellHandler.Spellbooks.warrior["2"].TTFury.spells
local A = Aurora.SpellHandler.Spellbooks.warrior["2"].TTFury.auras
local target = Aurora.UnitManager:Get("target")

------------------------------------------------------------------------
-- 配置系统集成
------------------------------------------------------------------------

-- 设置默认值
if Aurora and Aurora.Config then
    -- 循环模式
    Aurora.Config:SetDefault("fury.rotation.mode", 2)  -- 1=主播手法, 2=SimC模拟（大秘境手法）
    Aurora.Config:SetDefault("fury.rotation.streamer", false)  -- 主播手法开关
    Aurora.Config:SetDefault("fury.rotation.simc", true)     -- SimC模拟开关（大秘境手法）
    
    -- 大技能
    Aurora.Config:SetDefault("fury.useRecklessness", true)
    Aurora.Config:SetDefault("fury.useAvatar", true)
    Aurora.Config:SetDefault("fury.useBladestorm", true)
    Aurora.Config:SetDefault("fury.useThunderousRoar", true)
    
    -- 辅助技能
    Aurora.Config:SetDefault("fury.useEnragingRegeneration", true)
    Aurora.Config:SetDefault("fury.enragingRegenerationThreshold", 45)
    Aurora.Config:SetDefault("fury.useVictoryRush", true)
    Aurora.Config:SetDefault("fury.victoryRushThreshold", 40)
    Aurora.Config:SetDefault("fury.useSpellReflection", true)
    Aurora.Config:SetDefault("fury.spellReflectionCastPercent", 60)  -- 施法进度阈值
    
    -- 自动目标切换
    Aurora.Config:SetDefault("fury.autoTarget", true)  -- 自动目标切换开关
    Aurora.Config:SetDefault("fury.autoTargetRange", 8)  -- 自动目标切换最大范围（码）- 近战范围
    
    -- 饰品
    Aurora.Config:SetDefault("fury.trinket1.enabled", true)
    Aurora.Config:SetDefault("fury.trinket1.withCooldowns", true)
    Aurora.Config:SetDefault("fury.trinket2.enabled", true)
    Aurora.Config:SetDefault("fury.trinket2.withCooldowns", true)
    
    -- 中断设置
    Aurora.Config:SetDefault("fury.useInterrupt", true)
    Aurora.Config:SetDefault("fury.interruptWithList", true)
    Aurora.Config:SetDefault("fury.interruptCastPercent", 60)  -- 施法进度百分比阈值
    Aurora.Config:SetDefault("fury.usePummel", true)
    Aurora.Config:SetDefault("fury.useStormBolt", true)
    Aurora.Config:SetDefault("fury.stormBoltEnemyCount", 1)
    Aurora.Config:SetDefault("fury.useShockwave", true)
    Aurora.Config:SetDefault("fury.shockwaveEnemyCount", 2)
    
    -- AOE阈值
    Aurora.Config:SetDefault("fury.aoeThreshold4", 4)
    Aurora.Config:SetDefault("fury.aoeThreshold5", 5)
    
    -- 调试
    Aurora.Config:SetDefault("fury.debug", false)
    
    -- 版本追踪
    Aurora.Config:SetDefault("fury.lastSeenVersion", "0.0.0")
end

-- 配置读取函数
local function GetConfig(key, fallback)
    if Aurora and Aurora.Config then
        local value = Aurora.Config:Read("fury." .. key)
        if value ~= nil then
            return value
        end
    end
    return fallback
end

-- 配置访问器（方便访问，带缓存）
local cfg = setmetatable({}, {
    __index = function(t, key)
        -- 循环模式
        if key == "rotationMode" then return GetConfig("rotation.mode", 2) end
        if key == "rotationVersion" then return GetConfig("rotation.version", 1) end
        
        -- 大技能
        if key == "useRecklessness" then return GetConfig("useRecklessness", true) end
        if key == "useAvatar" then return GetConfig("useAvatar", true) end
        if key == "useBladestorm" then return GetConfig("useBladestorm", true) end
        if key == "useThunderousRoar" then return GetConfig("useThunderousRoar", true) end
        
        -- 辅助技能
        if key == "useEnragingRegeneration" then return GetConfig("useEnragingRegeneration", true) end
        if key == "enragingRegenerationThreshold" then return GetConfig("enragingRegenerationThreshold", 45) end
        if key == "useVictoryRush" then return GetConfig("useVictoryRush", true) end
        if key == "victoryRushThreshold" then return GetConfig("victoryRushThreshold", 40) end
        if key == "useSpellReflection" then return GetConfig("useSpellReflection", true) end
        if key == "spellReflectionCastPercent" then return GetConfig("spellReflectionCastPercent", 60) end
        
        -- 自动目标切换
        if key == "autoTarget" then return GetConfig("autoTarget", true) end
        if key == "autoTargetRange" then return GetConfig("autoTargetRange", 8) end
        
        -- 饰品
        if key == "useTrinket1" then return GetConfig("trinket1.enabled", true) end
        if key == "trinket1WithCooldowns" then return GetConfig("trinket1.withCooldowns", true) end
        if key == "useTrinket2" then return GetConfig("trinket2.enabled", true) end
        if key == "trinket2WithCooldowns" then return GetConfig("trinket2.withCooldowns", true) end
        
        -- 药水和消耗品（保持本地默认值）
        if key == "useHealthstone" then return true end
        if key == "healthstoneThreshold" then return 40 end
        if key == "useHealingPotion" then return true end
        if key == "healingPotionThreshold" then return 35 end
        if key == "useCombatPotion" then return true end
        if key == "combatPotionWithCooldowns" then return true end
        
        -- 中断设置
        if key == "useInterrupt" then return GetConfig("useInterrupt", true) end
        if key == "interruptWithList" then return GetConfig("interruptWithList", true) end
        if key == "interruptCastPercent" then return GetConfig("interruptCastPercent", 60) end
        if key == "usePummel" then return GetConfig("usePummel", true) end
        if key == "useStormBolt" then return GetConfig("useStormBolt", true) end
        if key == "stormBoltEnemyCount" then return GetConfig("stormBoltEnemyCount", 1) end
        if key == "useShockwave" then return GetConfig("useShockwave", true) end
        if key == "shockwaveEnemyCount" then return GetConfig("shockwaveEnemyCount", 2) end
        
        -- AOE阈值
        if key == "aoeThreshold4" then return GetConfig("aoeThreshold4", 4) end
        if key == "aoeThreshold5" then return GetConfig("aoeThreshold5", 5) end
        
        -- 调试
        if key == "debug" then return GetConfig("debug", false) end
        
        -- 手动爆发开关
        if key == "manualCooldownsEnabled" then return true end
        
        return nil
    end
})

------------------------------------------------------------------------
-- 辅助函数
------------------------------------------------------------------------

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 打断辅助函数 - 已移至 Interface.lua
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 所有打断逻辑现在由 Interface.lua 的回调统一处理

-- Aurora 爆发开关检查函数
local function ShouldUseCooldowns()
    -- 1. 检查预留爆发选项
    -- 如果开启了"预留爆发"，且周围敌人数量 <= 2，则不使用爆发技能
    -- 但是Boss除外（Boss战始终可以使用爆发）
    if cfg.reserveBurst then
        local enemies = player.enemiesaround(8) or 0
        if enemies <= 2 then
            -- 检查当前目标是否为Boss（使用Aurora标准方法）
            -- target.isboss: 单位是否是Boss
            local isBoss = target and target.exists and target.isboss
            
            -- 如果不是Boss，则不使用爆发（保留爆发）
            if not isBoss then
                return false
            end
        end
    end
    
    -- 2. 优先使用 Aurora 内置的 Cooldown Toggle
    if Aurora.Rotation and Aurora.Rotation.Cooldown then
        return Aurora.Rotation.Cooldown:GetValue()
    end
    
    -- 3. 备用：检查 Aurora.UseCooldowns
    if Aurora and Aurora.UseCooldowns ~= nil then
        return Aurora.UseCooldowns
    end
    
    -- 4. 最后备用：使用手动配置
    return cfg.manualCooldownsEnabled
end

-- Aurora 中断开关检查函数
local function ShouldUseInterrupt()
    -- 优先使用 Aurora 内置的 Interrupt Toggle
    if Aurora.Rotation and Aurora.Rotation.Interrupt then
        return Aurora.Rotation.Interrupt:GetValue()
    end
    
    -- 备用：使用手动配置
    return cfg.useInterrupt
end

local function log(msg)
    if cfg.debug then 
        print("|cff00ff00[TT狂战]|r " .. tostring(msg)) 
    end
end


------------------------------------------------------------------------
-- 物品 ID 定义
------------------------------------------------------------------------
local ITEM_IDS = {
    -- 治疗石
    Healthstone = 5512,
    HealthstoneDemon = 224464, -- 恶魔治疗石（备用）
    
    -- 阿加治疗药水（按品质从高到低）
    HealingPotion = {
        211880, -- 史诗品质
        211879, -- 稀有品质
        211878, -- 优秀品质
    },
    
    -- 爆发药水（按品质从高到低）
    CombatPotion = {
        212265, -- 史诗品质
        212264, -- 稀有品质
        212263, -- 优秀品质
    },
}

------------------------------------------------------------------------
-- 工具函数 (使用 Aurora 标准方法)
------------------------------------------------------------------------

-- 使用物品的辅助函数
local function UseItem(itemId)
    if not itemId then return false end
    
    -- 检查物品是否存在且可用
    if GetItemCount(itemId) > 0 and GetItemCooldown(itemId) == 0 then
        UseItemByName(itemId)
        return true
    end
    return false
end

-- 使用治疗石
local function UseHealthstone()
    if not cfg.useHealthstone then return false end
    if player.healthpercent > cfg.healthstoneThreshold then return false end
    
    -- 优先使用普通治疗石
    if UseItem(ITEM_IDS.Healthstone) then
        log("使用治疗石")
        return true
    end
    
    -- 备用：恶魔治疗石
    if UseItem(ITEM_IDS.HealthstoneDemon) then
        log("使用恶魔治疗石")
        return true
    end
    
    return false
end

-- 使用治疗药水（按品质从高到低尝试）
local function UseHealingPotion()
    if not cfg.useHealingPotion then return false end
    if player.healthpercent > cfg.healingPotionThreshold then return false end
    
    for _, potionId in ipairs(ITEM_IDS.HealingPotion) do
        if UseItem(potionId) then
            log("使用阿加治疗药水 (ID: " .. potionId .. ")")
            return true
        end
    end
    
    return false
end

-- 使用爆发药水（按品质从高到低尝试）
local function UseCombatPotion()
    -- 检查是否在战斗中
    if not player.combat then return false end
    
    for _, potionId in ipairs(ITEM_IDS.CombatPotion) do
        if UseItem(potionId) then
            log("使用爆发药水 (ID: " .. potionId .. ")")
            return true
        end
    end
    
    return false
end

------------------------------------------------------------------------
-- 饰品引导追踪（防止打断1秒引导）
------------------------------------------------------------------------

local trinketChannelingUntil = 0  -- 引导结束时间
local trinketChannelDuration = 1.2  -- 引导时长 + 缓冲（1秒引导 + 0.2秒缓冲）

-- 检查饰品是否正在引导
local function IsTrinketChanneling()
    return GetTime() < trinketChannelingUntil
end

-- 设置饰品引导状态
local function SetTrinketChanneling()
    trinketChannelingUntil = GetTime() + trinketChannelDuration
    if cfg.debug then
        log("|cffff8800[等待]|r 饰品引导中，" .. trinketChannelDuration .. "秒内不使用其他技能")
    end
end

------------------------------------------------------------------------
-- 饰品使用函数 (基于 Aurora ItemHandler - 修复版)
------------------------------------------------------------------------

-- 获取饰品名称（用于调试，处理缓存延迟）
local function GetTrinketName(slotID)
    local itemLink = GetInventoryItemLink("player", slotID)
    if itemLink then
        local name = GetItemInfo(itemLink)
        if name and name ~= "" then
            return name
        end
        -- 如果名称未缓存，从物品链接提取（备用方案）
        local extractedName = itemLink:match("%[(.+)%]")
        if extractedName then
            return extractedName
        end
        return "加载中..."
    end
    return "未装备"
end

-- 获取饰品物品ID
local function GetTrinketItemID(slotID)
    return GetInventoryItemID("player", slotID)
end

-- 使用饰品1（每次动态创建，支持引导类饰品）
local function UseTrinket1()
    if not cfg.useTrinket1 then return false end
    if not player or not player.combat then return false end
    
    -- 检查玩家是否正在施法或引导（引导类饰品需要）
    if player.casting or player.channeling then
        if cfg.debug then
            log("|cffffff00[跳过]|r 饰品1 - 正在施法/引导")
        end
        return false
    end
    
    -- 检查 Aurora.ItemHandler
    if not Aurora or not Aurora.ItemHandler then
        if cfg.debug then
            log("|cffff0000[错误]|r Aurora.ItemHandler 不存在")
        end
        return false
    end
    
    -- 获取饰品物品ID
    local itemID = GetTrinketItemID(13)
    if not itemID then
        if cfg.debug then
            log("|cffffff00[警告]|r 饰品1槽位为空")
        end
        return false
    end
    
    -- 特殊处理：跳过只能对队友使用的饰品（需要玩家手动使用）
    -- 索·莉亚的究极秘术 (只能对其他队友使用，循环会跳过)
    local friendOnlyTrinkets = {
        [190958] = true,  -- 索·莉亚的究极秘术 ⭐正确ID
        [219917] = true,  -- 索·莉亚的究极秘术（旧ID-史诗）
        [219915] = true,  -- 索·莉亚的究极秘术（旧ID-普通）
        [219916] = true,  -- 索·莉亚的究极秘术（旧ID-英雄）
        [219918] = true,  -- 索·莉亚的究极秘术（旧ID-神话）
    }
    
    if friendOnlyTrinkets[itemID] then
        if cfg.debug then
            local name = GetTrinketName(13) or "饰品1"
            log("|cffffff00[跳过]|r 饰品1: " .. name .. " (ID: " .. itemID .. ") - 需要玩家手动对队友使用")
        end
        return false
    end
    
    -- 动态创建饰品对象
    local trinket = Aurora.ItemHandler.NewItem(itemID)
    if not trinket then
        if cfg.debug then
            log("|cffff0000[错误]|r 无法创建饰品1对象 (ID: " .. itemID .. ")")
        end
        return false
    end
    
    -- 使用 Aurora ItemHandler 的智能检查
    -- 优先尝试对自己使用（增益类饰品）
    if trinket:usable(player) then
        local success = trinket:use(player)
        
        if success then
            SetTrinketChanneling()
            
            if cfg.debug then
                local name = GetTrinketName(13) or "饰品1"
                log("|cff00ff00✓|r 使用饰品1: " .. name .. " (ID: " .. itemID .. ")")
            end
            
            return true
        end
    end
    
    -- 备选：对当前目标使用（伤害类饰品）
    if target and target.exists and trinket:usable(target) then
        local success = trinket:use(target)
        
        if success then
            SetTrinketChanneling()
            
            if cfg.debug then
                local name = GetTrinketName(13) or "饰品1"
                log("|cff00ff00✓|r 使用饰品1: " .. name .. " (ID: " .. itemID .. ") [对目标]")
            end
            
            return true
        end
    end
    
    -- 静默失败，不影响循环
    return false
end

-- 使用饰品2（每次动态创建，支持引导类饰品）
local function UseTrinket2()
    if not cfg.useTrinket2 then return false end
    if not player or not player.combat then return false end
    
    -- 检查玩家是否正在施法或引导（引导类饰品需要）
    if player.casting or player.channeling then
        if cfg.debug then
            log("|cffffff00[跳过]|r 饰品2 - 正在施法/引导")
        end
        return false
    end
    
    -- 检查 Aurora.ItemHandler
    if not Aurora or not Aurora.ItemHandler then
        if cfg.debug then
            log("|cffff0000[错误]|r Aurora.ItemHandler 不存在")
        end
        return false
    end
    
    -- 获取饰品物品ID
    local itemID = GetTrinketItemID(14)
    if not itemID then
        if cfg.debug then
            log("|cffffff00[警告]|r 饰品2槽位为空")
        end
        return false
    end
    
    -- 特殊处理：跳过只能对队友使用的饰品（需要玩家手动使用）
    -- 索·莉亚的究极秘术 (只能对其他队友使用，循环会跳过)
    local friendOnlyTrinkets = {
        [190958] = true,  -- 索·莉亚的究极秘术 ⭐正确ID
        [219917] = true,  -- 索·莉亚的究极秘术（旧ID-史诗）
        [219915] = true,  -- 索·莉亚的究极秘术（旧ID-普通）
        [219916] = true,  -- 索·莉亚的究极秘术（旧ID-英雄）
        [219918] = true,  -- 索·莉亚的究极秘术（旧ID-神话）
    }
    
    if friendOnlyTrinkets[itemID] then
        if cfg.debug then
            local name = GetTrinketName(14) or "饰品2"
            log("|cffffff00[跳过]|r 饰品2: " .. name .. " (ID: " .. itemID .. ") - 需要玩家手动对队友使用")
        end
        return false
    end
    
    -- 动态创建饰品对象
    local trinket = Aurora.ItemHandler.NewItem(itemID)
    if not trinket then
        if cfg.debug then
            log("|cffff0000[错误]|r 无法创建饰品2对象 (ID: " .. itemID .. ")")
        end
        return false
    end
    
    -- 使用 Aurora ItemHandler 的智能检查
    -- 优先尝试对自己使用（增益类饰品）
    if trinket:usable(player) then
        local success = trinket:use(player)
        
        if success then
            SetTrinketChanneling()
            
            if cfg.debug then
                local name = GetTrinketName(14) or "饰品2"
                log("|cff00ff00✓|r 使用饰品2: " .. name .. " (ID: " .. itemID .. ")")
            end
            
            return true
        end
    end
    
    -- 备选：对当前目标使用（伤害类饰品）
    if target and target.exists and trinket:usable(target) then
        local success = trinket:use(target)
        
        if success then
            SetTrinketChanneling()
            
            if cfg.debug then
                local name = GetTrinketName(14) or "饰品2"
                log("|cff00ff00✓|r 使用饰品2: " .. name .. " (ID: " .. itemID .. ") [对目标]")
            end
            
            return true
        end
    end
    
    -- 静默失败，不影响循环
    return false
end

-- 检测是否是训练假人（优化版，避免访问不存在的属性）
local dummyCache = {}  -- 缓存假人检测结果
local function IsTrainingDummy(unit)
    if not unit or not unit.exists then return false end
    
    -- 使用 GUID 缓存结果，避免重复检测
    local guid = unit.guid
    if guid and dummyCache[guid] ~= nil then
        return dummyCache[guid]
    end
    
    -- 通过名字检测（最可靠的方法）
    local name = unit.name or ""
    local dummyKeywords = {
        "训练假人", "Training Dummy", "Target Dummy", "Raider's Training Dummy",
        "试炼假人", "木桩", "Striking Dummy", "Cleave Training Dummy",
        "测试假人", "PvP Training Dummy", "Dungeoneer's Training Dummy",
        "Dummy", "假人"
    }
    
    for _, keyword in ipairs(dummyKeywords) do
        if name:find(keyword) then
            if guid then dummyCache[guid] = true end
            return true
        end
    end
    
    -- 不是假人
    if guid then dummyCache[guid] = false end
    return false
end

-- 检查是否应该使用中断
local function ShouldUseInterrupt()
    -- 优先使用 Aurora 内置的 Interrupt Toggle
    if Aurora.Rotation and Aurora.Rotation.Interrupt then
        return Aurora.Rotation.Interrupt:GetValue()
    end
    
    -- 备用：使用手动配置
    return cfg.useInterrupt
end

-- 中断检测函数
local function ShouldInterrupt(unit)
    if not ShouldUseInterrupt() then return false end
    if not unit or not unit.exists or not unit.alive then return false end
    
    -- 检查目标是否在施法
    local isCasting = unit.casting or unit.channeling
    if not isCasting then return false end
    
    -- 检查是否可中断
    local isInterruptible = unit.castinginterruptible or unit.channelinginterruptible
    if not isInterruptible then return false end
    
    -- 如果启用列表检查
    if cfg.interruptWithList and Aurora.Lists and Aurora.Lists.InterruptSpells then
        local spellId = unit.castingspellid or unit.channelingspellid
        if spellId then
            -- 检查技能是否在中断列表中
            for _, interruptSpellId in ipairs(Aurora.Lists.InterruptSpells) do
                if spellId == interruptSpellId then
                    if cfg.debug then
                        log(string.format("检测到需要中断的技能: %d", spellId))
                    end
                    return true
                end
            end
            -- 不在列表中，不中断
            return false
        end
    end
    
    -- 如果不使用列表，中断所有可中断技能
    return not cfg.interruptWithList
end

-- 战斗时间追踪
local combatStartTime = 0

local function UpdateCombatTime()
    if player.combat then
        if combatStartTime == 0 then
            combatStartTime = GetTime()
        end
    else
        combatStartTime = 0
        -- 打断计时由 Interface.lua 管理
    end
end

local function GetCombatTime()
    if not player.combat then return 0 end
    return GetTime() - combatStartTime
end

-- ✅ 优化：Whirlwind 改用 Aurora 内置的 timeSinceLastCast() 方法
-- 不再需要手动追踪 lastWhirlwindTime 和 whirlwindGCD

------------------------------------------------------------------------
-- 自动目标切换系统
------------------------------------------------------------------------
-- 当当前目标不在攻击范围时，自动切换到最近的可攻击目标

local function AutoTargetSwitch()
    -- 检查状态栏按钮是否启用（优先）
    if Aurora.Rotation.AutoTargetToggle and not Aurora.Rotation.AutoTargetToggle:GetValue() then
        return false
    end
    
    -- 备用：检查配置是否启用
    if not Aurora.Rotation.AutoTargetToggle and not cfg.autoTarget then
        return false
    end
    
    -- 获取配置的近战范围（默认8码）
    local meleeRange = cfg.autoTargetRange or 8
    
    -- 如果当前目标存在、存活、是敌人，且在近战范围内，不切换
    if target.exists and target.alive and target.enemy and player.melee(target) then
        return false
    end
    
    -- 当前目标不在近战范围内，查找近战范围内最近的敌人
    local nearestEnemy = nil
    local nearestDistance = 999
    
    Aurora.activeenemies:each(function(enemy)
        if enemy.exists and enemy.alive and enemy.enemy then
            local distance = enemy.distanceto(player)
            
            -- 查找近战范围内最近的敌人（带视线检测）
            if distance <= meleeRange and enemy.los and distance < nearestDistance then
                nearestEnemy = enemy
                nearestDistance = distance
            end
        end
    end)
    
    -- 如果找到了近战范围内的敌人，切换目标
    if nearestEnemy then
        -- 避免切换到当前目标
        if target.exists and nearestEnemy.guid == target.guid then
            return false
        end
        
        if cfg.debug then
            log(string.format("🎯 【自动目标】切换到 %s (距离: %.1f码)", 
                nearestEnemy.name or "未知", nearestDistance))
        end
        
        player.settarget(nearestEnemy)
        return true
    end
    
    -- 如果没找到近战范围内的敌人，记录日志
    if cfg.debug and (not target.exists or not target.alive or not player.melee(target)) then
        log(string.format("🎯 【自动目标】未找到%d码近战范围内的可攻击敌人", meleeRange))
    end
    
    return false
end

------------------------------------------------------------------------
-- 猝死判断逻辑
------------------------------------------------------------------------

-- 猝死四要素 (5目标及以上)
local function SuddenDeath4Factors()
    if not player.aura(A.SuddenDeath) then return false end
    
    local markStacks = target.auracount(A.ExecutionersWill) or 0
    local sdStacks = player.auracount(A.SuddenDeath) or 0
    local sdRemains = player.auraremains(A.SuddenDeath) or 0
    local bladestormCD = S.Bladestorm:getcd() or 0
    
    -- 因素1: 3层印记
    if markStacks >= 3 then return true end
    
    -- 因素2: 2层猝死
    if sdStacks >= 2 then return true end
    
    -- 因素3: 猝死即将消失 (1.5秒内)
    if sdRemains > 0 and sdRemains <= 1.5 then return true end
    
    -- 因素4: 风车CD好了，消化印记
    if bladestormCD == 0 and markStacks > 0 and markStacks < 3 then
        return true
    end
    
    return false
end

-- 猝死五要素 (4目标及以下)
local function SuddenDeath5Factors()
    if not player.aura(A.SuddenDeath) then return false end
    
    local markStacks = target.auracount(A.ExecutionersWill) or 0
    local sdStacks = player.auracount(A.SuddenDeath) or 0
    local sdRemains = player.auraremains(A.SuddenDeath) or 0
    local bladestormCD = S.Bladestorm:getcd() or 0
    
    -- 因素1: 2层印记
    if markStacks >= 2 then return true end
    
    -- 因素2: 2层猝死
    if sdStacks >= 2 then return true end
    
    -- 因素3: 猝死即将消失
    if sdRemains > 0 and sdRemains <= 1.5 then return true end
    
    -- 因素4: 灰烬主宰即将消失
    local ajRemains = player.auraremains(A.AshenJuggernaut) or 0
    if ajRemains > 0 and ajRemains <= 1.0 then
        return true
    end
    
    -- 因素5: 风车前消化印记
    if bladestormCD == 0 and markStacks > 0 and markStacks < 2 then
        return true
    end
    
    return false
end

-- 打印记怪收尾
local function ShouldFinishWithExecute()
    if not target or not target.exists then return false end
    
    local targetHP = target.healthpercent or 100
    local markStacks = target.auracount(A.ExecutionersWill) or 0
    local bladestormCD = S.Bladestorm:getcd() or 0
    
    return targetHP <= 15 and markStacks >= 1 and bladestormCD > 3
end

------------------------------------------------------------------------
-- 法术反射逻辑
------------------------------------------------------------------------
-- 重要区分：
-- 1. 反射是否启用 → 只受 cfg.useSpellReflection 控制（独立于打断总开关）
-- 2. 打断是否会执行 → 需要检查打断总开关 + 打断技能状态（用于判断优先级）
--
-- 逻辑：
-- - 关闭Interrupt按钮 → 打断不会执行 → 反射补位
-- - 开启Interrupt按钮 + 打断技能可用 → 打断会执行 → 不反射，优先打断
-- - 开启Interrupt按钮 + 打断技能CD → 打断不会执行 → 反射补位

------------------------------------------------------------------------
-- 技能回调 (简化版，按照 Aurora 文档建议)
------------------------------------------------------------------------

------------------------------------------------------------------------
-- 中断技能回调 - 已移至 Interface.lua
------------------------------------------------------------------------
-- 打断逻辑现在完全由 Interface.lua 的回调处理
-- 这里不再定义任何打断回调，避免冲突

-- 胜利在望（优先级高于狂暴回复，因为恢复更多）
S.VictoryRush:callback(function(spell)
    if not cfg.useVictoryRush then return false end
    
    -- 检查血量是否低于阈值
    if player.healthpercent <= cfg.victoryRushThreshold then
        if cfg.debug then
            log(string.format("💚 [胜利在望] 血量: %d%% (阈值: %d%%)", 
                math.floor(player.healthpercent), 
                cfg.victoryRushThreshold))
        end
        return spell:cast(player)
    end
    
    return false
end)

-- 法术反射 - 智能逻辑：打断CD或关闭时才反射
S.SpellReflection:callback(function(spell)
    if not cfg.useSpellReflection then 
        if cfg.debug then log("🚫 [反射] 功能已禁用") end
        return false 
    end
    
    if not spell:ready() then 
        if cfg.debug then log("🚫 [反射] CD未就绪") end
        return false 
    end
    
    -- 战斗时间延迟（避免刚开战就触发）
    local combatTime = player.timecombat or 0
    if combatTime < 3 then 
        if cfg.debug then 
            log(string.format("🚫 [反射] 战斗时间%.1f秒 < 3秒", combatTime))
        end
        return false 
    end
    
    -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    -- 第1步：先找有没有需要反射的目标
    -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    local debugInfo = {}
    local reflectTarget = Aurora.activeenemies:first(function(enemy)
        -- 基础检查
        if not enemy.exists or not enemy.alive or not enemy.enemy then 
            return false 
        end
        
        local dist = enemy.distanceto(player)
        if dist > 40 then 
            return false 
        end
        
        -- 施法检查（怪物还在读条，说明队友没打断）
        -- 严格检查：必须是字符串类型且不为空
        local isCasting = enemy.casting
        local isChanneling = enemy.channeling
        
        -- 类型和值检查
        local hasCasting = (type(isCasting) == "string" and isCasting ~= "")
        local hasChanneling = (type(isChanneling) == "string" and isChanneling ~= "")
        
        if not hasCasting and not hasChanneling then 
            return false 
        end
        
        -- 【关键】检查施法目标是否是玩家本人
        local castTarget = enemy.casttarget
        if not castTarget or not castTarget.exists then 
            if cfg.debug then
                table.insert(debugInfo, string.format("%s 无施法目标", enemy.name or "未知"))
            end
            return false 
        end
        
        if not player.isunit(castTarget) then 
            local targetName = castTarget.name or "未知"
            if cfg.debug then
                table.insert(debugInfo, string.format("%s 对%s施法（不是我）", enemy.name or "未知", targetName))
            end
            return false 
        end
        
        -- 施法进度检查（严格：必须有有效的进度值）
        local castPct = (hasCasting and enemy.castingpct) or (hasChanneling and enemy.channelingpct) or 0
        
        -- 验证进度值的有效性
        if type(castPct) ~= "number" or castPct <= 0 then
            if cfg.debug then
                table.insert(debugInfo, string.format("%s 施法进度无效", enemy.name or "未知"))
            end
            return false
        end
        
        local threshold = math.max(30, cfg.spellReflectionCastPercent or 60)  -- 最低30%
        if castPct < threshold then 
            if cfg.debug then
                table.insert(debugInfo, string.format("%s 施法进度%.1f%% < %d%%", enemy.name or "未知", castPct, threshold))
            end
            return false 
        end
        
        -- 找到符合条件的目标！
        if cfg.debug then
            local spellName = hasCasting and isCasting or isChanneling
            log(string.format("✅ [反射目标] %s 对我施法: %s (进度%.1f%%)", 
                enemy.name or "未知", spellName or "未知", castPct))
        end
        return true
    end)
    
    -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    -- 第2步：如果没找到反射目标，直接返回
    -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    if not reflectTarget then
        if cfg.debug and #debugInfo > 0 then
            log("❌ [反射] 没有找到有效的反射目标:")
            for _, info in ipairs(debugInfo) do
                log("   • " .. info)
            end
        end
        return false
    end
    
    -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    -- 第3步：检查这个目标的读条进度是否达到打断阈值
    -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    -- 重要：反射系统独立于打断总开关，只检查各个打断技能的状态
    local isCasting = reflectTarget.casting
    local castPct = isCasting and reflectTarget.castingpct or reflectTarget.channelingpct or 0
    local interruptThreshold = cfg.interruptCastPercent or 60
    local reflectThreshold = math.max(30, cfg.spellReflectionCastPercent or 60)
    
    -- 如果读条进度已达到打断阈值，检查打断系统是否会真的执行
    if castPct >= interruptThreshold then
        -- 🔍 关键逻辑：
        -- 1. 反射是否启用 → 只受 cfg.useSpellReflection 控制（不受打断总开关影响）
        -- 2. 打断是否会执行 → 需要检查打断总开关 + 打断技能状态（用于决定是否让打断优先）
        
        -- 检查打断系统总开关
        local interruptSystemEnabled = ShouldUseInterrupt()
        
        if not interruptSystemEnabled then
            -- 打断系统总开关关闭 → 打断不会执行 → 反射补位
            if cfg.debug then
                log(string.format("✅ [反射] 进度%.1f%%>=打断阈值%d%%，但打断系统已关闭", castPct, interruptThreshold))
            end
        else
            -- 打断系统开启 → 检查各个打断技能是否【启用且就绪】
            local pummelAvailable = cfg.usePummel and S.Pummel and S.Pummel:ready()
            local stormBoltAvailable = cfg.useStormBolt and S.StormBolt and S.StormBolt:ready()
            local shockwaveAvailable = cfg.useShockwave and S.Shockwave and S.Shockwave:ready()
            
            if pummelAvailable or stormBoltAvailable or shockwaveAvailable then
                -- 打断系统开启 + 打断技能可用 → 打断会执行 → 不反射，优先打断
                if cfg.debug then
                    local available = {}
                    if pummelAvailable then table.insert(available, "拳击") end
                    if stormBoltAvailable then table.insert(available, "风暴之锤") end
                    if shockwaveAvailable then table.insert(available, "震荡波") end
                    log(string.format("🚫 [反射] 进度%.1f%%>=打断阈值%d%%，打断系统开启且技能可用(%s)，优先打断", 
                        castPct, interruptThreshold, table.concat(available, ",")))
                end
                return false
            else
                -- 打断系统开启，但所有打断技能CD/关闭 → 打断不会执行 → 反射补位
                if cfg.debug then
                    log(string.format("✅ [反射] 进度%.1f%%>=打断阈值%d%%，但打断技能CD/关闭", castPct, interruptThreshold))
                end
            end
        end
    else
        -- 读条进度未达到打断阈值，但达到反射阈值 → 直接用反射
        if cfg.debug then
            log(string.format("✅ [反射] 进度%.1f%%<打断阈值%d%%，但>=反射阈值%d%%，用反射补位", 
                castPct, interruptThreshold, reflectThreshold))
        end
    end
    
    -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    -- 第4步：最终安全检查 - 在cast前再次验证目标状态
    -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    -- 检查目标是否还存在且在施法
    if not reflectTarget.exists or not reflectTarget.alive then
        if cfg.debug then log("❌ [反射] 目标已消失或死亡") end
        return false
    end
    
    -- 再次检查施法状态（避免时间差导致状态改变）
    local finalCasting = reflectTarget.casting
    local finalChanneling = reflectTarget.channeling
    local hasFinalCasting = (type(finalCasting) == "string" and finalCasting ~= "")
    local hasFinalChanneling = (type(finalChanneling) == "string" and finalChanneling ~= "")
    
    if not hasFinalCasting and not hasFinalChanneling then
        if cfg.debug then log("❌ [反射] 目标已停止施法") end
        return false
    end
    
    -- 再次检查施法目标
    local finalCastTarget = reflectTarget.casttarget
    if not finalCastTarget or not finalCastTarget.exists or not player.isunit(finalCastTarget) then
        if cfg.debug then log("❌ [反射] 施法目标已改变") end
        return false
    end
    
    -- 所有检查通过，执行反射
    local spellName = hasFinalCasting and finalCasting or finalChanneling
    if cfg.debug then
        log(string.format(
            "🛡️ [反射执行] %s 对我施法: %s (进度%.1f%%)", 
            reflectTarget.name or "未知",
            spellName or "未知",
            castPct
        ))
    end
    return spell:cast(player)
end)

-- 狂暴回复
S.EnragingRegeneration:callback(function(spell)
    if not cfg.useEnragingRegeneration then return false end
    if player.healthpercent <= cfg.enragingRegenerationThreshold then
        return spell:cast(player)
    end
end)

-- 🎯 智能大技能判断函数
-- 判断是否应该使用大技能（考虑群体数量、单位类型、TTD）
local function ShouldUseMajorCooldown(ttdThreshold)
    -- 训练假人：无限制使用
    if IsTrainingDummy(target) then
        return true
    end
    
    -- 🎯 检查是否在近战范围内
    if not player.melee(target) then
        return false
    end
    
    -- 🎯 检查目标存活时间（TTD）
    local ttd = target.ttd or 999
    if ttd > 0 and ttd < ttdThreshold then
        return false
    end
    
    -- 🎯 检查周围敌人数量
    local enemies = player.enemiesaround(8) or 0
    
    -- 群体场景（3个或以上怪物）：值得开大招
    if enemies >= 3 then
        return true
    end
    
    -- 单体或少量怪物（1-2个）：只对BOSS/精英使用
    -- 检查目标是否是 BOSS 或精英怪
    local isBoss = target.isboss or false
    
    -- 如果是BOSS，直接返回true
    if isBoss then
        return true
    end
    
    -- 对于非BOSS的目标，检查是否是精英或稀有怪
    -- 通过血量判断：普通小怪血量通常较低，精英怪血量较高
    local maxHealth = target.healthmax or 0
    local playerMaxHealth = player.healthmax or 1
    
    -- 如果目标最大血量 > 玩家最大血量的3倍，认为是精英/稀有怪
    if maxHealth > (playerMaxHealth * 3) then
        return true
    end
    
    -- 其他情况（普通小怪）：不使用大技能
    return false
end

------------------------------------------------------------------------
-- 智能打断系统
------------------------------------------------------------------------

-- 检查打断开关状态
local function IsInterruptEnabled()
    if not Aurora or not Aurora.Rotation then
        return true -- Aurora不存在时，默认启用
    end
    
    -- 尝试多个可能的Toggle名称
    local possibleNames = {
        "Interrupt",      -- 单数
        "Interrupts",     -- 复数
        "interrupt",      -- 小写
        "interrupts",     -- 小写复数
    }
    
    for _, name in ipairs(possibleNames) do
        local toggle = Aurora.Rotation[name]
        if toggle and type(toggle.GetValue) == "function" then
            local value = toggle:GetValue()
            if cfg.debug then
                log(string.format("🔍 [打断开关] 找到 Aurora.Rotation.%s = %s", name, tostring(value)))
            end
            return value
        end
    end
    
    -- 如果找不到任何interrupt按钮，默认启用
    if cfg.debug then
        log("⚠️ [打断开关] 未找到任何Interrupt Toggle，默认启用")
    end
    return true
end

-- 检查最近是否使用了延迟打断技能（防止技能浪费）
local function HasRecentDelayedInterrupt()
    -- 震荡波：10码AOE，有延迟（需要1.5秒等待打中）
    local shockwaveDelay = 1.5
    if S.Shockwave and S.Shockwave:timeSinceLastCast() < shockwaveDelay then
        if cfg.debug then
            log(string.format("⏱️ 震荡波刚释放 %.1f秒前，等待打中", S.Shockwave:timeSinceLastCast()))
        end
        return true
    end
    
    -- 风暴之锤：40码远程，有飞行时间（需要1秒等待打中）
    local stormBoltDelay = 1.0
    if S.StormBolt and S.StormBolt:timeSinceLastCast() < stormBoltDelay then
        if cfg.debug then
            log(string.format("⏱️ 风暴之锤刚释放 %.1f秒前，等待打中", S.StormBolt:timeSinceLastCast()))
        end
        return true
    end
    
    return false
end

-- 检查技能是否应该被中断（使用 Aurora 列表）
local function ShouldInterruptSpell(spellId)
    -- 如果不使用列表，中断所有
    if not cfg.interruptWithList then
        return true
    end
    
    -- 检查列表是否存在
    if not Aurora.Lists or not Aurora.Lists.InterruptSpells then
        return true -- 列表不存在，安全起见中断所有
    end
    
    -- 列表为空，中断所有
    if #Aurora.Lists.InterruptSpells == 0 then
        return true
    end
    
    -- 检查 spellId 是否在列表中
    if not spellId then
        return false
    end
    
    for _, interruptSpellId in ipairs(Aurora.Lists.InterruptSpells) do
        if spellId == interruptSpellId then
            return true
        end
    end
    
    return false -- 不在列表中
end

-- 检查目标是否需要中断（按文档最佳实践）
local function TargetNeedsInterrupt()
    -- 按照文档示例：简洁的链式检查
    -- 文档示例：if target.exists and target.casting then
    if not target.exists then return false, nil end
    if not target.alive then return false, nil end
    if not target.enemy then return false, nil end
    
    -- 检查是否在施法（普通施法或引导）
    local isCasting = target.casting
    local isChanneling = target.channeling
    if not isCasting and not isChanneling then return false, nil end
    
    -- 检查是否可中断
    local isInterruptible = isCasting and target.castinginterruptible or target.channelinginterruptible
    if not isInterruptible then return false, nil end
    
    -- 获取施法的技能ID
    local spellId = isCasting and target.castingspellid or target.channelingspellid
    
    -- 列表检查（如果启用）
    if not ShouldInterruptSpell(spellId) then
        return false, spellId
    end
    
    -- 施法进度检查（文档示例：target.castingpct > 50）
    local castPercent = isCasting and target.castingpct or target.channelingpct
    local threshold = cfg.interruptCastPercent or 60
    
    if castPercent and castPercent >= threshold then
        return true, spellId
    end
    
    return false, nil
end

-- 🎯 智能查找需要打断的目标（混合模式）
-- 优先级1: 当前选中的目标
-- 优先级2: 附近40码内正在施法的敌人
local function FindInterruptTarget()
    -- 优先级1: 检查当前选中的目标
    if target.exists and target.enemy and target.alive then
        local needsInt, spellId = TargetNeedsInterrupt()
        if needsInt then
            if cfg.debug then
                log(string.format("🎯 打断当前目标: %s (ID:%s)", target.name, tostring(spellId)))
            end
            return target, spellId
        end
    end
    
    -- 优先级2: 扫描附近40码内正在施法的敌人
    local interruptTarget = Aurora.activeenemies:first(function(enemy)
        -- 基础检查
        if not enemy.exists or not enemy.alive or not enemy.enemy then
            return false
        end
        
        -- 检查是否在施法
        local isCasting = enemy.casting or enemy.channeling
        if not isCasting then return false end
        
        -- 检查是否可中断
        local isInterruptible = enemy.castinginterruptible or enemy.channelinginterruptible
        if not isInterruptible then return false end
        
        -- 检查距离（40码内）
        if enemy.distanceto(player) > 40 then return false end
        
        -- 检查施法进度
        local castPct = enemy.castingpct or enemy.channelingpct or 0
        if castPct < (cfg.interruptCastPercent or 60) then
            return false
        end
        
        -- 检查列表
        local spellId = enemy.castingspellid or enemy.channelingspellid
        if cfg.interruptWithList then
            if not ShouldInterruptSpell(spellId) then
                return false
            end
        end
        
        return true
    end)
    
    if interruptTarget then
        local spellId = interruptTarget.castingspellid or interruptTarget.channelingspellid
        if cfg.debug then
            log(string.format("🔍 找到附近需要打断的敌人: %s (ID:%s)", interruptTarget.name, tostring(spellId)))
        end
        return interruptTarget, spellId
    end
    
    return nil, nil
end

-- 统计正在读条且可打断的敌人数量
local function CountCastingEnemies()
    local count = 0
    local castingEnemies = {}
    
    Aurora.activeenemies:each(function(enemy)
        if enemy.exists and enemy.alive and not enemy.dead then
            -- 检查是否在施法或引导
            local isCasting = enemy.casting or enemy.channeling
            local isInterruptible = enemy.castinginterruptible or enemy.channelinginterruptible
            
            if isCasting and isInterruptible then
                -- 检查施法进度是否达到阈值
                local castPct = enemy.castingpct or 0
                local minCastPct = cfg.interruptCastPercent or 60
                
                if castPct >= minCastPct then
                    -- ✅ 检查列表（如果启用）
                    local spellId = enemy.castingspellid or enemy.channelingspellid
                    if ShouldInterruptSpell(spellId) then
                        count = count + 1
                        table.insert(castingEnemies, enemy)
                    end
                end
            end
        end
    end)
    
    return count, castingEnemies
end

------------------------------------------------------------------------
-- 技能回调系统
------------------------------------------------------------------------

-- 拳击（主要中断，15秒CD，即时生效）
S.Pummel:callback(function(spell)
    -- 检查是否启用中断
    if not IsInterruptEnabled() or not cfg.usePummel then 
        return false 
    end
    
    -- ⏱️ 延迟检查：如果刚用过延迟打断技能，等待其生效
    if HasRecentDelayedInterrupt() then
        return false
    end
    
    -- 📊 检查读条怪物数量
    local castingCount = CountCastingEnemies()
    
    -- 🎯 多目标优先级：2+怪读条时，优先让震荡波AOE打断
    if castingCount >= 2 and cfg.useShockwave and S.Shockwave:ready() then
        if cfg.debug then
            log(string.format("⚡ 有%d个怪读条，优先使用震荡波AOE打断", castingCount))
        end
        return false -- 让震荡波去处理
    end
    
    -- 🎯 智能查找需要打断的目标（优先当前目标，然后扫描附近）
    local interruptTarget, spellId = FindInterruptTarget()
    if not interruptTarget then
        return false
    end
    
    if cfg.debug then
        log(string.format("✊ 拳击打断 %s (ID:%s)", interruptTarget.name, tostring(spellId)))
    end
    
    return spell:cast(interruptTarget)
end)

-- 风暴之锤（备用中断，30秒CD，远程40码，有飞行时间）
S.StormBolt:callback(function(spell)
    -- 检查是否启用
    if not IsInterruptEnabled() or not cfg.useStormBolt then 
        return false 
    end
    
    -- ⏱️ 延迟检查：如果刚用过震荡波，等待其生效
    if S.Shockwave and S.Shockwave:timeSinceLastCast() < 1.5 then
        if cfg.debug then
            log(string.format("⏱️ 震荡波刚释放，等待生效"))
        end
        return false
    end
    
    -- 📊 检查读条怪物数量
    local castingCount = CountCastingEnemies()
    
    -- 🎯 多目标优先级：2+怪读条时，优先让震荡波AOE打断
    if castingCount >= 2 and cfg.useShockwave and S.Shockwave:ready() then
        if cfg.debug then
            log(string.format("⚡ 有%d个怪读条，优先使用震荡波AOE打断", castingCount))
        end
        return false -- 让震荡波去处理
    end
    
    -- 检查拳击是否启用且可用（优先使用拳击）
    -- ⚠️ 必须同时检查配置开关和CD状态
    if cfg.usePummel and S.Pummel:ready() then
        return false -- 拳击启用且可用，让拳击去中断
    end
    
    -- 🎯 智能查找需要打断的目标
    local interruptTarget, spellId = FindInterruptTarget()
    if not interruptTarget then
        return false
    end
    
    -- Boss免疫风暴之锤（眩晕效果无效）
    if interruptTarget.isboss then
        return false
    end
    
    -- 检查敌人数量
    local enemies = player.enemiesaround(40) or 0
    if enemies < cfg.stormBoltEnemyCount then
        return false
    end
    
    if cfg.debug then
        log(string.format("⚡ 风暴之锤打断 %s (ID:%s)", interruptTarget.name, tostring(spellId)))
    end
    
    return spell:cast(interruptTarget)
end)

-- 震荡波（AOE中断，40秒CD，10码范围，有延迟）
S.Shockwave:callback(function(spell)
    -- 检查是否启用
    if not IsInterruptEnabled() or not cfg.useShockwave then 
        return false 
    end
    
    -- 📊 检查读条怪物数量
    local castingCount = CountCastingEnemies()
    
    -- 🎯 智能优先级判断
    -- 场景1: 2+怪读条 → 震荡波最优（AOE群体打断）
    if castingCount >= 2 then
        -- 找一个读条目标确认位置
        local interruptTarget = FindInterruptTarget()
        if interruptTarget then
            -- Boss免疫震荡波（眩晕效果无效）
            if not interruptTarget.isboss then
                -- 检查周围敌人数量
                local enemies = player.enemiesaround(10) or 0
                if enemies >= cfg.shockwaveEnemyCount then
                    if cfg.debug then
                        log(string.format("💥 震荡波AOE打断 - %d个怪读条，周围%d个敌人", castingCount, enemies))
                    end
                    return spell:cast(player) -- 震荡波是以玩家为中心的AOE
                end
            end
        end
    end
    
    -- 场景2: 单怪读条 → 作为兜底（拳击和风暴之锤都CD时）
    if castingCount >= 1 then
        -- 检查拳击和风暴之锤是否启用且可用
        local pummelAvailable = cfg.usePummel and S.Pummel:ready()
        local stormBoltAvailable = cfg.useStormBolt and S.StormBolt:ready()
        
        if pummelAvailable or stormBoltAvailable then
            return false -- 有其他中断技能可用，优先使用
        end
        
        -- 🎯 智能查找需要打断的目标
        local interruptTarget = FindInterruptTarget()
        if not interruptTarget then
            return false
        end
        
        -- Boss免疫震荡波（眩晕效果无效）
        if interruptTarget.isboss then
            return false
        end
        
        -- 检查周围敌人数量
        local enemies = player.enemiesaround(10) or 0
        if enemies >= cfg.shockwaveEnemyCount then
            if cfg.debug then
                log(string.format("💥 震荡波兜底打断 %s (ID:%s)", interruptTarget.name, tostring(FindInterruptTarget())))
            end
            return spell:cast(player)
        end
    end
    
    return false
end)

-- 鲁莽 (受 Aurora 爆发开关控制)
S.Recklessness:callback(function(spell)
    if not ShouldUseCooldowns() then return false end
    if not cfg.useRecklessness then return false end -- 单独开关
    
    -- 检查战斗状态（必须在战斗中）
    if not player.combat then return false end
    
    -- 检查目标有效性
    if not target.exists then return false end
    if not target.alive then return false end
    if not target.enemy then return false end
    
    -- 🎯 智能大技能判断
    local ttdThreshold = cfg.recklessnessTTD or 10
    if not ShouldUseMajorCooldown(ttdThreshold) then
        return false
    end
    
    return spell:cast(player)
end)

-- 天神下凡 (受 Aurora 爆发开关控制)
S.Avatar:callback(function(spell)
    if not ShouldUseCooldowns() then return false end
    if not cfg.useAvatar then return false end -- 单独开关
    
    -- 检查战斗状态（必须在战斗中）
    if not player.combat then return false end
    
    -- 检查目标有效性
    if not target.exists then return false end
    if not target.alive then return false end
    if not target.enemy then return false end
    
    -- 🎯 智能大技能判断
    local ttdThreshold = cfg.avatarTTD or 10
    if not ShouldUseMajorCooldown(ttdThreshold) then
        return false
    end
    
    return spell:cast(player)
end)

-- 剑刃风暴 (受 Aurora 爆发开关控制)
S.Bladestorm:callback(function(spell)
    if not ShouldUseCooldowns() then return false end
    if not cfg.useBladestorm then return false end -- 单独开关
    
    -- 检查战斗状态（必须在战斗中）
    if not player.combat then return false end
    
    -- 检查目标有效性
    if not target.exists then return false end
    if not target.alive then return false end
    if not target.enemy then return false end
    
    -- 🎯 智能大技能判断
    local ttdThreshold = cfg.bladestormTTD or 8
    if not ShouldUseMajorCooldown(ttdThreshold) then
        return false
    end
    
    return spell:cast(player)
end)

-- 雷鸣之吼 (只要激怒状态就可以使用，不受大技能开关影响)
S.ThunderousRoar:callback(function(spell)
    -- 必须在激怒状态下使用
    if not player.aura(A.Enrage) then
        return false
    end
    
    return spell:cast(player)  -- 雷鸣之吼是对自己施放的AOE技能
end)

-- 战斗怒吼 (队友增益BUFF，战斗外或BUFF消失时使用)
S.BattleShout:callback(function(spell)
    -- 如果手动禁用了战斗怒吼，则不使用
    if cfg.useBattleShout == false then
        return false
    end
    
    -- 🎯 智能检查：玩家或队友缺少BUFF时施放
    -- 检查玩家自己是否有BUFF
    if not player.aura(A.BattleShout) then
        if cfg.debug then
            log("🔔 战斗怒吼 - 玩家缺少BUFF")
        end
        return spell:cast(player)
    end
    
    -- 检查队友是否有人缺少BUFF（只在队伍中检查）
    if player.group then
        local needsBuff = false
        
        Aurora.fgroup:each(function(member)
            if member.exists and member.alive then
                -- 检查队友是否在40码内（战斗怒吼范围）
                if member.distanceto(player) <= 100 then
                    -- 检查队友是否有战斗怒吼BUFF
                    if not member.aura(A.BattleShout) then
                        needsBuff = true
                        if cfg.debug then
                            log(string.format("🔔 战斗怒吼 - 队友 %s 缺少BUFF", member.name))
                        end
                        return true  -- 找到缺buff的队友，跳出循环
                    end
                end
            end
            return false
        end)
        
        if needsBuff then
            return spell:cast(player)
        end
    end
    
    return false
end)

-- 旋风斩回调（根据Aurora文档优化 - AOE技能应检查周围敌人）
S.Whirlwind:callback(function(spell)
    -- ✅ 优化后：移除冗余检查，cast()会自动检查combat、exists等
    -- 单体时也可用作兜底技能，但要防止连续施放
    -- 使用 Aurora 内置的施法历史追踪，确保不会连续2次
    if spell:timeSinceLastCast() >= 1.5 then
        return spell:cast(player)
    end
    return false
end)

S.Rampage:callback(function(spell)
    return spell:cast(target)
end)

S.RagingBlow:callback(function(spell)
    return spell:cast(target)
end)

S.Execute:callback(function(spell)
    return spell:cast(target)
end)

S.Bloodthirst:callback(function(spell)
    return spell:cast(target)
end)

------------------------------------------------------------------------
-- SimC优化循环（基于SimulationCraft APL - Slayer天赋）
------------------------------------------------------------------------
local function SimCRotation()
    UpdateCombatTime()
    
    
    if player.dead then return false end
    
    -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    -- 【自动目标切换】当目标不存在或超出范围时，自动切换
    -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    AutoTargetSwitch()
    
    -- 检查目标有效性
    if not target or not target.exists or not target.alive or not target.enemy then
        return false
    end
    
    -- 获取战斗数据
    local enemies = player.enemiesaround(8) or 0
    local enrageUp = player.aura(A.Enrage) and true or false
    local enrageRem = player.auraremains(A.Enrage) or 0
    local rage = player.rage or 0
    local mcStacks = player.auracount(A.MeatCleaver) or 0
    local combatTime = GetCombatTime()
    local suddenDeathUp = player.aura(A.SuddenDeath) and true or false
    local executePhase = (target.healthpercent < 35) or (target.healthpercent < 20)
    
    -- ✅ 优化：预缓存天赋检查结果（减少循环中的 isknown() 调用）
    local hasMeatCleaver = S.MeatCleaver and S.MeatCleaver:isknown() or false
    local hasTitanicRage = S.TitanicRage and S.TitanicRage:isknown() or false
    local hasTenderize = S.Tenderize and S.Tenderize:isknown() or false
    local hasViciousContempt = S.ViciousContempt and S.ViciousContempt:isknown() or false
    local hasRecklessAbandon = S.RecklessAbandon and S.RecklessAbandon:isknown() or false
    local hasAngerManagement = S.AngerManagement and S.AngerManagement:isknown() or false
    local hasUproar = S.Uproar and S.Uproar:isknown() or false
    local hasBloodborne = S.Bloodborne and S.Bloodborne:isknown() or false
    
    if cfg.debug then
        local cdEnabled = ShouldUseCooldowns() and "开启" or "关闭"
        log(string.format("[SimC] 敌人=%d | 激怒=%s(%.1fs) | 怒气=%d | 猝死=%s | 爆发=%s", 
            enemies, tostring(enrageUp), enrageRem, rage, tostring(suddenDeathUp), cdEnabled))
    end
    
    -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    -- 【起手优化】斩鲜血肉天赋 - 优先使用嗜血触发激怒
    -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    -- ✅ 使用Aurora内置的timecombat属性（更可靠）
    local playerCombatTime = player.timecombat or 0
    
    if cfg.debug and playerCombatTime < 10 then
        log(string.format("🔍 【起手检测】战斗时间=%.1fs | 激怒=%s | 嗜血CD=%.1fs | ready=%s", 
            playerCombatTime, tostring(enrageUp), 
            S.Bloodthirst and S.Bloodthirst:getcd() or 0,
            S.Bloodthirst and S.Bloodthirst:ready() and "true" or "false"))
    end
    
    -- 战斗开始的前5秒，如果没有激怒BUFF，优先用嗜血触发激怒
    if playerCombatTime < 5 and not enrageUp and S.Bloodthirst and S.Bloodthirst:ready() then
        if cfg.debug then
            log("🔥 【起手】斩鲜血肉天赋 - 使用嗜血触发激怒")
        end
        if S.Bloodthirst:execute() then return true end
    end
    
    -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    -- 【最高优先级】打断系统
    -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    -- execute() 会触发在 Rotation.lua 中定义的 callback
    -- callback 中包含所有打断逻辑（开关检查、目标选择、列表检查等）
    if S.Pummel:execute() then return true end
    if S.StormBolt:execute() then return true end
    if S.Shockwave:execute() then return true end
    
    -- 防御技能（反射在打断之后）
    if S.SpellReflection:execute() then return true end
    
    -- 治疗
    if UseHealthstone() then return true end
    if UseHealingPotion() then return true end
    if S.VictoryRush:execute() then return true end
    if S.EnragingRegeneration:execute() then return true end
    
    -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    -- 饰品和药水（受爆发开关控制）
    -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    if ShouldUseCooldowns() then
        local recklessnessReady = S.Recklessness:ready() and cfg.useRecklessness
        local avatarReady = S.Avatar:ready() and cfg.useAvatar
        local bladestormReady = S.Bladestorm:ready() and cfg.useBladestorm
        local anyCooldownReady = recklessnessReady or avatarReady or bladestormReady
        
        local shouldUseMajorCooldown = false
        if anyCooldownReady then
            local minTTD = math.min(
                cfg.recklessnessTTD or 10,
                cfg.avatarTTD or 10,
                cfg.bladestormTTD or 8
            )
            shouldUseMajorCooldown = ShouldUseMajorCooldown(minTTD)
        end
        
        -- 饰品1（必须在近战范围内才能使用）
        if cfg.useTrinket1 and cfg.trinket1WithCooldowns then
            if combatTime >= 2.0 and anyCooldownReady and shouldUseMajorCooldown then
                -- ✅ 优化：只保留近战距离判断
                if player.melee(target) then
                    if UseTrinket1() then return false end
                end
            end
        end
        
        -- 饰品2（必须在近战范围内才能使用）
        if cfg.useTrinket2 and cfg.trinket2WithCooldowns then
            if combatTime >= 2.0 and anyCooldownReady and shouldUseMajorCooldown then
                -- ✅ 优化：只保留近战距离判断
                if player.melee(target) then
                    if UseTrinket2() then return false end
                end
            end
        end
        
        -- 爆发药水（必须在近战范围内才能使用）
        if cfg.useCombatPotion and cfg.combatPotionWithCooldowns then
            if combatTime >= 2.0 and anyCooldownReady and shouldUseMajorCooldown then
                -- ✅ 优化：只保留近战距离判断
                if player.melee(target) then
                    UseCombatPotion()
                end
            end
        end
    end
    
    -- 等待饰品引导完成
    if IsTrinketChanneling() then
        return false
    end
    
    -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    -- SimC APL: Slayer优化手法 (已验证正确BUFF ID)
    -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    -- 核心BUFF验证：
    -- ✅ 灰烬主宰 (392537)
    -- ✅ 残暴终结 (446918)
    -- ✅ 屠戮打击 (393931)
    -- ✅ 血腥疯狂 (393951)
    -- ✅ 处刑之印 (445584)
    -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    
    -- 【第1优先级】大技能爆发（必须在近战范围内才能开启）
    -- ✅ 优化：cast()会自动检查exists/alive/enemy，只保留近战距离判断
    if player.melee(target) then
        if S.Recklessness:execute() then return true end
        if S.Avatar:execute() then return true end
    end
    
    -- 【第2优先级】Slayer核心机制 - 灰烬主宰紧急处理
    -- 灰烬主宰BUFF即将消失时立即Execute，确保不浪费巨额伤害加成
    if player.aura(A.AshenJuggernaut) then
        local ashenRem = player.auraremains(A.AshenJuggernaut)
        if ashenRem > 0 and ashenRem <= 1.5 then
            if S.Execute:cast(target) then
                return true
            end
        end
    end
    
    -- 【第3优先级】猝死BUFF时间窗口优化
    -- 非斩杀阶段猝死BUFF <2秒时立即Execute，防止BUFF浪费
    if suddenDeathUp then
        local sdRem = player.auraremains(A.SuddenDeath)
        if not executePhase and sdRem < 2.0 then
            if S.Execute:cast(target) then
                return true
            end
        end
    end
    
    -- 【第3优先级】爆发技能
    -- Thunderous Roar - 激怒状态下使用（单体+AOE通用）
    -- 只要CD好了且在激怒状态就立即使用
    if enrageUp then
        if S.ThunderousRoar:execute() then return true end
    end
    
    -- Champions Spear - 配合剑刃风暴
    if S.ChampionsSpear and S.ChampionsSpear:ready() then
        if S.Bladestorm:ready() and enrageUp then
            local avatarReady = S.Avatar:ready() or player.aura(A.Avatar)
            local recklessnessReady = S.Recklessness:ready() or player.aura(A.Recklessness)
            if avatarReady or recklessnessReady then
                if S.ChampionsSpear:cast(target) then return true end
            end
        end
    end
    
    -- Odyns Fury - AOE清空菜刀层数
    if S.OdynsFury and S.OdynsFury:ready() then
        if enemies > 1 and hasTitanicRage and mcStacks == 0 then
            if S.OdynsFury:cast(target) then return true end
        end
    end
    
    -- Bladestorm - 智能CD管理
    if enrageUp then
        local canUseBladestorm = false
        
        if hasRecklessAbandon then
            if S.Avatar:getcd() >= 24 then
                canUseBladestorm = true
            end
        elseif hasAngerManagement then
            local reckCD = S.Recklessness:getcd()
            local avatarCD = S.Avatar:getcd()
            local avatarUp = player.aura(A.Avatar)
            
            if reckCD >= 15 and (avatarUp or avatarCD >= 8) then
                canUseBladestorm = true
            end
        else
            canUseBladestorm = true
        end
        
        if canUseBladestorm then
            if S.Bladestorm:execute() then return true end
        end
    end
    
    -- 【第4优先级】AOE铺层数
    -- Whirlwind - 确保菜刀BUFF
    -- 时间追踪检查已在 callback 中处理，这里只检查业务逻辑
    if enemies >= 2 and hasMeatCleaver and mcStacks == 0 then
        if S.Whirlwind:execute() then
            return true
        end
    end
    
    -- 【第5优先级】暴怒管理
    -- Rampage - 趁温柔BUFF
    if hasTenderize and player.aura(A.BrutalFinish) then
        if S.Rampage:cast(target) then return true end
    end
    
    -- Rampage - 暴怒即将消失
    if enrageRem < 1.5 then
        if S.Rampage:cast(target) then return true end
    end
    
    -- 【第6优先级】Slayer高价值Execute
    -- Execute - 猝死2层优先处理（防止层数浪费）
    local suddenDeathStacks = player.auracount(A.SuddenDeath) or 0
    if suddenDeathStacks == 2 and enrageUp then
        if S.Execute:cast(target) then
            return true
        end
    end
    
    -- Execute - 处刑之印层数追踪（Slayer核心机制）
    local markedStacks = target.auracount(A.MarkedForExecution) or 0
    if markedStacks > 1 and enrageUp then
        if S.Execute:cast(target) then
            return true
        end
    end
    
    -- 【第7优先级】Odyns Fury（无泰坦之怒）
    if S.OdynsFury and S.OdynsFury:ready() then
        if enemies > 1 and not (hasTitanicRage) then
            if S.OdynsFury:cast(target) then return true end
        end
    end
    
    -- 【第8优先级】Raging Blow + 残暴终结 + 冠军之力协同
    local ragingCharges = S.RagingBlow:charges()
    local brutalFinish = player.aura(A.BrutalFinish)
    local champMight = target.aura(A.ChampionsMight)
    local champMightRem = target.auraremains(A.ChampionsMight) or 0
    
    local shouldUseRagingBlow = false
    
    -- 条件1: 2层充能防止溢出
    if ragingCharges == 2 then
        shouldUseRagingBlow = true
    -- 条件2: 残暴终结BUFF + 冠军之力协同判断
    elseif brutalFinish then
        if not champMight or champMightRem > 1.5 then
            shouldUseRagingBlow = true
        end
    end
    
    if shouldUseRagingBlow then
        if S.RagingBlow:cast(target) then
            return true
        end
    end
    
    -- 【第9优先级】Bloodbath多条件触发优化
    if S.Bloodbath and S.Bloodbath:ready() then
        local shouldUseBT = false
        
        -- 条件1: 血腥疯狂BUFF（正确ID: 393951）
        local bloodcrazeStack = player.auracount(A.Bloodcraze) or 0
        if bloodcrazeStack >= 1 then
            shouldUseBT = true
            if cfg.debug then
                log(string.format("🩸 【Bloodbath】血腥疯狂 %d层", bloodcrazeStack))
            end
        end
        
        -- 条件2: 喧哗天赋 + DoT刷新优化
        if not shouldUseBT then
            local btDotRem = target.auraremains(A.BloodbathDot) or 0
            
            if hasUproar and hasBloodborne and btDotRem < 40 then
                shouldUseBT = true
            end
        end
        
        -- 条件3: 激怒即将消失
        if not shouldUseBT then
            if enrageUp and enrageRem < 1.5 then
                shouldUseBT = true
            end
        end
        
        if shouldUseBT then
            if S.Bloodbath:cast(target) then
                return true
            end
        end
    end
    
    -- Raging Blow - 配合屠戮打击层数（正确ID: 393931）
    local slaughteringStacks = player.auracount(A.SlaughteringStrikes) or 0
    if brutalFinish and slaughteringStacks < 5 then
        if not champMight or champMightRem > 1.5 then
            if S.RagingBlow:cast(target) then
                return true
            end
        end
    end
    
    -- 【第10优先级】Rampage防溢出
    if rage > 115 then
        if S.Rampage:cast(target) then return true end
    end
    
    -- 【第11优先级】斩杀阶段Execute（单体优化）
    -- 只在单体且有处刑之印时使用，确保不浪费伤害加成
    if executePhase and target.aura(A.MarkedForExecution) and enrageUp and enemies == 1 then
        if cfg.debug then
            local markedStacks = target.auracount(A.MarkedForExecution) or 0
            log(string.format("💀 【斩杀阶段】Execute - 处刑之印%d层", markedStacks))
        end
        if S.Execute:cast(target) then return true end
    end
    
    -- 【第12优先级】Bloodthirst - 6目标以上使用
    if S.Bloodthirst and S.Bloodthirst:ready() and enemies > 6 then
        if cfg.debug then
            log(string.format("🩸 【嗜血AOE】%d目标", enemies))
        end
        if S.Bloodthirst:execute() then return true end
    end
    
    -- 【第13优先级】基础填充技能
    if S.RagingBlow:cast(target) then return true end
    
    if S.Bloodbath and S.Bloodbath:ready() then
        if S.Bloodbath:cast(target) then return true end
    end
    
    -- Raging Blow - 机会主义者BUFF
    if player.aura(A.Opportunist) then
        if S.RagingBlow:cast(target) then return true end
    end
    
    -- Raging Blow - 2层充能
    if S.RagingBlow:charges() == 2 then
        if S.RagingBlow:cast(target) then return true end
    end
    
    -- Onslaught - 温柔天赋
    if S.Onslaught and S.Onslaught:ready() then
        if hasTenderize then
            if S.Onslaught:cast(target) then return true end
        end
    end
    
    if S.RagingBlow:cast(target) then return true end
    if S.Rampage:cast(target) then return true end
    
    -- 【第14优先级】其他技能
    -- Odyns Fury - 暴怒期或泰坦之怒
    if S.OdynsFury and S.OdynsFury:ready() then
        if enrageUp or (hasTitanicRage) then
            if S.OdynsFury:cast(target) then return true end
        end
    end
    
    -- Execute - 猝死BUFF
    if suddenDeathUp then
        if S.Execute:cast(target) then return true end
    end
    
    -- 【填充技能】Bloodthirst - 5目标及以下时作为填充技能
    -- ✅ 严格条件：只在其他技能都不可用时使用
    if S.Bloodthirst and S.Bloodthirst:ready() and enemies <= 5 then
        -- 检查其他主要技能是否可用
        local ragingBlowCharges = S.RagingBlow and S.RagingBlow:charges() or 0
        local canRampage = rage >= 80
        local canExecute = suddenDeathUp or executePhase
        
        -- 只有当其他技能都不可用且怒气不高时才使用嗜血
        if ragingBlowCharges == 0 and not canRampage and not canExecute and rage < 70 then
            if cfg.debug then
                log(string.format("🩸 【嗜血填充】%d目标 (痛击0层|怒气%d)", enemies, rage))
            end
            if S.Bloodthirst:execute() then return true end
        end
    end
    
    -- 【最后兜底】只用Whirlwind，避免Bloodthirst占比过高
    -- Whirlwind伤害低，不会影响整体DPS占比
    -- ✅ 只有在近战范围内且有敌人时才使用
    if player.melee(target) and enemies > 0 then
        if S.Whirlwind:cast(player) then return true end
    end
    
    -- 注意: Storm Bolt已移除，仅用作打断和控制技能
    
    return false
end

------------------------------------------------------------------------
-- SimC循环 V2（完整APL，包含3次Bloodthirst）
------------------------------------------------------------------------
-- 基于最新SimC APL，包含所有Bloodthirst调用
-- 注意：由于Aurora没有动态暴击率检查，Bloodthirst可能使用频率偏高
------------------------------------------------------------------------
local function SimCRotationV2()
    UpdateCombatTime()
    
    
    if player.dead then return false end
    
    -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    -- 【自动目标切换】当目标不存在或超出范围时，自动切换
    -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    AutoTargetSwitch()
    
    -- 检查目标有效性
    if not target or not target.exists or not target.alive or not target.enemy then
        return false
    end
    
    -- 获取战斗数据
    local enemies = player.enemiesaround(8) or 0
    local enrageUp = player.aura(A.Enrage) and true or false
    local enrageRem = player.auraremains(A.Enrage) or 0
    local rage = player.rage or 0
    local mcStacks = player.auracount(A.MeatCleaver) or 0
    local combatTime = GetCombatTime()
    local suddenDeathUp = player.aura(A.SuddenDeath) and true or false
    local executePhase = (target.healthpercent < 35) or (target.healthpercent < 20)
    
    -- ✅ 优化：预缓存天赋检查结果（减少循环中的 isknown() 调用）
    local hasMeatCleaver = S.MeatCleaver and S.MeatCleaver:isknown() or false
    local hasTitanicRage = S.TitanicRage and S.TitanicRage:isknown() or false
    local hasTenderize = S.Tenderize and S.Tenderize:isknown() or false
    local hasViciousContempt = S.ViciousContempt and S.ViciousContempt:isknown() or false
    local hasRecklessAbandon = S.RecklessAbandon and S.RecklessAbandon:isknown() or false
    local hasAngerManagement = S.AngerManagement and S.AngerManagement:isknown() or false
    local hasUproar = S.Uproar and S.Uproar:isknown() or false
    local hasBloodborne = S.Bloodborne and S.Bloodborne:isknown() or false
    
    if cfg.debug then
        local cdEnabled = ShouldUseCooldowns() and "开启" or "关闭"
        log(string.format("[SimC V2] 敌人=%d | 激怒=%s(%.1fs) | 怒气=%d | 猝死=%s | 爆发=%s", 
            enemies, tostring(enrageUp), enrageRem, rage, tostring(suddenDeathUp), cdEnabled))
    end
    
    -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    -- 【起手优化】斩鲜血肉天赋 - 优先使用嗜血触发激怒
    -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    -- ✅ 使用Aurora内置的timecombat属性（更可靠）
    local playerCombatTime = player.timecombat or 0
    
    if cfg.debug and playerCombatTime < 10 then
        log(string.format("🔍 【起手检测V2】战斗时间=%.1fs | 激怒=%s | 嗜血CD=%.1fs | ready=%s", 
            playerCombatTime, tostring(enrageUp), 
            S.Bloodthirst and S.Bloodthirst:getcd() or 0,
            S.Bloodthirst and S.Bloodthirst:ready() and "true" or "false"))
    end
    
    -- 战斗开始的前5秒，如果没有激怒BUFF，优先用嗜血触发激怒
    if playerCombatTime < 5 and not enrageUp and S.Bloodthirst and S.Bloodthirst:ready() then
        if cfg.debug then
            log("🔥 【起手V2】斩鲜血肉天赋 - 使用嗜血触发激怒")
        end
        if S.Bloodthirst:execute() then return true end
    end
    
    -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    -- 【最高优先级】打断系统
    -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    -- execute() 会触发在 Rotation.lua 中定义的 callback
    -- callback 中包含所有打断逻辑（开关检查、目标选择、列表检查等）
    if S.Pummel:execute() then return true end
    if S.StormBolt:execute() then return true end
    if S.Shockwave:execute() then return true end
    
    -- 防御技能
    if S.SpellReflection:execute() then return true end
    
    -- 治疗
    if UseHealthstone() then return true end
    if UseHealingPotion() then return true end
    if S.VictoryRush:execute() then return true end
    if S.EnragingRegeneration:execute() then return true end
    
    -- 饰品和药水（受爆发开关控制）
    if ShouldUseCooldowns() then
        local recklessnessReady = S.Recklessness:ready() and cfg.useRecklessness
        local avatarReady = S.Avatar:ready() and cfg.useAvatar
        local bladestormReady = S.Bladestorm:ready() and cfg.useBladestorm
        local anyCooldownReady = recklessnessReady or avatarReady or bladestormReady
        
        local shouldUseMajorCooldown = false
        if anyCooldownReady then
            local minTTD = math.min(
                cfg.recklessnessTTD or 10,
                cfg.avatarTTD or 10,
                cfg.bladestormTTD or 8
            )
            shouldUseMajorCooldown = ShouldUseMajorCooldown(minTTD)
        end
        
        -- 饰品1
        if cfg.useTrinket1 and cfg.trinket1WithCooldowns then
            if combatTime >= 2.0 and anyCooldownReady and shouldUseMajorCooldown then
                if player.melee(target) then
                    if UseTrinket1() then return false end
                end
            end
        end
        
        -- 饰品2
        if cfg.useTrinket2 and cfg.trinket2WithCooldowns then
            if combatTime >= 2.0 and anyCooldownReady and shouldUseMajorCooldown then
                if player.melee(target) then
                    if UseTrinket2() then return false end
                end
            end
        end
        
        -- 爆发药水
        if cfg.useCombatPotion and cfg.combatPotionWithCooldowns then
            if combatTime >= 2.0 and anyCooldownReady and shouldUseMajorCooldown then
                if player.melee(target) then
                    UseCombatPotion()
                end
            end
        end
    end
    
    -- 等待饰品引导完成
    if IsTrinketChanneling() then
        return false
    end
    
    -- ====== 完整SimC APL（V2版本，包含所有Bloodthirst）======
    
    -- 1. Recklessness + Avatar
    -- ✅ 优化：只保留近战距离判断
    if player.melee(target) then
        if S.Recklessness:execute() then return true end
        if S.Avatar:execute() then return true end
    end
    
    -- 2. Execute - AshenJuggernaut紧急处理
    if player.aura(A.AshenJuggernaut) then
        local ashenRem = player.auraremains(A.AshenJuggernaut)
        if ashenRem > 0 and ashenRem <= 1.5 then
            if S.Execute:cast(target) then return true end
        end
    end
    
    -- 3. Execute - SuddenDeath时间窗口
    if suddenDeathUp then
        local sdRem = player.auraremains(A.SuddenDeath)
        if not executePhase and sdRem < 2.0 then
            if S.Execute:cast(target) then return true end
        end
    end
    
    -- 4. Thunderous Roar - AOE激怒
    if enrageUp and enemies > 1 then
        if S.ThunderousRoar:execute() then return true end
    end
    
    -- 5. Champions Spear
    if S.ChampionsSpear and S.ChampionsSpear:ready() then
        if S.Bladestorm:ready() and enrageUp then
            local avatarReady = S.Avatar:ready() or player.aura(A.Avatar)
            local recklessnessReady = S.Recklessness:ready() or player.aura(A.Recklessness)
            if avatarReady or recklessnessReady then
                if S.ChampionsSpear:cast(target) then return true end
            end
        end
    end
    
    -- 6. Odyns Fury - AOE清层
    if S.OdynsFury and S.OdynsFury:ready() then
        if enemies > 1 and hasTitanicRage and mcStacks == 0 then
            if S.OdynsFury:cast(target) then return true end
        end
    end
    
    -- 7. Bladestorm
    if enrageUp then
        local canUseBladestorm = false
        
        if hasRecklessAbandon then
            if S.Avatar:getcd() >= 24 then
                canUseBladestorm = true
            end
        elseif hasAngerManagement then
            local reckCD = S.Recklessness:getcd()
            local avatarCD = S.Avatar:getcd()
            local avatarUp = player.aura(A.Avatar)
            
            if reckCD >= 15 and (avatarUp or avatarCD >= 8) then
                canUseBladestorm = true
            end
        else
            canUseBladestorm = true
        end
        
        if canUseBladestorm then
            if S.Bladestorm:execute() then return true end
        end
    end
    
    -- 8. Whirlwind - AOE铺层
    if enemies >= 2 and hasMeatCleaver and mcStacks == 0 then
        -- ✅ 优化：使用 Aurora 内置的施法历史追踪
        if S.Whirlwind:timeSinceLastCast() >= 1.5 then
            if S.Whirlwind:execute() then
                return true
            end
        end
    end
    
    -- 9. Onslaught - Tenderize + BrutalFinish
    if S.Onslaught and S.Onslaught:ready() then
        if hasTenderize and player.aura(A.BrutalFinish) then
            if S.Onslaught:cast(target) then return true end
        end
    end
    
    -- 10. Rampage - 激怒即将消失
    if enrageRem < 1.5 then
        if S.Rampage:cast(target) then return true end
    end
    
    -- 11. Execute - SuddenDeath 2层
    local suddenDeathStacks = player.auracount(A.SuddenDeath) or 0
    if suddenDeathStacks == 2 and enrageUp then
        if S.Execute:cast(target) then return true end
    end
    
    -- 12. Execute - MarkedForExecution >1层
    local markedStacks = target.auracount(A.MarkedForExecution) or 0
    if markedStacks > 1 and enrageUp then
        if S.Execute:cast(target) then return true end
    end
    
    -- 13. Odyns Fury - AOE无泰坦
    if S.OdynsFury and S.OdynsFury:ready() then
        if enemies > 1 and not (hasTitanicRage) then
            if S.OdynsFury:cast(target) then return true end
        end
    end
    
    -- 14. Crushing Blow - 第一次
    local ragingCharges = S.RagingBlow:charges()
    local brutalFinish = player.aura(A.BrutalFinish)
    local champMight = target.aura(A.ChampionsMight)
    local champMightRem = target.auraremains(A.ChampionsMight) or 0
    
    if ragingCharges == 2 or (brutalFinish and (not champMight or champMightRem > 1.5)) then
        if S.RagingBlow:cast(target) then return true end
    end
    
    -- 15. Bloodbath - 第一次
    if S.Bloodbath and S.Bloodbath:ready() then
        local shouldUseBT = false
        
        local bloodcrazeStack = player.auracount(A.Bloodcraze) or 0
        if bloodcrazeStack >= 1 then
            shouldUseBT = true
            if cfg.debug then
                log(string.format("🩸 【Bloodbath】血腥疯狂 %d层", bloodcrazeStack))
            end
        end
        
        if not shouldUseBT then
            local btDotRem = target.auraremains(A.BloodbathDot) or 0
            
            if hasUproar and hasBloodborne and btDotRem < 40 then
                shouldUseBT = true
            end
        end
        
        if not shouldUseBT then
            if enrageUp and enrageRem < 1.5 then
                shouldUseBT = true
            end
        end
        
        if shouldUseBT then
            if S.Bloodbath:cast(target) then return true end
        end
    end
    
    -- 16. Raging Blow - BrutalFinish协同
    local slaughteringStacks = player.auracount(A.SlaughteringStrikes) or 0
    if brutalFinish and slaughteringStacks < 5 then
        if not champMight or champMightRem > 1.5 then
            if S.RagingBlow:cast(target) then return true end
        end
    end
    
    -- 17. Rampage - 防溢出
    if rage > 115 then
        if S.Rampage:cast(target) then return true end
    end
    
    -- 18. Execute - 斩杀阶段单体
    if executePhase and target.aura(A.MarkedForExecution) and enrageUp and enemies == 1 then
        if S.Execute:cast(target) then return true end
    end
    
    -- ★★★ 19. Bloodthirst - 6目标以上使用
    if S.Bloodthirst and S.Bloodthirst:ready() and enemies > 6 then
        if cfg.debug then
            log(string.format("🩸 【嗜血AOE-V2】%d目标", enemies))
        end
        if S.Bloodthirst:execute() then return true end
    end
    
    -- 20. Crushing Blow - 第二次
    if S.RagingBlow:cast(target) then return true end
    
    -- 21. Bloodbath - 第二次
    if S.Bloodbath and S.Bloodbath:ready() then
        if S.Bloodbath:cast(target) then return true end
    end
    
    -- 22. Raging Blow - Opportunist
    if player.aura(A.Opportunist) then
        if S.RagingBlow:cast(target) then return true end
    end
    
    -- 23. Raging Blow - 2层充能
    if S.RagingBlow:charges() == 2 then
        if S.RagingBlow:cast(target) then return true end
    end
    
    -- 25. Onslaught - Tenderize
    if S.Onslaught and S.Onslaught:ready() then
        if hasTenderize then
            if S.Onslaught:cast(target) then return true end
        end
    end
    
    -- 26. Raging Blow - 第三次
    if S.RagingBlow:cast(target) then return true end
    
    -- 27. Rampage
    if S.Rampage:cast(target) then return true end
    
    -- 28. Odyns Fury - 激怒或泰坦
    if S.OdynsFury and S.OdynsFury:ready() then
        if enrageUp or (hasTitanicRage) then
            if S.OdynsFury:cast(target) then return true end
        end
    end
    
    -- 29. Execute - SuddenDeath
    if suddenDeathUp then
        if S.Execute:cast(target) then return true end
    end
    
    -- ★★★ 30. Bloodthirst - 第三次（5目标及以下时作为填充技能）★★★
    -- ✅ 严格条件：只在其他技能都不可用时使用
    if S.Bloodthirst and S.Bloodthirst:ready() and enemies <= 5 then
        -- 检查其他主要技能是否可用
        local ragingBlowCharges = S.RagingBlow and S.RagingBlow:charges() or 0
        local canRampage = rage >= 80
        local canExecute = suddenDeathUp or executePhase
        
        -- 只有当其他技能都不可用且怒气不高时才使用嗜血
        if ragingBlowCharges == 0 and not canRampage and not canExecute and rage < 70 then
            if cfg.debug then
                log(string.format("🩸 【嗜血填充】%d目标 (痛击0层|怒气%d)", enemies, rage))
            end
            if S.Bloodthirst:execute() then return true end
        end
    end
    
    -- 31. Thunderous Roar
    if S.ThunderousRoar:execute() then return true end
    
    -- 32. Wrecking Throw
    -- (通常不在循环中实现)
    
    -- 33. Bloodthirst（兜底填充 - 单体和多目标）
    -- ✅ 所有情况都用嗜血填充，避免空转
    -- ✅ 旋风斩只用于铺层数，不作为填充技能
    if S.Bloodthirst and S.Bloodthirst:ready() then
        if S.Bloodthirst:execute() then return true end
    end
    
    -- 34. Storm Bolt（仅用于控制，不作为输出）
    
    return false
end

------------------------------------------------------------------------
-- 主循环（主播手法）
------------------------------------------------------------------------
local function Dps()
    UpdateCombatTime()
    
    
    if player.dead then return false end
    
    -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    -- 【自动目标切换】当目标不存在或超出范围时，自动切换
    -- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    AutoTargetSwitch()
    
    -- 检查目标有效性
    if not target or not target.exists or not target.alive or not target.enemy then
        return false
    end
    
    -- 获取战斗数据
    local enemies = player.enemiesaround(8) or 0
    local enrageUp = player.aura(A.Enrage) and true or false
    local enrageRem = player.auraremains(A.Enrage) or 0
    local rage = player.rage or 0
    local mcStacks = player.auracount(A.MeatCleaver) or 0
    local mcRem = player.auraremains(A.MeatCleaver) or 0
    local combatTime = GetCombatTime()
    
    if cfg.debug then
        local cdEnabled = ShouldUseCooldowns() and "开启" or "关闭"
        log(string.format("敌人=%d | 激怒=%s(%.1fs) | 怒气=%d | 顺劈=%d层(%.1fs) | 爆发=%s", 
            enemies, tostring(enrageUp), enrageRem, rage, mcStacks, mcRem, cdEnabled))
    end
    
    -- 中断（由 Interface.lua 的回调自动处理，无需显式调用）
    
    -- 治疗石（血量低时）
    if UseHealthstone() then return true end
    
    -- 治疗药水（血量极低时）
    if UseHealingPotion() then return true end
    
    -- 狂暴回复
    if S.EnragingRegeneration:execute() then return true end
    
    -- 💎 饰品系统（受爆发开关控制）
    -- 检查爆发开关是否开启
    if ShouldUseCooldowns() then
        -- 检查3个大技能是否ready（至少一个）
        local recklessnessReady = S.Recklessness:ready() and cfg.useRecklessness
        local avatarReady = S.Avatar:ready() and cfg.useAvatar
        local bladestormReady = S.Bladestorm:ready() and cfg.useBladestorm
        local anyCooldownReady = recklessnessReady or avatarReady or bladestormReady
        
        -- 🎯 检查目标是否值得使用大技能（避免在小怪上浪费饰品）
        local shouldUseMajorCooldown = false
        if anyCooldownReady then
            -- 使用最小的TTD阈值（最严格的条件）
            local minTTD = math.min(
                cfg.recklessnessTTD or 10,
                cfg.avatarTTD or 10,
                cfg.bladestormTTD or 8
            )
            shouldUseMajorCooldown = ShouldUseMajorCooldown(minTTD)
        end
        
        -- 第1步：使用饰品（引导类，需要1秒）
        -- 跟随大技能：大技能ready 且 目标值得使用大技能
        if cfg.useTrinket1 and cfg.trinket1WithCooldowns then
            if combatTime >= 2.0 then
                if anyCooldownReady and shouldUseMajorCooldown then
                    if player.melee(target) then
                        if UseTrinket1() then
                            return false  -- 不继续执行，下一帧再检查
                        end
                    end
                end
            end
        end
        
        if cfg.useTrinket2 and cfg.trinket2WithCooldowns then
            if combatTime >= 2.0 then
                if anyCooldownReady and shouldUseMajorCooldown then
                    if player.melee(target) then
                        if UseTrinket2() then
                            return false  -- 不继续执行，下一帧再检查
                        end
                    end
                end
            end
        end
        
        -- 不跟随大技能：CD好就用（仍受爆发开关控制）
        if cfg.useTrinket1 and not cfg.trinket1WithCooldowns then
            if combatTime >= 2.0 then
                if UseTrinket1() then
                    return false
                end
            end
        end
        if cfg.useTrinket2 and not cfg.trinket2WithCooldowns then
            if combatTime >= 2.0 then
                if UseTrinket2() then
                    return false
                end
            end
        end
        
        -- 💊 爆发药水（跟随爆发技能）
        if cfg.useCombatPotion and cfg.combatPotionWithCooldowns then
            if combatTime >= 2.0 and anyCooldownReady and shouldUseMajorCooldown then
                if player.melee(target) then
                    UseCombatPotion()
                end
            end
        end
    end
    
    -- 第2步：等待饰品引导完成
    if IsTrinketChanneling() then
        -- 饰品正在引导，不使用任何技能，避免打断
        return false
    end
    
    -- 💊 爆发药水（如果不跟随爆发技能，独立使用）
    if cfg.useCombatPotion and not cfg.combatPotionWithCooldowns then
        if UseCombatPotion() then return true end
    end
    
    -- 🔥 大技能（鲁莽、天神下凡）
    -- ✅ 优化：只保留近战距离判断
    if player.melee(target) then
        if S.Recklessness:execute() then return true end
        if S.Avatar:execute() then return true end
    end
    
    -- 雷鸣之吼 (激怒状态下使用，不受单体/AOE限制)
    if S.ThunderousRoar:execute() then return true end
    
    ------------------------------------------------------------------------
    -- 5目标及以上: AOE变量手法 (大秘境实战优先级)
    ------------------------------------------------------------------------
    if enemies >= cfg.aoeThreshold5 then
        
        local bladestormCD = S.Bladestorm:getcd() or 999
        local rbCharges = S.RagingBlow:charges() or 0
        
        -- 🔄 旋风斩管理：优先保持4层
        -- 无层数 OR (激怒持续中 且 层数<4 且 即将消失)
        if mcStacks == 0 then
            -- ✅ 优化：使用 Aurora 内置的施法历史追踪
            if S.Whirlwind:timeSinceLastCast() >= 1.5 then
                if S.Whirlwind:execute() then
                    return true
                end
            end
        elseif enrageUp and mcStacks < 4 and mcRem <= 2.0 then
            -- 激怒状态下，旋风斩快掉了就补
            if S.Whirlwind:execute() then return true end
        end
        
        -- ⚔️ 猝死四要素（智能延后策略）
        -- 如果剑刃风暴CD好了且不打算用，可以只用猝死延续殒命在即
        local shouldDelaySuddenDeath = false
        if bladestormCD == 0 then
            -- 剑刃风暴好了，评估是否延后猝死
            -- 如果旋风斩层数很高 (≥3) 且怒击有充能，优先打怒击
            if mcStacks >= 3 and rbCharges >= 1 then
                shouldDelaySuddenDeath = true
            end
        end
        
        if not shouldDelaySuddenDeath and SuddenDeath4Factors() then
            if S.Execute:execute() then return true end
        end
        
        -- 💥 激怒维持：允许怒气溢出，但要综合考虑续激怒和顺劈层数
        -- 条件：无激怒 OR 激怒快结束 OR 怒气极高(≥125)
        if not enrageUp or enrageRem < 1.0 or rage >= 125 then
            if S.Rampage:execute() then return true end
        end
        
        -- 🌀 剑刃风暴（尽量4层顺劈进入）
        if enrageUp then
            -- 优先：4层顺劈进入剑刃风暴
            if mcStacks >= 4 then
                if S.Bladestorm:execute() then return true end
            -- 次优：至少2层才考虑
            elseif mcStacks >= 2 then
                if S.Bladestorm:execute() then return true end
            end
        end
        
        -- 🔴 优先怒击（5目标以上最高单GCD伤害）
        -- 在激怒覆盖的前提下允许怒气溢出
        -- 但要平衡顺劈层数和激怒续上
        if enrageUp then
            -- 如果有2层充能，多打1-2个怒击
            if rbCharges >= 2 then
                if S.RagingBlow:execute() then return true end
            -- 如果旋风斩层数够，打怒击
            elseif mcStacks >= 2 and rbCharges >= 1 then
                if S.RagingBlow:execute() then return true end
            end
        end
        
        -- 🎯 收尾打印记怪（剑刃风暴CD期间尤其重要）
        -- 怪物带2层印记死亡会浪费10秒剑刃风暴CD
        if ShouldFinishWithExecute() then
            if S.Execute:execute() then return true end
        end
        
        -- ⚡ 嗜血填充（仅在激怒快结束或怒击CD时使用）
        -- 避免过度使用嗜血，优先使用怒击
        if not enrageUp or enrageRem < 2.0 or rbCharges == 0 then
            if S.Bloodthirst:execute() then return true end
        end
        
        -- 🔄 补充旋风斩（如果之前没补上）
        if mcStacks < 2 then
            if S.Whirlwind:execute() then return true end
        end
        
        -- 最后的怒击
        if S.RagingBlow:execute() then return true end
        
    ------------------------------------------------------------------------
    -- 2-4目标: 单体优先级 + 补旋风斩
    -- 📋 手法说明：和纯单体一模一样，只是补旋风斩层数
    ------------------------------------------------------------------------
    elseif enemies >= 2 then
        
        -- 🔄 补旋风斩：保持顺劈buff
        -- 无层数时立即补，有层数但快消失时也补
        if mcStacks == 0 then
            -- ✅ 优化：使用 Aurora 内置的施法历史追踪
            if S.Whirlwind:timeSinceLastCast() >= 1.5 then
                if S.Whirlwind:execute() then
                    return true
                end
            end
        elseif mcRem > 0 and mcRem <= 2.5 then
            if S.Whirlwind:execute() then return true end
        end
        
        -- ⚔️ 猝死五要素
        if SuddenDeath5Factors() then
            if S.Execute:execute() then return true end
        end
        
        -- 💥 激怒维持
        if not enrageUp or enrageRem < 1.0 or rage >= 115 then
            if S.Rampage:execute() then return true end
        end
        
        -- 🌀 剑刃风暴
        if enrageUp then
            if S.Bladestorm:execute() then return true end
        end
        
        -- 🎯 处决期斩杀 (20%血线)
        if target.healthpercent <= 20 and enrageUp and rage < 100 then
            if S.Execute:execute() then return true end
        end
        
        -- 🔴 怒击
        if S.RagingBlow:execute() then return true end
        
        -- ⚡ 嗜血（仅在激怒快结束或怒击CD时使用）
        if not enrageUp or enrageRem < 2.0 or S.RagingBlow:getcd() > 0.5 then
            if S.Bloodthirst:execute() then return true end
        end
        
    ------------------------------------------------------------------------
    -- 单体循环
    -- 📋 手法说明：纯单体优先级，不需要旋风斩
    ------------------------------------------------------------------------
    else
        
        -- ⚔️ 猝死五要素
        if SuddenDeath5Factors() then
            if S.Execute:execute() then return true end
        end
        
        -- 💥 激怒维持
        if not enrageUp or enrageRem < 1.0 or rage >= 115 then
            if S.Rampage:execute() then return true end
        end
        
        -- 🌀 剑刃风暴
        if enrageUp then
            if S.Bladestorm:execute() then return true end
        end
        
        -- 🎯 处决期斩杀 (20%血线)
        if target.healthpercent <= 20 and enrageUp then
            if S.Execute:execute() then return true end
        end
        
        -- 🔴 怒击
        if S.RagingBlow:execute() then return true end
        
        -- ⚡ 嗜血（仅在激怒快结束或怒击CD时使用）
        if not enrageUp or enrageRem < 2.0 or S.RagingBlow:getcd() > 0.5 then
            if S.Bloodthirst:execute() then return true end
        end
    end
    
    -- 兜底（紧急情况下的最后选择）
    if S.Bloodthirst:execute() then return true end
    
    return false
end

------------------------------------------------------------------------
-- 脱战逻辑
------------------------------------------------------------------------
local function Ooc()
    -- 脱战逻辑：给自己和队友加战斗怒吼BUFF
    if S.BattleShout:execute() then return true end
    
    return false
end

------------------------------------------------------------------------
-- 注册自定义 Toggle（可选）
------------------------------------------------------------------------
-- 添加 AOE 模式切换（如果需要更精细的控制）
if Aurora.AddGlobalToggle then
    -- AOE 模式切换
    Aurora.Rotation.AoEToggle = Aurora:AddGlobalToggle({
        label = "AOE Mode",
        var = "fury_aoe_mode",
        icon = 190411, -- 旋风斩图标
        tooltip = "切换 AOE 模式\n启用: 正常 AOE 逻辑\n禁用: 仅单体循环"
    })
end

------------------------------------------------------------------------
-- 主路由函数（根据用户选择的循环模式调用对应手法）
------------------------------------------------------------------------
local function MainRotation()
    local rotationMode = cfg.rotationMode or 1
    
    if rotationMode == 2 then
        -- SimC模拟手法
        return SimCRotation()
    else
        -- 主播手法（默认）
        return Dps()
    end
end

------------------------------------------------------------------------
-- 注册循环
------------------------------------------------------------------------
-- 职业和天赋检查已在文件开头完成
-- 代码能执行到这里，说明已经是狂怒战士了
-- 默认使用SimC V2循环（完整APL - 3次Bloodthirst）
Aurora:RegisterRoutine(function()
    if player.dead or player.aura("Food") or player.aura("Drink") then 
        return 
    end
    
    if player.combat then
        SimCRotationV2()
    else
        Ooc()
    end
end, "WARRIOR", 2, "TTFury")

-- print("|cff00ff00[TT狂战]|r 循环框架注册完成")

------------------------------------------------------------------------
-- 注册宏命令（用于手动控制）
------------------------------------------------------------------------
if Aurora.Macro then
    -- 初始化 GUI 配置界面
    local gui = Aurora.GuiBuilder:New()
    
    gui:Category("TT狂战")
        :Tab("简介")
        :Header({ text = "欢迎使用TT狂战循环!" })
        :Spacer()
        
        :Text({
            text = "1. 关于目标",
            size = 15,
            color = {r = 1, g = 1, b = 1, a = 1},
            inherit = "GameFontNormalLarge",
            width = 500
        })
        :Text({
            text = "Modules -> Auto Target -> Auto Target -> Highest -> OnlyDead",
            size = 14,
            color = {r = 0.9, g = 0.9, b = 0.9, a = 1},
            inherit = "GameFontNormal",
            width = 500
        })
        :Spacer()
        
        :Text({
            text = "2. 关于天赋",
            size = 15,
            color = {r = 1, g = 1, b = 1, a = 1},
            inherit = "GameFontNormalLarge",
            width = 500
        })
        :Text({
            text = "目前只支持屠戮天赋",
            size = 14,
            color = {r = 0.9, g = 0.9, b = 0.9, a = 1},
            inherit = "GameFontNormal",
            width = 500
        })
        :Spacer()
        
        :Text({
            text = "3. 关于技能插入",
            size = 15,
            color = {r = 1, g = 1, b = 1, a = 1},
            inherit = "GameFontNormalLarge",
            width = 500
        })
        :Text({
            text = "我们就用 Aurora 原生的 SmartQueue",
            size = 14,
            color = {r = 0.9, g = 0.9, b = 0.9, a = 1},
            inherit = "GameFontNormal",
            width = 500
        })
    
        :Tab("药品/饰品")
        :Header({ text = "主动饰品" })
        :Checkbox({
            text = "启用饰品1",
            key = "fury.trinket1.enabled",
            default = true,
            tooltip = "自动使用第一个饰品槽位的主动饰品",
            onChange = function(self, checked)
                cfg.useTrinket1 = checked
                Aurora.Config:Write("fury.trinket1.enabled", checked)
                print("|cff00ff00[TT狂战]|r 饰品1已" .. (checked and "启用" or "禁用"))
            end
        })
        :Checkbox({
            text = "启用饰品2",
            key = "fury.trinket2.enabled",
            default = true,
            tooltip = "自动使用第二个饰品槽位的主动饰品",
            onChange = function(self, checked)
                cfg.useTrinket2 = checked
                Aurora.Config:Write("fury.trinket2.enabled", checked)
                print("|cff00ff00[TT狂战]|r 饰品2已" .. (checked and "启用" or "禁用"))
            end
        })
        :Checkbox({
            text = "饰品跟随爆发使用",
            key = "fury.trinket1.withCooldowns",
            default = true,
            tooltip = "勾选: 仅在爆发技能启用时使用饰品\n不勾选: 战斗中CD好就用",
            onChange = function(self, checked)
                cfg.trinket1WithCooldowns = checked
                cfg.trinket2WithCooldowns = checked
                Aurora.Config:Write("fury.trinket1.withCooldowns", checked)
                Aurora.Config:Write("fury.trinket2.withCooldowns", checked)
                local mode = checked and "跟随爆发" or "CD好就用"
                print("|cff00ff00[TT狂战]|r 饰品模式: " .. mode)
            end
        })
        :Text({ text = "", size = 8 })
        :Header({ text = "药水和消耗品" })
        :Checkbox({
            text = "启用治疗石",
            key = "fury.healthstone.enabled",
            default = true,
            tooltip = "自动使用治疗石恢复生命值",
            onChange = function(self, checked)
                cfg.useHealthstone = checked
                print("|cff00ff00[TT狂战]|r 治疗石已" .. (checked and "启用" or "禁用"))
            end
        })
        :Slider({
            text = "治疗石血量阈值 (%)",
            key = "fury.healthstone.threshold",
            min = 0,
            max = 100,
            step = 5,
            default = 40,
            tooltip = "当生命值低于此百分比时自动使用治疗石",
            onChange = function(self, value)
                cfg.healthstoneThreshold = value
                print("|cff00ff00[TT狂战]|r 治疗石阈值设置为: " .. value .. "%")
            end
        })
        :Checkbox({
            text = "启用治疗药水",
            key = "fury.healingPotion.enabled",
            default = true,
            tooltip = "自动使用阿加治疗药水恢复生命值",
            onChange = function(self, checked)
                cfg.useHealingPotion = checked
                print("|cff00ff00[TT狂战]|r 治疗药水已" .. (checked and "启用" or "禁用"))
            end
        })
        :Slider({
            text = "治疗药水血量阈值 (%)",
            key = "fury.healingPotion.threshold",
            min = 0,
            max = 100,
            step = 5,
            default = 35,
            tooltip = "当生命值低于此百分比时自动使用阿加治疗药水\n按品质依次尝试: 史诗 > 稀有 > 优秀",
            onChange = function(self, value)
                cfg.healingPotionThreshold = value
                print("|cff00ff00[TT狂战]|r 治疗药水阈值设置为: " .. value .. "%")
            end
        })
        :Checkbox({
            text = "启用爆发药水",
            key = "fury.combatPotion.enabled",
            default = true,
            tooltip = "自动使用爆发药水增强输出",
            onChange = function(self, checked)
                cfg.useCombatPotion = checked
                print("|cff00ff00[TT狂战]|r 爆发药水已" .. (checked and "启用" or "禁用"))
            end
        })
        :Checkbox({
            text = "爆发药水跟随爆发技能",
            key = "fury.combatPotion.withCooldowns",
            default = true,
            tooltip = "勾选: 仅在爆发技能启用时使用爆发药水\n不勾选: 战斗中CD好就用",
            onChange = function(self, checked)
                cfg.combatPotionWithCooldowns = checked
                local mode = checked and "跟随爆发技能" or "CD好就用"
                print("|cff00ff00[TT狂战]|r 爆发药水模式: " .. mode)
            end
        })
    
    -- 辅助技能标签页
    gui:Tab("辅助技能")
        :Header({ text = Aurora.texture(184364, 16) .. " 防护技能" })
        :Checkbox({
            text = Aurora.texture(184364, 14) .. " 使用狂暴回复",
            key = "fury.enragingRegeneration.enabled",
            default = true,
            tooltip = "自动使用狂暴回复来恢复生命值",
            onChange = function(self, checked)
                cfg.useEnragingRegeneration = checked
                print("|cff00ff00[TT狂战]|r 狂暴回复已" .. (checked and "启用" or "禁用"))
            end
        })
        :Slider({
            text = "生命值阈值 (%)",
            key = "fury.enragingRegeneration.threshold",
            default = 45,
            min = 0,
            max = 100,
            step = 5,
            tooltip = "当生命值低于此百分比时自动使用狂暴回复",
            onChange = function(self, value)
                cfg.enragingRegenerationThreshold = value
                print("|cff00ff00[TT狂战]|r 狂暴回复阈值设置为: " .. value .. "%")
            end
        })
        
        -- 胜利在望
        :Checkbox({
            text = Aurora.texture(34428, 14) .. " 使用胜利在望",
            key = "fury.useVictoryRush",
            default = true,
            tooltip = "自动使用胜利在望",
            onChange = function(self, checked)
                cfg.useVictoryRush = checked
                print("|cff00ff00[TT狂战]|r 胜利在望已" .. (checked and "启用" or "禁用"))
            end
        })
        :Slider({
            text = "生命值阈值 (%)",
            key = "fury.victoryRush.threshold",
            default = 40,
            min = 0,
            max = 100,
            step = 5,
            tooltip = "当生命值低于此百分比时自动使用胜利在望",
            onChange = function(self, value)
                cfg.victoryRushThreshold = value
                print("|cff00ff00[TT狂战]|r 胜利在望阈值设置为: " .. value .. "%")
            end
        })
        
        -- 法术反射
        :Checkbox({
            text = Aurora.texture(23920, 14) .. " 使用法术反射",
            key = "fury.useSpellReflection",
            default = true,
            tooltip = "怪物对你施法时，且打断CD会自动反射",
            onChange = function(self, checked)
                cfg.useSpellReflection = checked
                print("|cff00ff00[TT狂战]|r 法术反射已" .. (checked and "启用" or "禁用"))
            end
        })
        :Slider({
            text = "施法进度 (%)",
            key = "fury.spellReflectionCastPercent",
            default = 60,
            min = 20,
            max = 80,
            step = 5,
            tooltip = "怪物施法进度达到此值时才反射\n\n推荐值：60%\n避免过早使用浪费技能",
            onChange = function(self, value)
                cfg.spellReflectionCastPercent = value
                print("|cff00ff00[TT狂战]|r 法术反射进度阈值设置为: " .. value .. "%")
            end
        })
        
        -- 显示掠武风暴范围
        :Checkbox({
            text = Aurora.texture(444775, 14) .. " 显示掠武风暴范围",
            key = "fury.whirlwind.showRange",
            default = true,
            tooltip = "战斗中在脚下显示5码范围圆圈\n帮助你站在怪物中间打出最高伤害",
            onChange = function(self, checked)
                cfg.showWhirlwindRange = checked
                print("|cff00ff00[TT狂战]|r 范围显示已" .. (checked and "启用" or "禁用"))
            end
        })
        :Slider({
            text = "范围圆圈透明度",
            key = "fury.whirlwind.rangeOpacity",
            default = 150,
            min = 50,
            max = 255,
            step = 10,
            tooltip = "调整圆圈的透明度\n数值越高越明显（50-255）",
            onChange = function(self, value)
                cfg.whirlwindRangeOpacity = value
                print("|cff00ff00[TT狂战]|r 圆圈透明度: " .. value)
            end
        })
    
    -- 打断标签页
    gui:Tab("打断")
        :Header({ text = Aurora.texture(6552, 16) .. " 打断系统设置" })
        :Checkbox({
            text = "使用 Aurora 列表",
            key = "fury.interrupt.withList",
            default = true,
            tooltip = "启用：只打断列表中的技能\n禁用：打断所有可打断技能\n\n💡 打断功能受Cooldown框架控制",
            onChange = function(self, checked)
                cfg.interruptWithList = checked
                local mode = checked and "仅列表" or "全部"
                print("|cff00ff00[TT狂战]|r 列表打断模式: " .. mode)
            end
        })
        :Slider({
            text = "施法进度 (%)",
            key = "fury.interrupt.castPercent",
            default = 60,
            min = 20,
            max = 80,
            step = 5,
            tooltip = "只有当施法进度到达此百分比才打断",
            onChange = function(self, value)
                cfg.interruptCastPercent = value
                print("|cff00ff00[TT狂战]|r 施法进度阈值设置为: " .. value .. "%")
            end
        })
        
        -- 风暴之锤
        :Checkbox({
            text = Aurora.texture(107570, 14) .. " 使用风暴之锤",
            key = "fury.interrupt.stormBolt",
            default = true,
            tooltip = "启用/禁用风暴之锤打断\n• 单体打断：1个读条怪时，拳击CD后使用\n• 30秒CD，远程40码",
            onChange = function(self, checked)
                cfg.useStormBolt = checked
                print("|cff00ff00[TT狂战]|r 风暴之锤已" .. (checked and "启用" or "禁用"))
            end
        })
        :Slider({
            text = "读条怪物数量",
            key = "fury.interrupt.stormBoltEnemyCount",
            default = 1,
            min = 1,
            max = 10,
            step = 1,
            tooltip = "当读条且可打断的怪物数量 >= 此值时才使用",
            onChange = function(self, value)
                cfg.stormBoltEnemyCount = value
                print("|cff00ff00[TT狂战]|r 风暴之锤读条怪数设置为: " .. value)
            end
        })
        
        -- 震荡波
        :Checkbox({
            text = Aurora.texture(46968, 14) .. " 使用震荡波",
            key = "fury.interrupt.shockwave",
            default = true,
            tooltip = "启用/禁用震荡波打断\n• 多目标打断：2个以上读条怪时优先使用\n• 单体兜底：拳击和风暴都CD时使用\n• 40秒CD，范围10码",
            onChange = function(self, checked)
                cfg.useShockwave = checked
                print("|cff00ff00[TT狂战]|r 震荡波已" .. (checked and "启用" or "禁用"))
            end
        })
        :Slider({
            text = "读条怪物数量",
            key = "fury.interrupt.shockwaveEnemyCount",
            default = 2,
            min = 1,
            max = 10,
            step = 1,
            tooltip = "当读条且可打断的怪物数量 >= 此值时才使用",
            onChange = function(self, value)
                cfg.shockwaveEnemyCount = value
                print("|cff00ff00[TT狂战]|r 震荡波读条怪数设置为: " .. value)
            end
        })
        
        -- 拳击
        :Checkbox({
            text = Aurora.texture(6552, 14) .. " 使用拳击",
            key = "fury.interrupt.pummel",
            default = true,
            tooltip = "启用/禁用拳击打断\n这是主要的打断技能，优先级最高",
            onChange = function(self, checked)
                cfg.usePummel = checked
                print("|cff00ff00[TT狂战]|r 拳击已" .. (checked and "启用" or "禁用"))
            end
        })
    
    -- 爆发技能标签页
    gui:Tab("爆发技能")
        :Header({ text = Aurora.texture(1719, 16) .. " 大技能控制" })
        :Checkbox({
            text = Aurora.texture(18499, 14) .. " 预留爆发",
            key = "fury.cooldowns.reserveBurst",
            default = false,
            tooltip = "AOE小怪只剩1-2只时不使用爆发技能\n\n作用:\n- 避免在残血小怪上浪费大技能CD\n- 保留爆发留给Boss或下一波小怪\n\n适用场景:\n- 大秘境(M+)多波次小怪\n- 需要合理分配CD的战斗\n\n建议: 开启",
            onChange = function(self, checked)
                cfg.reserveBurst = checked
                -- print("|cff00ff00[TT狂战]|r 预留爆发已" .. (checked and "启用" or "禁用"))
            end
        })
        :Text({ text = "", size = 5 })
        -- 鲁莽
        :Checkbox({
            text = Aurora.texture(1719, 14) .. " 使用鲁莽",
            key = "fury.cooldowns.recklessness",
            default = true,
            tooltip = "启用/禁用鲁莽技能\n冷却时间: 90秒\n效果: 大幅提升暴击率和伤害",
            onChange = function(self, checked)
                cfg.useRecklessness = checked
                print("|cff00ff00[TT狂战]|r 鲁莽已" .. (checked and "启用" or "禁用"))
            end
        })
        :Slider({
            text = "目标存活时间 (TTD)",
            key = "fury.cooldowns.recklessnessTTD",
            default = 10,
            min = 5,
            max = 30,
            step = 1,
            tooltip = "目标预计存活时间 ≥ 此值才使用鲁莽\n避免在即将死亡的目标上浪费90秒CD\n建议: 10秒",
            onChange = function(self, value)
                cfg.recklessnessTTD = value
                print("|cff00ff00[TT狂战]|r 鲁莽 TTD 阈值: " .. value .. "秒")
            end
        })
        
        -- 天神下凡
        :Checkbox({
            text = Aurora.texture(107574, 14) .. " 使用天神下凡",
            key = "fury.cooldowns.avatar",
            default = true,
            tooltip = "启用/禁用天神下凡技能\n冷却时间: 90秒\n效果: 提升伤害和冷却恢复速度",
            onChange = function(self, checked)
                cfg.useAvatar = checked
                print("|cff00ff00[TT狂战]|r 天神下凡已" .. (checked and "启用" or "禁用"))
            end
        })
        :Slider({
            text = "目标存活时间 (TTD)",
            key = "fury.cooldowns.avatarTTD",
            default = 10,
            min = 5,
            max = 30,
            step = 1,
            tooltip = "目标预计存活时间 ≥ 此值才使用天神下凡\n避免在即将死亡的目标上浪费90秒CD\n建议: 10秒",
            onChange = function(self, value)
                cfg.avatarTTD = value
                print("|cff00ff00[TT狂战]|r 天神下凡 TTD 阈值: " .. value .. "秒")
            end
        })
        
        -- 剑刃风暴
        :Checkbox({
            text = Aurora.texture(446035, 14) .. " 使用剑刃风暴",
            key = "fury.cooldowns.bladestorm",
            default = true,
            tooltip = "启用/禁用剑刃风暴技能\n冷却时间: 90秒\n效果: 强力 AOE 技能",
            onChange = function(self, checked)
                cfg.useBladestorm = checked
                print("|cff00ff00[TT狂战]|r 剑刃风暴已" .. (checked and "启用" or "禁用"))
            end
        })
        :Slider({
            text = "目标存活时间 (TTD)",
            key = "fury.cooldowns.bladestormTTD",
            default = 8,
            min = 5,
            max = 30,
            step = 1,
            tooltip = "目标预计存活时间 ≥ 此值才使用剑刃风暴\n剑刃风暴持续4秒，建议至少8秒\n建议: 8秒",
            onChange = function(self, value)
                cfg.bladestormTTD = value
                print("|cff00ff00[TT狂战]|r 剑刃风暴 TTD 阈值: " .. value .. "秒")
            end
        })
        
        :Text({ text = "", size = 10 })
        :Header({ text = "调试选项" })
        :Checkbox({
            text = Aurora.texture(134332, 14) .. " 启用调试模式",
            key = "fury.debug",
            default = false,
            tooltip = "开启后会在聊天框显示详细的循环信息\n\n包括:\n• 饰品使用/跳过信息\n• 技能使用决策\n• 打断系统状态\n\n注意: 会产生大量消息",
            onChange = function(self, checked)
                cfg.debug = checked
                print("|cff00ff00[TT狂战]|r 调试模式已" .. (checked and "启用 ✅" or "禁用 ❌"))
            end
        })
    
    -- 天赋导入标签页
    gui:Tab("天赋导入")
        :Header({ text = "天赋配置导入" })
        :Button({
            text = Aurora.texture(134400, 16) .. " 大米屠戮天赋",
            width = 200,
            height = 30,
            tooltip = "点击弹出天赋代码窗口\n适用场景：大秘境M+ / 团本AOE",
            onClick = function()
                -- 天赋代码
                local talentCode = "CgEArbixk/ZKwTdpZGVHeylmLAAAAAAAAAQjhxsxMMzygZWYmZmZGmhZ22mZMzMLAzMzYmxywwMzMAAAIGbbDsAmgZYCMYDA"
                
                -- 使用 data 参数传递天赋代码
                local dialog = StaticPopup_Show("SLAYER_TALENT_CODE", "", "", talentCode)
                
                -- 显示后立即设置输入框内容（多重保险）
                if dialog then
                    C_Timer.After(0, function()
                        local editBox = dialog.editBox
                        if not editBox then
                            editBox = _G[dialog:GetName().."EditBox"]
                        end
                        if editBox then
                            editBox:SetMaxLetters(0)
                            editBox:SetText(talentCode)
                            editBox:HighlightText()
                            editBox:SetFocus()
                        end
                    end)
                end
            end
        })
    
    -- 设置配置默认值
    Aurora.Config:SetDefault("fury.enragingRegeneration.enabled", true)
    Aurora.Config:SetDefault("fury.enragingRegeneration.threshold", 45)
    Aurora.Config:SetDefault("fury.trinket1.enabled", true)
    Aurora.Config:SetDefault("fury.trinket1.withCooldowns", true)
    Aurora.Config:SetDefault("fury.trinket2.enabled", true)
    Aurora.Config:SetDefault("fury.trinket2.withCooldowns", true)
    Aurora.Config:SetDefault("fury.battleshout.enabled", true)
    Aurora.Config:SetDefault("fury.healthstone.enabled", true)
    Aurora.Config:SetDefault("fury.healthstone.threshold", 40)
    Aurora.Config:SetDefault("fury.healingPotion.enabled", true)
    Aurora.Config:SetDefault("fury.healingPotion.threshold", 35)
    Aurora.Config:SetDefault("fury.combatPotion.enabled", true)
    Aurora.Config:SetDefault("fury.combatPotion.withCooldowns", true)
    Aurora.Config:SetDefault("fury.aoe.threshold4", 4)
    Aurora.Config:SetDefault("fury.aoe.threshold5", 5)
    Aurora.Config:SetDefault("fury.whirlwind.showRange", true)
    Aurora.Config:SetDefault("fury.whirlwind.rangeOpacity", 150)
    Aurora.Config:SetDefault("fury.debug.enabled", false)
    
    -- 中断配置默认值
    Aurora.Config:SetDefault("fury.interrupt.enabled", true)
    Aurora.Config:SetDefault("fury.interrupt.withList", true)
    Aurora.Config:SetDefault("fury.interrupt.castPercent", 20)
    Aurora.Config:SetDefault("fury.interrupt.pummel", true)
    Aurora.Config:SetDefault("fury.interrupt.stormBolt", true)
    Aurora.Config:SetDefault("fury.interrupt.stormBoltEnemyCount", 1)
    Aurora.Config:SetDefault("fury.interrupt.shockwave", true)
    Aurora.Config:SetDefault("fury.interrupt.shockwaveEnemyCount", 3)
    
    -- 爆发技能配置默认值
    Aurora.Config:SetDefault("fury.cooldowns.reserveBurst", false)
    Aurora.Config:SetDefault("fury.cooldowns.recklessness", true)
    Aurora.Config:SetDefault("fury.cooldowns.recklessnessTTD", 10)
    Aurora.Config:SetDefault("fury.cooldowns.avatar", true)
    Aurora.Config:SetDefault("fury.cooldowns.avatarTTD", 10)
    Aurora.Config:SetDefault("fury.cooldowns.bladestorm", true)
    Aurora.Config:SetDefault("fury.cooldowns.bladestormTTD", 8)
    
    -- 从保存的配置加载值
    cfg.useEnragingRegeneration = Aurora.Config:Read("fury.enragingRegeneration.enabled")
    cfg.enragingRegenerationThreshold = Aurora.Config:Read("fury.enragingRegeneration.threshold")
    cfg.useBattleShout = Aurora.Config:Read("fury.battleshout.enabled")
    cfg.useHealthstone = Aurora.Config:Read("fury.healthstone.enabled")
    cfg.healthstoneThreshold = Aurora.Config:Read("fury.healthstone.threshold")
    cfg.useHealingPotion = Aurora.Config:Read("fury.healingPotion.enabled")
    cfg.healingPotionThreshold = Aurora.Config:Read("fury.healingPotion.threshold")
    cfg.useCombatPotion = Aurora.Config:Read("fury.combatPotion.enabled")
    cfg.combatPotionWithCooldowns = Aurora.Config:Read("fury.combatPotion.withCooldowns")
    cfg.aoeThreshold4 = Aurora.Config:Read("fury.aoe.threshold4")
    cfg.aoeThreshold5 = Aurora.Config:Read("fury.aoe.threshold5")
    cfg.showWhirlwindRange = Aurora.Config:Read("fury.whirlwind.showRange")
    cfg.whirlwindRangeOpacity = Aurora.Config:Read("fury.whirlwind.rangeOpacity")
    cfg.debug = Aurora.Config:Read("fury.debug.enabled")
    
    -- 加载中断配置
    cfg.useInterrupt = Aurora.Config:Read("fury.interrupt.enabled")
    cfg.interruptWithList = Aurora.Config:Read("fury.interrupt.withList")
    cfg.interruptCastPercent = Aurora.Config:Read("fury.interrupt.castPercent")
    cfg.usePummel = Aurora.Config:Read("fury.interrupt.pummel")
    cfg.useStormBolt = Aurora.Config:Read("fury.interrupt.stormBolt")
    cfg.stormBoltEnemyCount = Aurora.Config:Read("fury.interrupt.stormBoltEnemyCount")
    cfg.useShockwave = Aurora.Config:Read("fury.interrupt.shockwave")
    cfg.shockwaveEnemyCount = Aurora.Config:Read("fury.interrupt.shockwaveEnemyCount")
    
    -- 加载爆发技能配置
    cfg.reserveBurst = Aurora.Config:Read("fury.cooldowns.reserveBurst")
    cfg.useRecklessness = Aurora.Config:Read("fury.cooldowns.recklessness")
    cfg.recklessnessTTD = Aurora.Config:Read("fury.cooldowns.recklessnessTTD")
    cfg.useAvatar = Aurora.Config:Read("fury.cooldowns.avatar")
    cfg.avatarTTD = Aurora.Config:Read("fury.cooldowns.avatarTTD")
    cfg.useBladestorm = Aurora.Config:Read("fury.cooldowns.bladestorm")
    cfg.bladestormTTD = Aurora.Config:Read("fury.cooldowns.bladestormTTD")
    
    -- print("|cff00ff00[TT狂战]|r GUI配置界面已加载")
    
    ------------------------------------------------------------------------
    -- 状态框架 - 打断控制
    ------------------------------------------------------------------------
    -- Aurora原生的Interrupt按钮应该已经存在，我们直接使用
    -- 如果 /aurora toggle interrupt 不工作，可能是因为：
    -- 1. 按钮名称不是 "Interrupt"
    -- 2. 或者需要检查 Aurora.Rotation.Interrupts（复数）
    -- 3. 或者检查其他可能的名称
    
    -- 添加风暴之锤切换按钮
    Aurora.Rotation.StormBoltToggle = Aurora:AddGlobalToggle({
        label = "风暴之锤",
        var = "fury_stormbolt_interrupt",
        icon = 107570,  -- 风暴之锤技能ID
        tooltip = "启用/禁用风暴之锤自动打断\n\n当前设置:\n- 敌人数量阈值: " .. cfg.stormBoltEnemyCount .. "\n- 冷却时间: 30秒",
        onClick = function(value)
            cfg.useStormBolt = value
            Aurora.Config:Write("fury.interrupt.stormBolt", value)
            -- print("|cff00ff00[TT狂战]|r 风暴之锤打断已" .. (value and "|cff00ff00启用|r" or "|cffff0000禁用|r"))
        end
    })
    
    -- 添加震荡波切换按钮
    Aurora.Rotation.ShockwaveToggle = Aurora:AddGlobalToggle({
        label = "震荡波",
        var = "fury_shockwave_interrupt",
        icon = 46968,  -- 震荡波技能ID
        tooltip = "启用/禁用震荡波自动打断\n\n当前设置:\n- 敌人数量阈值: " .. cfg.shockwaveEnemyCount .. "\n- 冷却时间: 40秒\n- AOE打断优先",
        onClick = function(value)
            cfg.useShockwave = value
            Aurora.Config:Write("fury.interrupt.shockwave", value)
            -- print("|cff00ff00[TT狂战]|r 震荡波打断已" .. (value and "|cff00ff00启用|r" or "|cffff0000禁用|r"))
        end
    })
    
    -- 添加战斗怒吼切换按钮
    Aurora.Rotation.BattleShoutToggle = Aurora:AddGlobalToggle({
        label = "战斗怒吼",
        var = "fury_battleshout",
        icon = 6673,  -- 战斗怒吼技能ID
        tooltip = "启用/禁用战斗怒吼自动使用\n\n战斗外自动给队友加BUFF\n持续时间: 1小时",
        onClick = function(value)
            cfg.useBattleShout = value
            Aurora.Config:Write("fury.battleshout.enabled", value)
            -- print("|cff00ff00[TT狂战]|r 战斗怒吼已" .. (value and "|cff00ff00启用|r" or "|cffff0000禁用|r"))
        end
    })
    
    -- 设置初始值（从配置读取）
    -- InterruptToggle 是 Aurora 原生的，不需要设置初始值
    
    if Aurora.Rotation.StormBoltToggle then
        Aurora.Rotation.StormBoltToggle:SetValue(cfg.useStormBolt)
    end
    
    if Aurora.Rotation.ShockwaveToggle then
        Aurora.Rotation.ShockwaveToggle:SetValue(cfg.useShockwave)
    end
    
    if Aurora.Rotation.BattleShoutToggle then
        Aurora.Rotation.BattleShoutToggle:SetValue(cfg.useBattleShout)
    end
    
    -- print("|cff00ff00[TT狂战]|r 状态框架切换按钮已创建:")
    -- print("  |cff00ffff风暴之锤|r - 快速切换风暴之锤打断")
    -- print("  |cff00ffff震荡波|r - 快速切换震荡波打断")
    -- print("  |cff00ffff战斗怒吼|r - 快速切换战斗怒吼BUFF")
    
    ------------------------------------------------------------------------
    -- 天赋配置弹窗系统
    ------------------------------------------------------------------------
    
    -- 天赋代码
    local TALENT_CODE = "CgEArbixk/ZKwTdpZGVHeylmLAAAAAAAAAQjhxsxMMzygZWYmZmZGmhZ22mZMzMLAzMzYmxywwMzMAAAIGbbDsAmgZYCMYDA"
    
    -- 注册天赋弹窗对话框
    StaticPopupDialogs["SLAYER_TALENT_CODE"] = {
        text = "天赋配置：大米屠戮\n\n请按 Ctrl+C 复制下方输入框中的代码",
        button1 = "确定",
        timeout = 0,
        whileDead = true,
        hideOnEscape = true,
        hasEditBox = true,
        editBoxWidth = 350,
        maxLetters = 0,
        OnShow = function(self, data)
            -- 多种方式尝试获取 editBox
            local editBox = self.editBox
            if not editBox then
                editBox = _G[self:GetName().."EditBox"]
            end
            if not editBox then
                for i = 1, 4 do
                    local popup = _G["StaticPopup"..i]
                    if popup and popup:IsShown() and popup.which == "SLAYER_TALENT_CODE" then
                        editBox = popup.editBox or _G["StaticPopup"..i.."EditBox"]
                        break
                    end
                end
            end
            
            if editBox then
                editBox:SetMaxLetters(0)
                editBox:SetText(data)
                editBox:HighlightText()
                editBox:SetFocus()
                -- 额外确保文本被设置
                C_Timer.After(0, function()
                    if editBox then
                        editBox:SetText(data)
                        editBox:HighlightText()
                    end
                end)
            end
        end,
        OnHide = function(self)
            if self.editBox then
                self.editBox:SetText("")
            end
        end,
        EditBoxOnEnterPressed = function(self)
            self:GetParent():Hide()
        end,
        EditBoxOnEscapePressed = function(self)
            self:GetParent():Hide()
        end,
        preferredIndex = 3,
    }
    
    -- 显示天赋弹窗的函数
    local function ShowTalentPopup()
        -- 使用 data 参数传递天赋代码
        local dialog = StaticPopup_Show("SLAYER_TALENT_CODE", "", "", TALENT_CODE)
        
        -- 显示后再次尝试设置（多重保险）
        if dialog then
            C_Timer.After(0, function()
                local editBox = dialog.editBox
                if not editBox then
                    editBox = _G[dialog:GetName().."EditBox"]
                end
                if editBox then
                    editBox:SetMaxLetters(0)
                    editBox:SetText(TALENT_CODE)
                    editBox:HighlightText()
                    editBox:SetFocus()
                end
            end)
        end
    end
    
    -- 注册天赋显示命令
    Aurora.Macro:RegisterCommand("talent", ShowTalentPopup, "显示大米屠戮天赋代码")
    
    -- print("|cff00ff00[TT狂战]|r 天赋配置弹窗已注册: |cff00ffff/slayer talent|r")
    
    -- 切换爆发开关
    Aurora.Macro:RegisterCommand("cd", function(args)
        if args == "on" or args == "1" then
            cfg.manualCooldownsEnabled = true
            print("|cff00ff00[TT狂战]|r 爆发技能已 |cff00ff00启用|r")
        elseif args == "off" or args == "0" then
            cfg.manualCooldownsEnabled = false
            print("|cffff0000[TT狂战]|r 爆发技能已 |cffff0000禁用|r")
        else
            -- 切换状态
            cfg.manualCooldownsEnabled = not cfg.manualCooldownsEnabled
            local status = cfg.manualCooldownsEnabled and "|cff00ff00启用|r" or "|cffff0000禁用|r"
            print("|cff00ff00[TT狂战]|r 爆发技能已切换为: " .. status)
        end
    end, "切换爆发技能 (on/off/toggle)")
    
    -- 切换调试模式
    Aurora.Macro:RegisterCommand("debug", function(args)
        if args == "on" or args == "1" then
            cfg.debug = true
            print("|cff00ff00[TT狂战]|r 调试模式已 |cff00ff00启用|r")
        elseif args == "off" or args == "0" then
            cfg.debug = false
            print("|cffff0000[TT狂战]|r 调试模式已 |cffff0000禁用|r")
        else
            cfg.debug = not cfg.debug
            local status = cfg.debug and "|cff00ff00启用|r" or "|cffff0000禁用|r"
            print("|cff00ff00[TT狂战]|r 调试模式已切换为: " .. status)
        end
    end, "切换调试模式 (on/off/toggle)")
    
    -- 显示当前状态
    Aurora.Macro:RegisterCommand("status", function()
        print("|cffff00ff========== TT狂战状态 ==========|r")
        
        -- 爆发技能状态
        if Aurora.Rotation and Aurora.Rotation.Cooldown then
            local cdValue = Aurora.Rotation.Cooldown:GetValue()
            print("爆发技能 (Toggle): " .. (cdValue and "|cff00ff00启用|r" or "|cffff0000禁用|r"))
        else
            print("爆发技能 (Toggle): |cffff0000未检测到|r")
        end
        print("爆发技能 (手动): " .. (cfg.manualCooldownsEnabled and "|cff00ff00启用|r" or "|cffff0000禁用|r"))
        print("最终使用爆发: " .. (ShouldUseCooldowns() and "|cff00ff00是|r" or "|cffff0000否|r"))
        
        -- 中断状态
        if Aurora.Rotation and Aurora.Rotation.Interrupt then
            local intValue = Aurora.Rotation.Interrupt:GetValue()
            print("中断 (Toggle): " .. (intValue and "|cff00ff00启用|r" or "|cffff0000禁用|r"))
        else
            print("中断 (Toggle): |cffff0000未检测到|r")
        end
        print("中断 (手动): " .. (cfg.useInterrupt and "|cff00ff00启用|r" or "|cffff0000禁用|r"))
        print("最终使用中断: " .. (ShouldUseInterrupt() and "|cff00ff00是|r" or "|cffff0000否|r"))
        
        -- 其他设置
        print("调试模式: " .. (cfg.debug and "|cff00ff00启用|r" or "|cffff0000禁用|r"))
        print("自动中断: " .. (cfg.useInterrupt and "|cff00ff00启用|r" or "|cffff0000禁用|r"))
        print("列表中断: " .. (cfg.interruptWithList and "|cff00ff00启用|r (仅列表)" or "|cffff0000禁用|r (全部)"))
        print("狂暴回复: " .. (cfg.useEnragingRegeneration and "|cff00ff00启用|r" or "|cffff0000禁用|r") .. " (阈值: " .. cfg.enragingRegenerationThreshold .. "%)")
        print("AOE 阈值: 4目标=" .. cfg.aoeThreshold4 .. " | 5目标=" .. cfg.aoeThreshold5)
        
        -- 显示中断列表信息
        if Aurora.Lists and Aurora.Lists.InterruptSpells then
            print("中断列表技能数: " .. #Aurora.Lists.InterruptSpells)
        else
            print("中断列表: |cffff0000未加载|r")
        end
        print("|cffff00ff===================================|r")
    end, "显示循环状态")
    
    -- 设置狂暴回复阈值
    Aurora.Macro:RegisterCommand("er", function(threshold)
        local value = tonumber(threshold)
        if value and value >= 0 and value <= 100 then
            cfg.enragingRegenerationThreshold = value
            print("|cff00ff00[TT狂战]|r 狂暴回复阈值设置为: |cff00ff00" .. value .. "%|r")
        else
            print("|cffff0000[TT狂战]|r 无效的阈值，请输入 0-100 之间的数字")
            print("当前阈值: " .. cfg.enragingRegenerationThreshold .. "%")
        end
    end, "设置狂暴回复血量阈值 (0-100)")
    
    -- 切换中断
    Aurora.Macro:RegisterCommand("int", function(args)
        if args == "on" or args == "1" then
            cfg.useInterrupt = true
            print("|cff00ff00[TT狂战]|r 自动中断已 |cff00ff00启用|r")
        elseif args == "off" or args == "0" then
            cfg.useInterrupt = false
            print("|cffff0000[TT狂战]|r 自动中断已 |cffff0000禁用|r")
        else
            cfg.useInterrupt = not cfg.useInterrupt
            local status = cfg.useInterrupt and "|cff00ff00启用|r" or "|cffff0000禁用|r"
            print("|cff00ff00[TT狂战]|r 自动中断已切换为: " .. status)
        end
    end, "切换自动中断 (on/off/toggle)")
    
    -- 切换列表中断
    Aurora.Macro:RegisterCommand("intlist", function(args)
        if args == "on" or args == "1" then
            cfg.interruptWithList = true
            print("|cff00ff00[TT狂战]|r 列表中断已 |cff00ff00启用|r (仅中断列表中的技能)")
        elseif args == "off" or args == "0" then
            cfg.interruptWithList = false
            print("|cffff0000[TT狂战]|r 列表中断已 |cffff0000禁用|r (中断所有可中断技能)")
        else
            cfg.interruptWithList = not cfg.interruptWithList
            local status = cfg.interruptWithList and "|cff00ff00启用|r (仅列表)" or "|cffff0000禁用|r (全部)"
            print("|cff00ff00[TT狂战]|r 列表中断已切换为: " .. status)
        end
    end, "切换列表中断模式 (on/off/toggle)")
    
    -- 修复中断列表
    Aurora.Macro:RegisterCommand("intfix", function()
        print("|cff00ff00[TT狂战]|r 尝试修复中断列表...")
        
        -- 检查 Aurora.Lists 是否存在
        if not Aurora.Lists then
            print("|cffff0000错误: Aurora.Lists 不存在|r")
            print("|cffffff00解决方案: 确保 Aurora 框架正确加载|r")
            return
        end
        
        print("检查默认列表...")
        
        -- 尝试使用默认列表
        if Aurora.Lists.DefaultInterruptSpells then
            local count = 0
            if type(Aurora.Lists.DefaultInterruptSpells) == "table" then
                for _ in pairs(Aurora.Lists.DefaultInterruptSpells) do
                    count = count + 1
                end
            end
            
            if count > 0 then
                -- 复制默认列表到工作列表
                Aurora.Lists.InterruptSpells = {}
                for k, v in pairs(Aurora.Lists.DefaultInterruptSpells) do
                    Aurora.Lists.InterruptSpells[k] = v
                end
                print("|cff00ff00成功!|r 已加载默认中断列表 (共 " .. count .. " 个技能)")
                print("|cffffff00提示: 现在可以使用中断功能了|r")
                print("|cffffff00运行 /aurora inttest 验证|r")
            else
                print("|cffff0000错误: 默认中断列表为空 (0个技能)|r")
                print("|cffffff00这可能是 Aurora 框架配置问题|r")
                print("|cffffff00建议: 使用 /aurora intlist off 禁用列表模式|r")
            end
        else
            print("|cffff0000错误: Aurora.Lists.DefaultInterruptSpells 不存在|r")
            print("|cffffff00这可能是 Aurora 框架版本问题|r")
            print("|cffffff00建议: 使用 /aurora intlist off 禁用列表模式|r")
        end
    end, "修复中断列表")
    
    -- 查看中断列表状态
    Aurora.Macro:RegisterCommand("intlist-info", function()
        print("|cffff00ff========== Aurora 中断列表状态 ==========|r")
        
        -- 检查 Aurora.Lists 是否存在
        if not Aurora or not Aurora.Lists then
            print("|cffff0000错误: Aurora.Lists 不存在|r")
            return
        end
        
        -- 显示工作列表
        if Aurora.Lists.InterruptSpells then
            local count = 0
            for _ in pairs(Aurora.Lists.InterruptSpells) do count = count + 1 end
            print(string.format("\n|cff00ff00工作列表 (InterruptSpells): %d 个技能|r", count))
            
            if count > 0 and count <= 20 then
                print("技能列表:")
                for i, spellId in ipairs(Aurora.Lists.InterruptSpells) do
                    -- 安全获取技能名称
                    local spellName = "未知"
                    if spellId and type(spellId) == "number" then
                        local name = GetSpellInfo(spellId)
                        if name and type(name) == "string" then
                            spellName = name
                        end
                    end
                    print(string.format("  %d. %s (ID:%s)", i, spellName, tostring(spellId)))
                    if i >= 10 then
                        print(string.format("  ... 还有 %d 个技能", count - 10))
                        break
                    end
                end
            elseif count > 20 then
                print(string.format("  (共 %d 个技能，使用 /dump Aurora.Lists.InterruptSpells 查看完整列表)", count))
            else
                print("  |cffff0000列表为空！|r")
            end
        else
            print("\n|cffff0000工作列表 (InterruptSpells): 不存在|r")
        end
        
        -- 显示默认列表
        if Aurora.Lists.DefaultInterruptSpells then
            local count = 0
            for _ in pairs(Aurora.Lists.DefaultInterruptSpells) do count = count + 1 end
            print(string.format("\n|cffffff00默认列表 (DefaultInterruptSpells): %d 个技能|r", count))
        else
            print("\n|cffff0000默认列表 (DefaultInterruptSpells): 不存在|r")
        end
        
        -- 显示配置文件位置
        print("\n|cffffff00配置文件: configs/InterruptSpells.json|r")
        print("|cffff00ff==========================================|r")
    end, "查看 Aurora 中断列表状态")
    
    -- 测试中断（调试用）
    Aurora.Macro:RegisterCommand("inttest", function()
        print("|cffff00ff========== 中断系统测试 ==========|r")
        print("中断开关: " .. (ShouldUseInterrupt() and "|cff00ff00启用|r" or "|cffff0000禁用|r"))
        print("列表模式: " .. (cfg.interruptWithList and "|cff00ff00启用|r" or "|cffff0000禁用|r"))
        
        -- 显示列表状态
        if Aurora.Lists and Aurora.Lists.InterruptSpells then
            local count = 0
            for _ in pairs(Aurora.Lists.InterruptSpells) do count = count + 1 end
            print(string.format("中断列表: |cff00ff00%d 个技能|r", count))
        else
            print("中断列表: |cffff0000不可用|r")
        end
        
        if target and target.exists then
            print("目标: " .. (target.name or "未知"))
            print("目标存活: " .. (target.alive and "|cff00ff00是|r" or "|cffff0000否|r"))
            print("目标敌对: " .. (target.enemy and "|cff00ff00是|r" or "|cffff0000否|r"))
            print("目标施法: " .. ((target.casting or target.channeling) and "|cff00ff00是|r" or "|cffff0000否|r"))
            
            if target.casting or target.channeling then
                local spellId = target.castingspellid or target.channelingspellid
                print("施法技能ID: " .. (spellId or "未知"))
                print("可中断: " .. ((target.castinginterruptible or target.channelinginterruptible) and "|cff00ff00是|r" or "|cffff0000否|r"))
                
                -- 显示施法进度（使用 Aurora 内置属性）
                local castPercent = 0
                if target.casting then
                    castPercent = target.castingpct or 0
                    local duration = target.castingduration or 0
                    local remains = target.castingremains or 0
                    print(string.format("施法进度: |cff00ff00%.1f%%|r (已用: %.2fs, 剩余: %.2fs)", castPercent, duration, remains))
                elseif target.channeling then
                    castPercent = target.channelingpct or 0
                    local duration = target.channelingduration or 0
                    local remains = target.channelingtimeremains or 0
                    print(string.format("引导进度: |cff00ff00%.1f%%|r (已用: %.2fs, 剩余: %.2fs)", castPercent, duration, remains))
                end
                
                local threshold = cfg.interruptCastPercent or 60
                if castPercent >= threshold then
                    print(string.format("进度检查: |cff00ff00%.1f%% >= %d%% 允许打断|r", castPercent, threshold))
                else
                    print(string.format("进度检查: |cffff0000%.1f%% < %d%% 等待中|r", castPercent, threshold))
                end
                
                if cfg.interruptWithList and spellId and Aurora.Lists and Aurora.Lists.InterruptSpells then
                    local inList = false
                    for _, id in ipairs(Aurora.Lists.InterruptSpells) do
                        if id == spellId then
                            inList = true
                            break
                        end
                    end
                    print("在中断列表中: " .. (inList and "|cff00ff00是|r" or "|cffff0000否|r"))
                end
            end
            
            -- 测试 Pummel
            if S.Pummel then
                print("拳击准备: " .. (S.Pummel:ready() and "|cff00ff00是|r" or "|cffff0000否|r"))
                print("拳击CD: " .. (S.Pummel:getcd() or 0) .. " 秒")
            end
        else
            print("|cffff0000没有目标|r")
        end
        
        if Aurora.Lists then
            if Aurora.Lists.InterruptSpells and #Aurora.Lists.InterruptSpells > 0 then
                print("中断列表加载: |cff00ff00是|r (共 " .. #Aurora.Lists.InterruptSpells .. " 个技能)")
            elseif Aurora.Lists.DefaultInterruptSpells and #Aurora.Lists.DefaultInterruptSpells > 0 then
                print("中断列表加载: |cffffff00部分|r (使用默认列表，共 " .. #Aurora.Lists.DefaultInterruptSpells .. " 个技能)")
                print("|cffffff00提示: 尝试 /aurora intfix 修复列表|r")
            else
                print("中断列表加载: |cffff0000否|r (列表为空)")
                print("|cffffff00建议: 使用 /aurora intlist off 禁用列表模式|r")
            end
        else
            print("中断列表加载: |cffff0000否|r (Aurora.Lists 不存在)")
        end
        print("|cffff00ff===================================|r")
    end, "测试中断系统")
    
    -- 测试雷鸣之吼
    Aurora.Macro:RegisterCommand("roartest", function()
        print("|cffff00ff========== 雷鸣之吼测试 ==========|r")
        
        -- 检查技能是否存在
        if not S.ThunderousRoar then
            print("|cffff0000雷鸣之吼技能不存在！|r")
            return
        end
        
        print("技能存在: |cff00ff00是|r")
        print("技能ID: 384318")
        
        -- 检查技能状态
        if S.ThunderousRoar.ready then
            local isReady = S.ThunderousRoar:ready()
            print("技能准备: " .. (isReady and "|cff00ff00是|r" or "|cffff0000否|r"))
        end
        
        if S.ThunderousRoar.getcd then
            local cd = S.ThunderousRoar:getcd() or 0
            print("冷却时间: " .. string.format("%.1f", cd) .. " 秒")
        end
        
        -- 检查激怒状态
        local hasEnrage = player.aura(A.Enrage)
        print("激怒状态: " .. (hasEnrage and "|cff00ff00是|r" or "|cffff0000否|r"))
        
        if hasEnrage then
            local enrageRem = player.auraremains(A.Enrage) or 0
            print("激怒剩余: " .. string.format("%.1f", enrageRem) .. " 秒")
        end
        
        -- 检查战斗状态
        print("战斗状态: " .. (player.combat and "|cff00ff00是|r" or "|cffff0000否|r"))
        
        -- 检查目标
        if target and target.exists then
            print("目标: " .. (target.name or "未知"))
            print("目标存活: " .. (target.alive and "|cff00ff00是|r" or "|cffff0000否|r"))
            print("目标敌对: " .. (target.enemy and "|cff00ff00是|r" or "|cffff0000否|r"))
        else
            print("|cffff0000没有目标|r")
        end
        
        -- 尝试手动执行
        print("|cffffff00尝试执行雷鸣之吼...|r")
        if S.ThunderousRoar:execute() then
            print("|cff00ff00成功！|r")
        else
            print("|cffff0000失败！检查上述条件|r")
        end
        
        print("|cffff00ff===================================|r")
    end, "测试雷鸣之吼")
    
    -- 测试饰品
    Aurora.Macro:RegisterCommand("trinkettest", function()
        print("|cffff00ff========== 饰品系统测试 ==========|r")
        
        -- 检查 Aurora.ItemHandler
        if not Aurora or not Aurora.ItemHandler then
            print("|cffff0000[错误]|r Aurora.ItemHandler 不存在")
            print("|cffffff00提示: 确保Aurora框架已正确加载|r")
            return
        end
        print("|cff00ff00✓|r Aurora.ItemHandler 已加载")
        
        -- 检查配置
        print("")
        print("|cff00ffff【配置状态】|r")
        print("饰品1启用: " .. (cfg.useTrinket1 and "|cff00ff00是|r" or "|cffff0000否|r"))
        print("饰品1跟随大技能: " .. (cfg.trinket1WithCooldowns and "|cff00ff00是|r" or "|cffff0000否|r"))
        print("饰品2启用: " .. (cfg.useTrinket2 and "|cff00ff00是|r" or "|cffff0000否|r"))
        print("饰品2跟随大技能: " .. (cfg.trinket2WithCooldowns and "|cff00ff00是|r" or "|cffff0000否|r"))
        
        -- 检查装备的饰品
        print("")
        print("|cff00ffff【装备检测】|r")
        
        -- 饰品1
        local item1Link = GetInventoryItemLink("player", 13)
        if item1Link then
            local name1, _, _, itemLevel1 = GetItemInfo(item1Link)
            print("饰品1 (槽位13): |cff00ff00" .. (name1 or "未知") .. "|r")
            print("  └─ 物品等级: " .. (itemLevel1 or "?"))
            
            -- 检查CD
            local start1, duration1 = GetInventoryItemCooldown("player", 13)
            if start1 and duration1 and duration1 > 0 then
                local remaining = duration1 - (GetTime() - start1)
                if remaining > 0 then
                    print("  └─ 冷却中: " .. string.format("%.1f", remaining) .. " 秒")
                else
                    print("  └─ |cff00ff00可使用|r")
                end
            else
                print("  └─ |cff00ff00可使用|r")
            end
        else
            print("饰品1 (槽位13): |cffaaaaaa未装备|r")
        end
        
        -- 饰品2
        local item2Link = GetInventoryItemLink("player", 14)
        if item2Link then
            local name2, _, _, itemLevel2 = GetItemInfo(item2Link)
            print("饰品2 (槽位14): |cff00ff00" .. (name2 or "未知") .. "|r")
            print("  └─ 物品等级: " .. (itemLevel2 or "?"))
            
            -- 检查CD
            local start2, duration2 = GetInventoryItemCooldown("player", 14)
            if start2 and duration2 and duration2 > 0 then
                local remaining = duration2 - (GetTime() - start2)
                if remaining > 0 then
                    print("  └─ 冷却中: " .. string.format("%.1f", remaining) .. " 秒")
                else
                    print("  └─ |cff00ff00可使用|r")
                end
            else
                print("  └─ |cff00ff00可使用|r")
            end
        else
            print("饰品2 (槽位14): |cffaaaaaa未装备|r")
        end
        
        -- 检查大技能状态
        print("")
        print("|cff00ffff【大技能状态】|r")
        if S.Recklessness then
            local reckReady = S.Recklessness:ready()
            local reckCD = S.Recklessness:getcd() or 0
            print("鲁莽: " .. (reckReady and "|cff00ff00就绪|r" or string.format("|cffaaaaaa%.1f秒|r", reckCD)))
        end
        if S.Avatar then
            local avatarReady = S.Avatar:ready()
            local avatarCD = S.Avatar:getcd() or 0
            print("天神下凡: " .. (avatarReady and "|cff00ff00就绪|r" or string.format("|cffaaaaaa%.1f秒|r", avatarCD)))
        end
        
        -- 战斗状态
        print("")
        print("|cff00ffff【战斗状态】|r")
        if player and player.combat then
            print("战斗状态: |cff00ff00是|r")
            local combatTime = GetTime() - combatStartTime
            print("战斗时间: " .. string.format("%.1f", combatTime) .. " 秒")
        else
            print("战斗状态: |cffaaaaaa否|r")
            print("|cffffff00提示: 需要在战斗中才会使用饰品|r")
        end
        
        -- 系统状态
        print("")
        print("|cff00ffff【系统状态】|r")
        print("饰品使用方式: 动态创建（每次使用时根据装备槽位自动创建）")
        
        -- 尝试获取物品ID
        local itemID1 = GetInventoryItemID("player", 13)
        local itemID2 = GetInventoryItemID("player", 14)
        if itemID1 then
            print("饰品1物品ID: " .. itemID1)
        end
        if itemID2 then
            print("饰品2物品ID: " .. itemID2)
        end
        
        print("|cffff00ff===================================|r")
    end, "测试饰品系统")
    
    -- print("|cff00ff00[TT狂战]|r 宏命令已注册:")
    -- print("  |cff00ffff/aurora cd [on/off]|r - 切换爆发技能")
    -- print("  |cff00ffff/aurora debug [on/off]|r - 切换调试模式")
    -- print("  |cff00ffff/aurora status|r - 显示当前状态")
    -- print("  |cff00ffff/aurora er <数值>|r - 设置狂暴回复阈值")
    -- print("  |cff00ffff/aurora int [on/off]|r - 切换自动中断")
    -- print("  |cff00ffff/aurora intlist [on/off]|r - 切换列表中断")
    -- print("  |cff00ffff/aurora intfix|r - 修复中断列表")
    -- print("  |cff00ffff/aurora intlist-info|r - 查看列表状态")
    -- print("  |cff00ffff/aurora inttest|r - 测试中断系统")
    -- print("  |cff00ffff/aurora roartest|r - 测试雷鸣之吼")
    -- print("  |cff00ffff/aurora rotation|r - |cffff8800显示当前手法状态|r")
    -- print("  |cff00ffff/aurora testdraw|r - 测试范围显示")
    -- print("  |cff00ffff/aurora trinkettest|r - |cffff00ff测试饰品系统|r")
    
    -- 测试范围显示
    Aurora.Macro:RegisterCommand("testdraw", function()
        print("|cffff00ff========== 范围显示测试 ==========|r")
        
        -- 检查 Aurora.Draw
        if not Aurora.Draw then
            print("|cffff0000[错误]|r Aurora.Draw 不存在")
            return
        end
        print("|cff00ff00✓|r Aurora.Draw 已加载")
        
        -- 检查配置
        print("|cff00ff00✓|r 显示开关: " .. (cfg.showWhirlwindRange and "开启" or "关闭"))
        print("|cff00ff00✓|r 透明度: " .. tostring(cfg.whirlwindRangeOpacity))
        
        -- 检查状态
        if player and player.combat then
            print("|cff00ff00✓|r 战斗中 - 应该能看到圆圈")
        else
            print("|cffffff00⚠|r 不在战斗中 - 进入战斗后才会显示")
        end
        
        print("|cff00ff00✓|r 范围: 5码")
        print("|cff00ff00✓|r 颜色: 战士职业色（棕橙色）")
        
        print("|cffff00ff===================================|r")
    end, "测试范围显示")
    
    -- 手法状态显示
    Aurora.Macro:RegisterCommand("rotation", function()
        print("|cffff00ff========== 当前手法状态 ==========|r")
        
        if not player or not player.combat then
            print("|cffffff00[提示]|r 不在战斗中")
            print("|cffff00ff===================================|r")
            return
        end
        
        -- 目标数量
        local enemies = player.enemiesaround(8) or 0
        print("🎯 周围敌人: " .. enemies .. "个")
        
        -- 判断手法分支
        local rotationType = "单体"
        if enemies >= cfg.aoeThreshold5 then
            rotationType = "大群体AOE (5+目标)"
        elseif enemies >= 2 then
            rotationType = "小群体 (2-4目标)"
        end
        print("📋 当前手法: |cff00ff00" .. rotationType .. "|r")
        
        -- 关键资源
        local rage = player.rage or 0
        local enrageUp = player.aura(A.Enrage)
        local enrageRem = enrageUp and (player.auraremains(A.Enrage) or 0) or 0
        print("💥 怒气: " .. rage .. "/100")
        print("😤 激怒: " .. (enrageUp and string.format("|cff00ff00是|r (%.1f秒)", enrageRem) or "|cffff0000否|r"))
        
        -- 旋风斩层数
        local mcStacks = player.auracount(A.MeatCleaver) or 0
        local mcRem = mcStacks > 0 and (player.auraremains(A.MeatCleaver) or 0) or 0
        if enemies >= 2 then
            print("🔄 血肉顺劈: " .. mcStacks .. "层" .. (mcStacks > 0 and string.format(" (%.1f秒)", mcRem) or ""))
        end
        
        -- 猝死状态
        local sdBuff = player.aura(A.SuddenDeath)
        local sdStacks = sdBuff and (player.auracount(A.SuddenDeath) or 0) or 0
        local sdRem = sdBuff and (player.auraremains(A.SuddenDeath) or 0) or 0
        print("⚔️  猝死: " .. (sdBuff and string.format("|cff00ff00%d层|r (%.1f秒)", sdStacks, sdRem) or "|cffaaaaaa无|r"))
        
        -- 目标印记
        if target and target.exists then
            local markStacks = target.auracount(A.ExecutionersWill) or 0
            print("🎯 处刑印记: " .. markStacks .. "层 (目标: " .. (target.name or "未知") .. ")")
        end
        
        -- 剑刃风暴CD
        local bladestormCD = S.Bladestorm:getcd() or 999
        local bladestormReady = bladestormCD == 0
        print("🌀 剑刃风暴: " .. (bladestormReady and "|cff00ff00就绪|r" or string.format("|cffaaaaaa%.1f秒|r", bladestormCD)))
        
        -- 怒击充能
        local rbCharges = S.RagingBlow:charges() or 0
        local rbMax = S.RagingBlow:maxcharges() or 2
        print("🔴 怒击充能: " .. rbCharges .. "/" .. rbMax)
        
        -- 5目标以上特殊提示
        if enemies >= cfg.aoeThreshold5 then
            print("")
            print("|cffffff00【大秘境实战提示】|r")
            
            -- 旋风斩层数建议
            if mcStacks < 3 then
                print("• ⚠️  旋风斩层数偏低，剑刃风暴前补到4层")
            elseif mcStacks >= 4 then
                print("• ✓ 旋风斩层数充足，可以剑刃风暴")
            end
            
            -- 怒击建议
            if enrageUp and rbCharges >= 2 then
                print("• ✓ 激怒+2充能，可多打1-2个怒击")
            elseif not enrageUp and rage >= 125 then
                print("• ⚠️  怒气高但无激怒，考虑打暴怒")
            end
            
            -- 猝死延后建议
            if sdBuff and bladestormReady and mcStacks >= 3 and rbCharges >= 1 then
                print("• 💡 可延后猝死，优先打怒击")
            end
            
            -- 收尾提示
            if target and target.exists then
                local targetHP = target.healthpercent or 100
                local markStacks = target.auracount(A.ExecutionersWill) or 0
                if targetHP <= 15 and markStacks >= 1 and bladestormCD > 3 then
                    print("• 🎯 目标即将死亡，打裸斩杀消耗印记！")
                end
            end
        end
        
        print("|cffff00ff===================================|r")
    end, "显示当前手法状态")
end

------------------------------------------------------------------------
-- 掠武风暴范围显示系统（简化版）
------------------------------------------------------------------------
-- 战斗中显示5码攻击范围圆圈
if Aurora.Draw then
    local Draw = Aurora.Draw
    
    Draw:RegisterCallback("whirlwindRange", function(canvas, unit)
        -- 检查配置开关
        if not cfg.showWhirlwindRange then return end
        
        -- 只为玩家绘制
        if not unit or unit.guid ~= UnitGUID("player") then return end
        
        -- 只在战斗中显示
        if not player or not player.combat then return end
        
        -- 获取透明度配 置
        local alpha = cfg.whirlwindRangeOpacity or 150
        
        -- 使用战士职业色
        local r, g, b, a = Draw:GetColor("Warrior", alpha)
        canvas:SetColor(r, g, b, a)
        
        -- 绘制5码范围圆圈
        canvas:Circle(player.position.x, player.position.y, player.position.z, 5)
    end, "units")
    
    -- 启用绘制系统
    Draw:Enable()
    -- print("|cff00ff00[TT狂战]|r 掠武风暴范围显示已加载（5码）")
end

------------------------------------------------------------------------
-- 专精变化热重载系统
------------------------------------------------------------------------
-- 监听专精变化事件，当从狂怒切换到其他专精时自动重载
-- 使用WoW标准事件: PLAYER_SPECIALIZATION_CHANGED

local specChangeFrame = CreateFrame("Frame")
local currentSpec = player.spec  -- 保存当前专精

-- 注册专精变化事件
specChangeFrame:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")
specChangeFrame:RegisterEvent("ACTIVE_TALENT_GROUP_CHANGED")

-- 事件处理函数
specChangeFrame:SetScript("OnEvent", function(self, event)
    -- 等待一小段时间确保专精信息已更新
    C_Timer.After(0.5, function()
        -- 重新获取player对象（确保获取最新信息）
        local updatedPlayer = Aurora.UnitManager:Get("player")
        if not updatedPlayer then return end
        
        local newSpec = updatedPlayer.spec
        local isWarrior = (updatedPlayer.class2 == "WARRIOR")
        
        -- 检测专精是否变化
        if currentSpec ~= newSpec then
            -- 专精已变化
            if isWarrior then
                if newSpec == 2 then
                    -- 切换到狂怒天赋
                    -- print("|cff00ff00[TT狂战]|r 检测到切换为狂怒天赋 (Spec: " .. newSpec .. ")")
                    -- print("|cff00ff00[TT狂战]|r 正在自动重载以加载模块...")
                    C_Timer.After(0.1, function()
                        ReloadUI()
                    end)
                elseif currentSpec == 2 then
                    -- 从狂怒切换到武器或防护
                    -- local specName = "未知"
                    -- if newSpec == 1 then
                    --     specName = "武器"
                    -- elseif newSpec == 3 then
                    --     specName = "防护"
                    -- end
                    -- print("|cffffff00[TT狂战]|r 检测到切换为" .. specName .. "天赋 (Spec: " .. newSpec .. ")")
                    -- print("|cffffff00[TT狂战]|r 正在自动重载以卸载模块...")
                    C_Timer.After(0.1, function()
                        ReloadUI()
                    end)
                end
            end
            
            -- 更新当前专精记录
            currentSpec = newSpec
        end
    end)
end)

-- print("|cff00ff00[TT狂战]|r 专精变化热重载系统已启用")
-- print("|cffffff00[提示]|r 切换天赋后将自动重载界面")

------------------------------------------------------------------------
-- 状态框架 - 自动目标切换按钮
------------------------------------------------------------------------
-- 使用Aurora全局状态框架添加可视化切换按钮
-- 注意：Interrupt 按钮由 Aurora 框架自动创建，无需手动添加

-- 添加自动目标切换按钮到状态栏
Aurora.Rotation.AutoTargetToggle = Aurora:AddGlobalToggle({
    label = "自动目标",              -- 显示文本（最多11个字符）
    var = "fury_auto_target",        -- 唯一标识符
    icon = 132336,                   -- 致命打击图标（Ability_Warrior_Savageblow - 红色战士拳头）
    tooltip = "自动目标切换\n\n启用后:\n• 目标死亡/不存在 → 自动选择新目标\n• 目标超出近战范围 → 切换到最近的敌人\n• 自动检测视线（LOS）\n\n当前范围: 8码近战范围",
    onClick = function(value)
        -- 同步到配置系统
        Aurora.Config:Write("fury.autoTarget", value)
        
        -- 显示状态提示
        if value then
            print("|cff00ff00━━━━━━━━━━━━━━━━━━━━━━━━|r")
            print("|cff00ff00[自动目标]|r ✅ 已启用")
            print("|cff00ffff• 目标死亡 → 自动切换|r")
            print("|cff00ffff• 超出范围 → 切换最近目标|r")
            print("|cff00ffff• 自动检测视线|r")
            print("|cff00ff00━━━━━━━━━━━━━━━━━━━━━━━━|r")
        else
            print("|cffff0000━━━━━━━━━━━━━━━━━━━━━━━━|r")
            print("|cffff0000[自动目标]|r ❌ 已禁用")
            print("|cff808080需要手动切换目标|r")
            print("|cffff0000━━━━━━━━━━━━━━━━━━━━━━━━|r")
        end
    end
})

-- 初始化：从配置读取状态并同步到状态栏
C_Timer.After(0.5, function()
    local savedState = Aurora.Config:Read("fury.autoTarget")
    if savedState ~= nil then
        Aurora.Rotation.AutoTargetToggle:SetValue(savedState)
    end
end)

------------------------------------------------------------------------
-- 快捷命令系统 - 自动目标切换控制
------------------------------------------------------------------------
-- 注册快捷命令来快速控制自动目标切换功能

-- 创建斜杠命令框架
SLASH_FURYTARGET1 = "/fury"
SLASH_FURYTARGET2 = "/狂怒"

-- 命令处理函数
SlashCmdList["FURYTARGET"] = function(msg)
    -- 处理空命令
    if not msg or msg == "" then
        msg = "help"
    end
    
    local command = string.lower(strtrim(msg))
    
    -- /fury test - 测试命令是否工作
    if command == "test" then
        print("|cff00ff00[TT狂战]|r Slash命令系统正常工作！")
        print("命令输入: " .. tostring(msg))
        return
    end
    
    -- /fury target - 快速开关自动目标切换
    if command == "target" or command == "目标" then
        -- 获取当前状态（优先从状态栏按钮）
        local current = false
        if Aurora.Rotation.AutoTargetToggle then
            current = Aurora.Rotation.AutoTargetToggle:GetValue()
        else
            current = Aurora.Config:Read("fury.autoTarget")
        end
        
        local newValue = not current
        
        -- 同步到状态栏按钮和配置
        if Aurora.Rotation.AutoTargetToggle then
            Aurora.Rotation.AutoTargetToggle:SetValue(newValue)
        end
        Aurora.Config:Write("fury.autoTarget", newValue)
        
        print("|cff00ff00━━━━━━━━━━━━━━━━━━━━━━━━|r")
        print("|cff00ff00[TT狂战]|r 自动目标切换")
        print(" ")
        if newValue then
            print("|cff00ff00✅ 已启用|r")
            print(" ")
            print("|cff00ffff功能:|r")
            print("  • 目标死亡/不存在 → 自动选择新目标")
            print("  • 目标超出近战范围 → 切换到最近的敌人")
            print("  • 自动检测视线（LOS）")
            print(" ")
            local range = Aurora.Config:Read("fury.autoTargetRange") or 8
            print("|cff808080当前范围:|r " .. range .. "码")
        else
            print("|cffff0000❌ 已禁用|r")
            print(" ")
            print("|cff808080目标切换将需要手动操作|r")
        end
        print("|cff00ff00━━━━━━━━━━━━━━━━━━━━━━━━|r")
        return
    end
    
    -- /fury target status - 查看当前状态
    if command == "target status" or command == "目标 状态" or command == "target state" then
        -- 优先从状态栏按钮读取
        local enabled = false
        if Aurora.Rotation.AutoTargetToggle then
            enabled = Aurora.Rotation.AutoTargetToggle:GetValue()
        else
            enabled = Aurora.Config:Read("fury.autoTarget")
        end
        local range = Aurora.Config:Read("fury.autoTargetRange") or 8
        
        print("|cff00ff00━━━━━━━━━━━━━━━━━━━━━━━━|r")
        print("|cff00ff00[TT狂战]|r 自动目标切换状态")
        print(" ")
        print("|cff00ffff状态:|r " .. (enabled and "|cff00ff00已启用 ✅|r" or "|cffff0000已禁用 ❌|r"))
        print("|cff00ffff范围:|r " .. range .. "码")
        print(" ")
        if enabled then
            print("|cff808080工作模式:|r")
            print("  • 检测目标是否在近战范围内")
            print("  • 自动切换到" .. range .. "码内最近的敌人")
            print("  • 检测视线和距离")
        else
            print("|cff808080输入 |cff00ff00/fury target|r 快速启用")
        end
        print("|cff00ff00━━━━━━━━━━━━━━━━━━━━━━━━|r")
        return
    end
    
    -- /fury target on - 强制开启
    if command == "target on" or command == "目标 开" or command == "target enable" then
        if Aurora.Rotation.AutoTargetToggle then
            Aurora.Rotation.AutoTargetToggle:SetValue(true)
        end
        Aurora.Config:Write("fury.autoTarget", true)
        print("|cff00ff00[TT狂战]|r 自动目标切换 |cff00ff00已启用 ✅|r")
        return
    end
    
    -- /fury target off - 强制关闭
    if command == "target off" or command == "目标 关" or command == "target disable" then
        if Aurora.Rotation.AutoTargetToggle then
            Aurora.Rotation.AutoTargetToggle:SetValue(false)
        end
        Aurora.Config:Write("fury.autoTarget", false)
        print("|cff00ff00[TT狂战]|r 自动目标切换 |cffff0000已禁用 ❌|r")
        return
    end
    
    -- /fury debug - 调试打断开关
    if command == "debug" then
        print("|cff00ff00━━━━━━━━━━━━━━━━━━━━━━━━|r")
        print("|cff00ff00[TT狂战]|r 打断开关调试")
        print(" ")
        
        -- 读取原始配置值
        local rawPummel = Aurora.Config:Read("fury.usePummel")
        print("|cff00ffffGUI配置原始值:|r")
        print("  fury.usePummel = " .. tostring(rawPummel) .. " (type: " .. type(rawPummel) .. ")")
        
        -- 通过 cfg 访问器读取
        print(" ")
        print("|cff00ffffcfg 访问器读取值:|r")
        print("  cfg.usePummel = " .. tostring(cfg.usePummel) .. " (type: " .. type(cfg.usePummel) .. ")")
        
        -- 检查 Aurora.Rotation
        print(" ")
        print("|cff00ffffAurora.Rotation 状态:|r")
        if Aurora and Aurora.Rotation then
            print("  Aurora.Rotation 存在: true")
            
            local toggleNames = {"InterruptToggle", "Interrupts", "InterruptsToggle"}
            for _, name in ipairs(toggleNames) do
                local toggle = Aurora.Rotation[name]
                if toggle then
                    print("  " .. name .. " 存在: true")
                    if type(toggle.GetValue) == "function" then
                        local value = toggle:GetValue()
                        print("  " .. name .. ":GetValue() = " .. tostring(value))
                    end
                else
                    print("  " .. name .. " 存在: false")
                end
            end
        else
            print("  Aurora.Rotation 不存在")
        end
        
        print("|cff00ff00━━━━━━━━━━━━━━━━━━━━━━━━|r")
        return
    end
    
    -- /fury toggles - 列出所有Aurora Toggle（调试用）
    if command == "toggles" or command == "list" then
        print("|cff00ff00━━━━━━━━━━━━━━━━━━━━━━━━|r")
        print("|cff00ff00[TT狂战]|r Aurora Toggle 列表")
        print(" ")
        
        if Aurora and Aurora.Rotation then
            print("|cff00ffffAurora.Rotation 中的所有对象:|r")
            local count = 0
            for key, value in pairs(Aurora.Rotation) do
                if type(value) == "table" and type(value.GetValue) == "function" then
                    local val = value:GetValue()
                    print(string.format("  |cff00ff00%s|r = %s (类型: Toggle)", key, tostring(val)))
                    count = count + 1
                elseif type(value) ~= "function" then
                    print(string.format("  |cff808080%s|r (类型: %s)", key, type(value)))
                end
            end
            print(" ")
            print(string.format("找到 |cff00ff00%d|r 个 Toggle", count))
        else
            print("|cffff0000Aurora.Rotation 不存在|r")
        end
        
        print("|cff00ff00━━━━━━━━━━━━━━━━━━━━━━━━|r")
        return
    end
    
    -- /fury interrupt 或 /fury 打断 - 查看打断状态
    if command == "interrupt" or command == "打断" or command == "interrupt status" then
        print("|cff00ff00━━━━━━━━━━━━━━━━━━━━━━━━|r")
        print("|cff00ff00[TT狂战]|r 打断系统状态")
        print(" ")
        
        -- 检查打断总开关状态
        local interruptEnabled = true
        local toggleFound = false
        local toggleName = "未知"
        
        if Aurora and Aurora.Rotation then
            -- 尝试多个可能的Toggle名称
            local possibleNames = {"Interrupt", "Interrupts", "interrupt", "interrupts"}
            for _, name in ipairs(possibleNames) do
                local toggle = Aurora.Rotation[name]
                if toggle and type(toggle.GetValue) == "function" then
                    interruptEnabled = toggle:GetValue()
                    toggleFound = true
                    toggleName = name
                    break
                end
            end
        end
        
        print("|cff00ffffAurora状态栏 - Interrupt:|r")
        if toggleFound then
            if interruptEnabled then
                print(string.format("  |cff00ff00✅ 已启用|r (Toggle: %s)", toggleName))
                print("  |cff808080可用命令: /aurora toggle interrupt|r")
            else
                print(string.format("  |cffff0000❌ 已禁用 (所有打断失效)|r (Toggle: %s)", toggleName))
                print("  |cff808080可用命令: /aurora toggle interrupt|r")
            end
        else
            print("  |cffff8800⚠ 未找到任何Interrupt Toggle|r")
            print("  |cff808080提示: 运行 /fury toggles 查看所有可用Toggle|r")
        end
        print(" ")
        
        -- 检查GUI配置
        print("|cff00ffffGUI配置状态:|r")
        
        local usePummel = cfg.usePummel
        local useStormBolt = cfg.useStormBolt
        local useShockwave = cfg.useShockwave
        
        if usePummel then
            print("  拳击: |cff00ff00✅ 已启用|r")
        else
            print("  拳击: |cffff0000❌ 已禁用|r")
        end
        
        if useStormBolt then
            print("  风暴之锤: |cff00ff00✅ 已启用|r (对Boss无效)")
        else
            print("  风暴之锤: |cffff0000❌ 已禁用|r")
        end
        
        if useShockwave then
            print("  震荡波: |cff00ff00✅ 已启用|r (对Boss无效)")
        else
            print("  震荡波: |cffff0000❌ 已禁用|r")
        end
        print(" ")
        
        -- 检查列表配置
        print("|cff00ffff列表配置:|r")
        local useList = cfg.interruptWithList
        if useList then
            print("  使用Aurora列表: |cff00ff00✅ 已启用|r")
            if Aurora.Lists and Aurora.Lists.InterruptSpells then
                local listCount = #Aurora.Lists.InterruptSpells
                if listCount > 0 then
                    print("  列表技能数: |cff00ff00" .. listCount .. "|r")
                else
                    print("  |cffff8800⚠ 列表为空，将打断所有技能|r")
                end
            else
                print("  |cffff8800⚠ 列表不存在，将打断所有技能|r")
            end
        else
            print("  使用Aurora列表: |cffff0000❌ 已禁用 (打断所有技能)|r")
        end
        print(" ")
        
        -- 检查阈值设置
        print("|cff00ffff打断阈值:|r")
        print("  施法进度: |cff00ff00" .. (cfg.interruptCastPercent or 60) .. "%|r")
        print("  风暴之锤读条怪数: |cff00ff00" .. (cfg.stormBoltEnemyCount or 1) .. "|r")
        print("  震荡波读条怪数: |cff00ff00" .. (cfg.shockwaveEnemyCount or 2) .. "|r")
        print(" ")
        
        -- 最终状态
        if interruptEnabled and (usePummel or useStormBolt or useShockwave) then
            print("|cff00ff00✅ 打断系统正常工作|r")
        elseif not interruptEnabled then
            print("|cffff0000❌ 打断系统已禁用 (Interrupt按钮关闭)|r")
        else
            print("|cffff0000❌ 所有打断技能都已关闭|r")
        end
        
        print("|cff00ff00━━━━━━━━━━━━━━━━━━━━━━━━|r")
        return
    end
    
    -- /fury help - 显示帮助
    if command == "help" or command == "帮助" or command == "" then
        print("|cff00ff00━━━━━━━━━━━━━━━━━━━━━━━━|r")
        print("|cff00ff00[TT狂战]|r 快捷命令帮助")
        print(" ")
        print("|cff00ffff自动目标切换:|r")
        print("  |cff00ff00/fury target|r - 快速开关")
        print("  |cff00ff00/fury target status|r - 查看状态")
        print("  |cff00ff00/fury target on|r - 强制开启")
        print("  |cff00ff00/fury target off|r - 强制关闭")
        print(" ")
        print("|cff00ffff打断系统:|r")
        print("  |cff00ff00/fury interrupt|r - 查看打断状态")
        print("  |cff00ff00/fury toggles|r - 列出所有Aurora Toggle（调试）")
        print("  |cff00ff00/fury debug|r - 调试打断开关")
        print(" ")
        print("|cff00ffff其他命令:|r")
        print("  |cff00ff00/aurora|r - 打开设置界面")
        print("|cff00ff00━━━━━━━━━━━━━━━━━━━━━━━━|r")
        return
    end
    
    -- 未知命令
    print("|cffff0000[TT狂战]|r 未知命令: " .. msg)
    print("|cff00ffff输入 |cff00ff00/fury help|r 查看帮助")
end

------------------------------------------------------------------------
-- 加载完成通知
------------------------------------------------------------------------

-- 延迟显示 Toast 通知，确保所有内容都加载完成
C_Timer.After(2.5, function()
    if Aurora and Aurora.Toast and Aurora.Config then
        local currentVersion = MythicWarrior.Version or "2.1.0"
        local lastSeenVersion = Aurora.Config:Read("fury.lastSeenVersion") or "0.0.0"
        local playerName = UnitName("player") or "战士"
        
        -- 检查是否为新版本
        if currentVersion ~= lastSeenVersion then
            -- 保存当前版本
            Aurora.Config:Write("fury.lastSeenVersion", currentVersion)
            
            -- 判断是首次使用还是更新
            if lastSeenVersion == "0.0.0" then
                -- 首次使用
                Aurora.Toast:Show(
                    string.format("TT狂战 v%s", currentVersion),
                    string.format("欢迎, %s! 输入 /fury help 查看命令", playerName)
                )
            else
                -- 版本更新
                Aurora.Toast:Show(
                    string.format("TT狂战已更新至 v%s", currentVersion),
                    "优化：移除调试信息 | 打断默认值优化"
                )
            end
        end
    end
end)

return MythicWarrior
