--[[--------------------------------------------------------------------
    屠戮狂战 · 技能回调接口
----------------------------------------------------------------------]]

local MythicWarrior = ...

-- 获取玩家和技能书
local player = Aurora.UnitManager:Get("player")
local S = Aurora.SpellHandler.Spellbooks.warrior["2"].MythicWarrior.spells

------------------------------------------------------------------------
-- 智能打断系统
------------------------------------------------------------------------

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
                count = count + 1
                table.insert(castingEnemies, enemy)
            end
        end
    end)
    
    return count, castingEnemies
end

-- 拳击（Pummel）- 单体打断，15秒CD
S.Pummel:callback(function(spell, logic)
    local castingCount = CountCastingEnemies()
    
    -- 只有1个读条怪时，优先使用拳击（CD最短）
    if castingCount == 1 then
        Aurora.activeenemies:each(function(enemy)
            if enemy.casting or enemy.channeling then
                if enemy.castinginterruptible or enemy.channelinginterruptible then
                    return spell:cast(enemy)
                end
            end
        end)
    end
end)

-- 风暴之锤（Storm Bolt）- 单体打断+眩晕，30秒CD
S.StormBolt:callback(function(spell, logic)
    local castingCount = CountCastingEnemies()
    
    -- 只有1个读条怪，且拳击CD时，使用风暴之锤
    if castingCount == 1 and S.Pummel:getcd() > 0 then
        Aurora.activeenemies:each(function(enemy)
            if enemy.casting or enemy.channeling then
                if enemy.castinginterruptible or enemy.channelinginterruptible then
                    return spell:cast(enemy)
                end
            end
        end)
    end
end)

-- 震荡波（Shockwave）- AOE打断+眩晕，40秒CD，范围10码
S.Shockwave:callback(function(spell, logic)
    local castingCount, castingEnemies = CountCastingEnemies()
    
    -- 2个或以上读条怪时，优先使用震荡波（范围打断更划算）
    if castingCount >= 2 then
        -- 找到读条怪物最密集的位置
        for _, enemy in ipairs(castingEnemies) do
            local nearbyCount = 0
            for _, other in ipairs(castingEnemies) do
                if other.distanceto(enemy) <= 10 then
                    nearbyCount = nearbyCount + 1
                end
            end
            
            -- 如果这个位置能打断2个或以上，立即释放
            if nearbyCount >= 2 then
                return spell:cast(player)
            end
        end
    end
    
    -- 单个读条怪，且拳击和风暴之锤都CD时，使用震荡波兜底
    if castingCount == 1 and S.Pummel:getcd() > 0 and S.StormBolt:getcd() > 0 then
        Aurora.activeenemies:each(function(enemy)
            if enemy.casting or enemy.channeling then
                if enemy.castinginterruptible or enemy.channelinginterruptible then
                    -- 检查敌人是否在震荡波范围内（10码）
                    if enemy.distanceto(player) <= 10 then
                        return spell:cast(player)
                    end
                end
            end
        end)
    end
end)

return MythicWarrior
