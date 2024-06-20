--[[
Title: 智慧教育平台
Author(s): pbb
Date: 2023.1.30
use the lib:
------------------------------------------------------------
local WisidomEducate = NPL.load('(gl)script/apps/Aries/Creator/Game/Login/WisidomEducate.lua')
------------------------------------------------------------
]]
local LocalService = NPL.load('(gl)Mod/WorldShare/service/LocalService.lua')
local WisidomEducate = NPL.export()

function WisidomEducate.RunEduCommands(cmdLineWorld)
    local preCmd = cmdLineWorld
    cmdLineWorld = cmdLineWorld:gsub("edu_do_works/","")
    if cmdLineWorld:find('single="true"') then
        cmdLineWorld = cmdLineWorld:gsub('single="true"','')
    end
    local jsonStr = commonlib.Encoding.unbase64(cmdLineWorld)
    local workData = commonlib.Json.Decode(jsonStr)
    if System.options.isDevMode then
        print(preCmd)
        print("cmdLineWorld===========",cmdLineWorld)
        echo(workData,true)
    end
    if type(workData) == "table" then
        if workData.competePaperId and tonumber(workData.competePaperId) > 0 then 
            --赛事相关的逻辑
            NPL.load("(gl)script/apps/Aries/Creator/Game/Educate/Competition/CompetitionManager.lua")
            local CompetitionManager = commonlib.gettable("MyCompany.Aries.Game.Educate.Competete.Manager")
            CompetitionManager:Init()
            CompetitionManager:SetCompeteData(workData)
            if System.options.isDevMode then
                echo(workData,true)
                print("compete===============")
            end
        else
            NPL.load("(gl)script/apps/Aries/Creator/Game/Educate/Project/EducateClassManager.lua");
            local EducateClassManager = commonlib.gettable("MyCompany.Aries.Game.Educate.Class.Manager");
            EducateClassManager:Init();
            EducateClassManager.SetEducateData(workData)
            if System.options.isDevMode then
                echo(workData,true)
                print("educate===============")
            end
        end
    end
    System.options.cmdline_world = nil
end
