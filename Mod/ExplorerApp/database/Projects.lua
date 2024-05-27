--[[
Title: Projects
Author(s):  big
Date: 2019.01.25
place: Foshan
Desc: 
use the lib:
------------------------------------------------------------
local Projects = NPL.load("(gl)Mod/WorldShare/database/Projects.lua")
------------------------------------------------------------
]]
local Utils = NPL.load("(gl)Mod/WorldShare/helper/Utils.lua")
local Store = NPL.load("(gl)Mod/WorldShare/store/Store.lua")

local Projects = NPL.export()

-- TODO: Move to general class
function Projects:GetAllData()
    local playerController = Store:Getter("user/GetPlayerController")

    if not playerController then
        playerController = GameLogic.GetPlayerController()
        local SetPlayerController = Store:Action("user/SetPlayerController")

        SetPlayerController(playerController)
    end

    local projects = playerController:LoadLocalData("projects", nil, true)

    if type(projects) ~= "table" then
        return {}
    end

    return projects
end

function Projects:GetData(key)
    local allData = self:GetAllData()

    if type(allData) ~= "table" then
        return false
    end

    return allData[key]
end

function Projects:SetData(key, value)
    local allData = self:GetAllData()
    local playerController = Store:Getter("user/GetPlayerController")

    if not allData or not playerController then
        return false
    end

    allData[key] = value

    playerController:SaveLocalData("projects", allData, true)
end

function Projects:IsProjectDownloaded(projectId)
    if not projectId then
        return false
    end

    local downloadedProjects = self:GetData("downloadedProjects") or {}

    if not downloadedProjects then
        return false
    end

    for key, item in ipairs(downloadedProjects) do
        if item.projectId == projectId then
            return true
        end
    end

    return false
end

function Projects:SetDownloadedProject(info)
    if not info or not info.id or not info.world then
        return false
    end

    local data = {
        projectId = info.id,
        world = info.world
    }

    local downloadedProjects = self:GetData("downloadedProjects") or {}

    local downItem, downKey = self:GetDownloadedProject(data.projectId)

    if downItem then
        downloadedProjects[downKey] = data
    else
        downloadedProjects[#downloadedProjects + 1] = data
    end

    self:SetData('downloadedProjects', downloadedProjects)
end

function Projects:GetDownloadedProject(projectId)
    if not projectId then
        return false
    end

    local downloadedProjects = self:GetData("downloadedProjects") or {}

    for key, item in ipairs(downloadedProjects) do
        if item.projectId == projectId then
            return item, key
        end
    end
end

function Projects:SetFavoriteProject(projectId)
    if not projectId then
        return false
    end

    local favoriteProjects = commonlib.Array:new(self:GetData("favoriteProjects") or {})

    favoriteProjects:push_back(projectId)

    self:SetData("favoriteProjects", favoriteProjects)
end

function Projects:RemoveFavoriteProject(projectId)
    if not projectId then
        return false
    end

    local favoriteProjects = commonlib.Array:new(self:GetData("favoriteProjects") or {})

    favoriteProjects:removeByValue(projectId)

    self:SetData("favoriteProjects", favoriteProjects)
end

function Projects:IsFavoriteProject(projectId)
    if not projectId then
        return false
    end

    local favoriteProjects = commonlib.Array:new(self:GetData("favoriteProjects") or {})

    if favoriteProjects:contains(projectId) then
        return true
    else
        return false
    end
end

function Projects:GetAllFavoriteProjects()
    local favoriteProjects = commonlib.Array:new(self:GetData("favoriteProjects") or {})

    return favoriteProjects
end