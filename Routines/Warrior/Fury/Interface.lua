--[[--------------------------------------------------------------------
    TT狂战 · 技能回调接口
----------------------------------------------------------------------]]

local MythicWarrior = ...

-- 获取玩家和技能书
local player = Aurora.UnitManager:Get("player")
local S = Aurora.SpellHandler.Spellbooks.warrior["2"].TTFury.spells

------------------------------------------------------------------------
-- 配置访问器
------------------------------------------------------------------------

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

-- 配置访问器
local cfg = setmetatable({}, {
    __index = function(t, key)
        if key == "usePummel" then return GetConfig("usePummel", true) end
        if key == "useStormBolt" then return GetConfig("useStormBolt", true) end
        if key == "useShockwave" then return GetConfig("useShockwave", true) end
        if key == "stormBoltEnemyCount" then return GetConfig("stormBoltEnemyCount", 1) end
        if key == "shockwaveEnemyCount" then return GetConfig("shockwaveEnemyCount", 2) end
        if key == "interruptCastPercent" then return GetConfig("interruptCastPercent", 30) end
        return nil
    end
})

------------------------------------------------------------------------
-- 智能打断系统
------------------------------------------------------------------------

-- 检查Aurora打断开关状态（支持多种可能的Toggle名称）
local function IsInterruptEnabled()
    if not Aurora or not Aurora.Rotation then
        return true -- Aurora不存在时，默认启用
    end
    
    -- 尝试多个可能的Toggle名称
    local toggleNames = {
        "InterruptToggle",  -- 主要名称
        "Interrupts",       -- 备选名称1
        "InterruptsToggle", -- 备选名称2
    }
    
    for _, name in ipairs(toggleNames) do
        local toggle = Aurora.Rotation[name]
        if toggle and type(toggle.GetValue) == "function" then
            return toggle:GetValue()
        end
    end
    
    -- 如果找不到任何打断Toggle，默认启用
    return true
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
                local minCastPct = cfg.interruptCastPercent or 30
                
                if castPct >= minCastPct then
                    count = count + 1
                    table.insert(castingEnemies, enemy)
                end
            end
        end
    end)
    
    return count, castingEnemies
end

-- 拳击（Pummel）- 单体打断，15秒CD
S.Pummel:callback(function(spell, logic)
    -- 检查是否启用拳击
    if not cfg.usePummel then
        return false
    end
    
    -- 检查是否启用中断（受Aurora Cooldown框架控制）
    if not IsInterruptEnabled() then
        return false
    end
    
    local castingCount = CountCastingEnemies()
    
    -- 只有1个读条怪时，优先使用拳击（CD最短）
    if castingCount == 1 then
        Aurora.activeenemies:each(function(enemy)
            if enemy.casting or enemy.channeling then
                if enemy.castinginterruptible or enemy.channelinginterruptible then
                    -- 检查施法进度
                    local castPct = enemy.castingpct or 0
                    local minCastPct = cfg.interruptCastPercent or 30
                    
                    if castPct >= minCastPct then
                        return spell:cast(enemy)
                    end
                end
            end
        end)
    end
end)

-- 风暴之锤（Storm Bolt）- 单体打断+眩晕，30秒CD
-- 注意：对Boss无效（眩晕效果），只能用于小怪
S.StormBolt:callback(function(spell, logic)
    -- 检查是否启用风暴之锤
    if not cfg.useStormBolt then
        return false
    end
    
    -- 检查是否启用中断（受Aurora Cooldown框架控制）
    if not IsInterruptEnabled() then
        return false
    end
    
    local castingCount = CountCastingEnemies()
    local enemyCountThreshold = cfg.stormBoltEnemyCount or 1
    
    -- 只有当读条怪物数量 >= 阈值，且拳击CD时，使用风暴之锤
    if castingCount >= enemyCountThreshold and S.Pummel:getcd() > 0 then
        Aurora.activeenemies:each(function(enemy)
            if enemy.casting or enemy.channeling then
                if enemy.castinginterruptible or enemy.channelinginterruptible then
                    -- 检查是否为Boss（风暴之锤对Boss无效）
                    if enemy.isboss then
                        return false
                    end
                    
                    -- 检查施法进度
                    local castPct = enemy.castingpct or 0
                    local minCastPct = cfg.interruptCastPercent or 30
                    
                    if castPct >= minCastPct then
                        return spell:cast(enemy)
                    end
                end
            end
        end)
    end
end)

-- 震荡波（Shockwave）- AOE打断+眩晕，40秒CD，范围10码
-- 注意：对Boss无效（眩晕效果），只能用于小怪
S.Shockwave:callback(function(spell, logic)
    -- 检查是否启用震荡波
    if not cfg.useShockwave then
        return false
    end
    
    -- 检查是否启用中断（受Aurora Cooldown框架控制）
    if not IsInterruptEnabled() then
        return false
    end
    
    local castingCount, castingEnemies = CountCastingEnemies()
    local enemyCountThreshold = cfg.shockwaveEnemyCount or 2
    
    -- 当读条怪物数量 >= 阈值时，优先使用震荡波（范围打断更划算）
    if castingCount >= enemyCountThreshold then
        -- 找到读条怪物最密集的位置
        for _, enemy in ipairs(castingEnemies) do
            -- Boss免疫震荡波的眩晕效果，跳过
            if not enemy.isboss then
                local nearbyCount = 0
                for _, other in ipairs(castingEnemies) do
                    if not other.isboss and other.distanceto(enemy) <= 10 then
                        nearbyCount = nearbyCount + 1
                    end
                end
                
                -- 如果这个位置能打断足够多怪物，立即释放
                if nearbyCount >= enemyCountThreshold then
                    return spell:cast(player)
                end
            end
        end
    end
    
    -- 单个读条怪（非Boss），且拳击和风暴之锤都CD时，使用震荡波兜底
    if castingCount >= 1 and S.Pummel:getcd() > 0 and S.StormBolt:getcd() > 0 then
        Aurora.activeenemies:each(function(enemy)
            if enemy.casting or enemy.channeling then
                if enemy.castinginterruptible or enemy.channelinginterruptible then
                    -- Boss免疫震荡波，跳过
                    if enemy.isboss then
                        return false
                    end
                    
                    -- 检查敌人是否在震荡波范围内（10码）
                    if enemy.distanceto(player) <= 10 then
                        -- 检查施法进度
                        local castPct = enemy.castingpct or 0
                        local minCastPct = cfg.interruptCastPercent or 30
                        
                        if castPct >= minCastPct then
                            return spell:cast(player)
                        end
                    end
                end
            end
        end)
    end
end)

return MythicWarrior
