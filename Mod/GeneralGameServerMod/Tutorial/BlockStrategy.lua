--[[
Author: wxa
Date: 2020-10-26
Desc: 新手引导API 
-----------------------------------------------
local BlockStrategy = NPL.load("Mod/GeneralGameServerMod/Tutorial/BlockStrategy.lua");
-----------------------------------------------
]]


local BlockStrategy = commonlib.inherit(commonlib.gettable("System.Core.ToolBase"), NPL.export());

function BlockStrategy:ctor()
end

function BlockStrategy:Init(strategy)
    self.type = strategy.type or "BlockId";
    self.blockId = strategy.blockId or 0;
    self.blockIdList = strategy.blockIdList or {};
    self.minBlockId = strategy.minBlockId or 0;
    self.maxBlockId = strategy.maxBlockId or 0; 
    self.blockPosList = strategy.blockPosList or {};
    self.blockX = strategy.blockX or 0;
    self.blockY = strategy.blockY or 0;
    self.blockZ = strategy.blockZ or 0;
    self.minBlockX = strategy.minBlockX or 0;
    self.minBlockY = strategy.minBlockY or 0;
    self.minBlockZ = strategy.minBlockZ or 0;
    self.maxBlockX = strategy.maxBlockX or 0;
    self.maxBlockY = strategy.maxBlockY or 0;
    self.maxBlockZ = strategy.maxBlockZ or 0;
    -- shift ctrl alt key state = 0 禁止按下 1 按下 2 忽略  
    self.shiftKeyState = strategy.shiftKeyState or 0;
    self.ctrlKeyState = strategy.ctrlKeyState or 0;
    self.altKeyState = strategy.altKeyState or 0;
    self.mouseKeyState = strategy.mouseKeyState or 3;
    self.handBlockId = strategy.handBlockId;
    self.eventType = strategy.eventType;
    return self;
end

function BlockStrategy:IsMatchEventType(blockData)
    if (not self.eventType) then return true end
    if (self.eventType == blockData.event_type) then return true end
    if (type(self.eventType) == "table") then
        for _, event_type in ipairs(self.eventType) do
            if (self.eventType == event_type) then return true end
        end
    end
    return false;
end

function BlockStrategy:IsMatchKeyPressed(blockData)
    return (self.shiftKeyState == 2 or (self.shiftKeyState == 1 and blockData.shift_pressed) or (self.shiftKeyState == 0 and not blockData.shift_pressed)) 
        and (self.ctrlKeyState == 2 or (self.ctrlKeyState == 1 and blockData.ctrl_pressed) or (self.ctrlKeyState == 0 and not blockData.ctrl_pressed)) 
        and (self.altKeyState == 2 or (self.altKeyState == 1 and blockData.alt_pressed) or (self.altKeyState == 0 and not blockData.alt_pressed))
        and (self.mouseKeyState == 3 or self.mouseKeyState == blockData.mouseKeyState);
end

function BlockStrategy:IsMatchHandBlockId(blockData)
    if (not self.handBlockId) then return true end

    if (type(self.handBlockId) == "number") then return self.handBlockId == blockData.handBlockId end

    if (type(self.handBlockId) == "table") then 
        for _, blockId in ipairs(self.handBlockId) do
            if (blockId == blockData.handBlockId) then return true end
        end
    end

    if (type(self.handBlockId) == "function") then return self.handBlockId(blockData) end
 
    return false;
end

function BlockStrategy:IsMatchBlockIdType(blockData)
    for _, blockId in ipairs(self.blockIdList) do
        if (blockId == blockData.blockId) then return true end
    end

    return self.blockId == blockData.blockId;
end

function BlockStrategy:IsMatchBlockPosType(blockData)
    for _, pos in ipairs(self.blockPosList) do
        if (pos.blockX == blockData.blockX and pos.blockY == blockData.blockY and pos.blockZ == blockData.blockZ) then return true end
    end

    return self.blockX == blockData.blockX and self.blockY == blockData.blockY and self.blockZ == blockData.blockZ;
end

function BlockStrategy:IsMatchBlockPosIdType(blockData)
    return self:IsMatchBlockIdType(blockData) and self:IsMatchBlockPosType(blockData);
end

function BlockStrategy:IsMatchBlockIdRangeType(blockData)
    return blockData.blockId >= self.minBlockId and blockData.blockId <= self.maxBlockId;
end

function BlockStrategy:IsMatchBlockPosRangeType(blockData)
    return blockData.blockX >= self.minBlockX and blockData.blockX <= self.maxBlockX and blockData.blockY >= self.minBlockY and blockData.blockY <= self.maxBlockY and blockData.blockZ >= self.minBlockZ and blockData.blockZ <= self.maxBlockZ;
end

function BlockStrategy:IsMatchBlockPosRangeIdType(blockData)
    return self:IsMatchBlockPosRangeType(blockData) and self:IsMatchBlockIdType(blockData);
end

function BlockStrategy:IsMatchBlockPosIdRangeType(blockData)
    return self:IsMatchBlockPosType(blockData) and self:IsMatchBlockIdRangeType(blockData);
end

function BlockStrategy:IsMatchBlockPosRangeIdRangeType(blockData)
    return self:IsMatchBlockPosRangeType(blockData) and self:IsMatchBlockIdRangeType(blockData);
end

function BlockStrategy:IsMatch(blockData)
    -- 先检测功能key是否匹配
    if (not self:IsMatchEventType(blockData) or not self:IsMatchKeyPressed(blockData) or not self:IsMatchHandBlockId(blockData)) then return false end

    if (self.type == "BlockId") then 
        return self:IsMatchBlockIdType(blockData);
    elseif (self.type == "BlockPos") then
        return self:IsMatchBlockPosType(blockData);
    elseif (self.type == "BlockPosId") then
        return self:IsMatchBlockPosIdType(blockData);
    elseif (self.type == "BlockIdRange") then 
        return self:IsMatchBlockIdRangeType(blockData);
    elseif (self.type == "BlockPosRange") then
        return self:IsMatchBlockPosRangeType(blockData);
    elseif (self.type == "BlockPosRangeId") then
        return self:IsMatchBlockPosRangeIdType(blockData);
    elseif (self.type == "BlockPosIdRange") then
        return self:IsMatchBlockPosIdRangeType(blockData);
    elseif (self.type == "BlockPosRangeIdRange") then
        return self:IsMatchBlockPosRangeIdRangeType(blockData);
    elseif (self.type == "All") then
        return true;
    end

    return false;
end
