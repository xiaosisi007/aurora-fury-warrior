--[[--------------------------------------------------------------------
    TT狂战 · 技能回调接口
----------------------------------------------------------------------]]

local MythicWarrior = ...

-- 获取玩家和技能书
local player = Aurora.UnitManager:Get("player")
local S = Aurora.SpellHandler.Spellbooks.warrior["2"].TTFury.spells

------------------------------------------------------------------------
-- 技能回调系统
------------------------------------------------------------------------

-- 集结呐喊 (Rally Cry) - 团队防御技能
S.RallyCry:callback(function(spell, logic)
    -- 读取配置（直接使用Aurora.Config）
    local useRallyCry = Aurora.Config:Read("fury.rallyCry.enabled")
    if useRallyCry == false then return false end
    
    -- 只在副本中释放（地牢、团队副本、大秘境）
    if not (player.ininstance or player.inraid or player.indelve) then
        return false
    end
    
    local threshold = Aurora.Config:Read("fury.rallyCry.threshold") or 50
    local requiredCount = Aurora.Config:Read("fury.rallyCry.playerCount") or 2
    local lowHealthCount = 0
    
    -- 检查玩家自己
    if player.exists and player.healthpercent <= threshold then
        -- 确保玩家不在坐骑上或载具中
        if not player.mounted and not player.invehicle then
            lowHealthCount = lowHealthCount + 1
        end
    end
    
    -- 检查小队成员（使用Aurora.fgroup包含玩家）
    if Aurora.fgroup then
        Aurora.fgroup:each(function(member)
            if member.exists and member.alive and member.guid ~= player.guid then
                -- 排除在坐骑上或载具中的队友（无法接收buff）
                if not member.mounted and not member.invehicle then
                    if member.healthpercent <= threshold then
                        lowHealthCount = lowHealthCount + 1
                    end
                end
            end
        end)
    end
    
    -- 当低血量队友数量达到要求时释放
    if lowHealthCount >= requiredCount then
        return spell:cast(player)
    end
    
    return false
end)

-- 这里可以添加其他技能的 callback
-- 打断系统已经移到 Rotation.lua 中

return MythicWarrior
