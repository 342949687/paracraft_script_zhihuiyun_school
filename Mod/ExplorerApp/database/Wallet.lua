--[[
Title: Wallet
Author(s):  big
Date: 2019.01.23
place: Foshan
Desc: 
use the lib:
------------------------------------------------------------
local Wallet = NPL.load("(gl)Mod/WorldShare/database/Wallet.lua")
------------------------------------------------------------
]]
local Utils = NPL.load("(gl)Mod/WorldShare/helper/Utils.lua")
local Store = NPL.load("(gl)Mod/WorldShare/store/Store.lua")

local Wallet = NPL.export()

-- TODO: Move to general class
function Wallet:GetAllData()
  local playerController = Store:Getter("user/GetPlayerController")

  if not playerController then
      playerController = GameLogic.GetPlayerController()
      local SetPlayerController = Store:Action("user/SetPlayerController")

      SetPlayerController(playerController)
  end

  local wallet = playerController:LoadLocalData("wallet", nil, true)

  if type(wallet) ~= "table" then
      return {}
  end

  return wallet
end

function Wallet:GetData(key)
    local allData = self:GetAllData()

    if type(allData) ~= 'table' then
        return false
    end

    return allData[key]
end

function Wallet:SetData(key, value)
    local allData = self:GetAllData()
    local playerController = Store:Getter("user/GetPlayerController")

    if not allData or not playerController then
        return false
    end

    allData[key] = value

    playerController:SaveLocalData("wallet", allData, true)
end

function Wallet:GetUserPassword()
    return self:GetData('password')
end

function Wallet:SetUserPassword(password)
    self:SetData('password', password)
end

function Wallet:GetUserBalance()
    return self:GetData('balance') or 0
end

function Wallet:SetUserBalance(coins)
    if not coins then
        return false
    end

    self:SetData('balance', coins)
end

function Wallet:GetPlayerBalance()
    return self:GetData('playerBalance') or 0
end

function Wallet:SetPlayerBalance(coins)
    if not coins then
        return false
    end

    self:SetData('playerBalance', coins)
end