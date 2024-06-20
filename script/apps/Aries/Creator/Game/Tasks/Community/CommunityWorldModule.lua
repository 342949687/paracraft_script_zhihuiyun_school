--[[
    author: pbb
    date: 2024-05-12
    uselib:
     local CommunityWorldModule = NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/Community/CommunityWorldModule.lua")
     CommunityWorldModule.ShowPage()
]]

local all_projects_data = {
    {type="全部", name="空白模板", project_name = "empty", id = 73347, img_bg="https://api.keepwork.com/ts-storage/siteFiles/20824/raw#emptyTemplate.jpg", is_recommend=false, is_vip_use=false, pos={19200,11,19200}},
    {type="全部", name="长征", project_name = "changzheng", id = 69076, img_bg="https://api.keepwork.com/ts-storage/siteFiles/20825/raw#qilvchangzheng.jpg", is_recommend=true, is_vip_use=false},

    {type="跑酷", name="跑酷模板1", project_name = "paoku1", id = 72030, img_bg="https://api.keepwork.com/ts-storage/siteFiles/20807/raw#paoku1.jpg", is_recommend=false, is_vip_use=true, pos={19162,11,19206}},
    {type="跑酷", name="跑酷模板2", project_name = "paoku2", id = 72001, img_bg="https://api.keepwork.com/ts-storage/siteFiles/20805/raw#paoku2.jpg", is_recommend=false, is_vip_use=true, pos={19162,11,19206}},

    -- 过山车
    {type="过山车", name="过山车模板", project_name = "guoshanche", id = 72012, img_bg="https://api.keepwork.com/ts-storage/siteFiles/20808/raw#guoshanche.jpg", is_recommend=false, is_vip_use=true, pos={19162,11,19206}},
    {type="过山车", name="过山车模板2", project_name = "guoshanche2", id = 73304, img_bg="https://api.keepwork.com/ts-storage/siteFiles/20820/raw#guoshanche2.jpg", is_recommend=false, is_vip_use=true, pos={19162,11,19206}},

    {type="动画", name="秋收起义", project_name = "qiushouqiyi", id = 71758, img_bg="https://api.keepwork.com/ts-storage/siteFiles/20742/raw#秋收起义.jpg", is_recommend=false, is_vip_use=true, pos={19248,11,19200}},
    {type="动画", name="洛川会议", project_name = "luochuanhuiyi", id = 71756, img_bg="https://api.keepwork.com/ts-storage/siteFiles/20740/raw#洛川会议.jpg", is_recommend=false, is_vip_use=true, pos={19207,11,19248}},
    {type="动画", name="东江纵队", project_name = "dongjiangzongdui", id = 71759, img_bg="https://api.keepwork.com/ts-storage/siteFiles/20736/raw#东江纵队.jpg", is_recommend=false, is_vip_use=true, pos={19232,11,19152}},
    {type="动画", name="毛泽东故居", project_name = "maozedongguju", id = 71760, img_bg="https://api.keepwork.com/ts-storage/siteFiles/20741/raw#毛泽东故居.jpg", is_recommend=false, is_vip_use=true, pos={19189,11,19148}},
    {type="动画", name="中共七大", project_name = "zhonggongqida", id = 71761, img_bg="https://api.keepwork.com/ts-storage/siteFiles/20744/raw#中共七大.jpg", is_recommend=false, is_vip_use=true, pos={19159,11,19249}},
    {type="动画", name="红八军", project_name = "hongbajun", id = 71762, img_bg="https://api.keepwork.com/ts-storage/siteFiles/20738/raw#红八军总部.jpg", is_recommend=false, is_vip_use=true, pos={19176,11,19238}},

    {type="动画", name="古田会议", project_name = "gutianhuiyi", id = 71764, img_bg="https://api.keepwork.com/ts-storage/siteFiles/20737/raw#古田会议.jpg", is_recommend=false, is_vip_use=true, pos={19225,11,19147}},
    {type="动画", name="红井", project_name = "hongjing", id = 71765, img_bg="https://api.keepwork.com/ts-storage/siteFiles/20739/raw#红井.jpg", is_recommend=false, is_vip_use=true, pos={19199,11,19224}},
    {type="动画", name="朱德故居", project_name = "zhudeguju", id = 71763, img_bg="https://api.keepwork.com/ts-storage/siteFiles/20745/raw#朱德故居.jpg", is_recommend=false, is_vip_use=true, pos={19239,11,19246}},
    {type="动画", name="瓦窑堡", project_name = "wayaobu", id = 70874, img_bg="https://api.keepwork.com/ts-storage/siteFiles/20743/raw#瓦窑堡.jpg", is_recommend=false, is_vip_use=true, pos={19175,11,19247}},

    {type="解密", name="闯关冒险", project_name = "chuangguan", id = 72015, img_bg="https://api.keepwork.com/ts-storage/siteFiles/20806/raw#chuangguan.jpg", is_vip_use=true, pos={19162,11,19206}},
    {type="解密", name="逃出山庄", project_name = "taochushanzhuang", id = 72171, img_bg="https://api.keepwork.com/ts-storage/siteFiles/20810/raw#yuhangyuan.png", is_vip_use=true, pos={19176,12,19205}},
    {type="解密", name="星光", project_name = "xingguang", id = 71023, img_bg="https://api.keepwork.com/ts-storage/siteFiles/20809/raw#littleGril.png", is_vip_use=true, pos={19209,12,19164}},

    {type="单人游戏", name="球赛模板", project_name = "qiusai", id = 72003, img_bg="https://api.keepwork.com/ts-storage/siteFiles/20804/raw#qiusai.jpg", is_vip_use=true, pos={19162,11,19206}},
    {type="单人游戏", name="保护羊群", project_name = "baohu", id = 73307, img_bg="https://api.keepwork.com/ts-storage/siteFiles/20819/raw#baohu.jpg", is_vip_use=true, pos={19162,11,19206}},

    {type="教学", name="建设乐园", project_name = "leyuan", id = 73305, img_bg="https://api.keepwork.com/ts-storage/siteFiles/20821/raw#leyuan.jpg", is_vip_use=true, pos={19162,11,19206}},
}

CreateModulPage.TypeData = {
    ["全部"] = {name="全部", background="Texture/Aries/Creator/keepwork/World2In1/zi1_32X32_32bits.png#0 0 108 36", project_list = {}},
    ["跑酷"] = {name="跑酷", background="Texture/Aries/Creator/keepwork/World2In1/zi3_32X32_32bits.png#0 0 108 36", project_list = {}},
    ["过山车"] = {name="过山车", background="Texture/Aries/Creator/keepwork/World2In1/zi8_62X15_32bits.png#0 0 108 36", project_list = {}},
    ["动画"] = {name="动画", background="Texture/Aries/Creator/keepwork/World2In1/zi2_31X15_32bits.png#0 0 108 36", project_list = {}},
    ["解密"] = {name="解密", background="Texture/Aries/Creator/keepwork/World2In1/zi4_32X32_32bits.png#0 0 108 36", project_list = {}},
    ["单人游戏"] = {name="单人游戏", background="Texture/Aries/Creator/keepwork/World2In1/zi6_62X15_32bits.png#0 0 108 36", project_list = {}},
    ["射击"] = {name="射击", background="Texture/Aries/Creator/keepwork/World2In1/zi9_31X15_32bits.png#0 0 108 36", project_list = {}},
    ["教学"] = {name="教学", background="Texture/Aries/Creator/keepwork/World2In1/zi10_31X15_32bits.png#0 0 108 36", project_list = {}},
    ["多人游戏"] = {name="多人游戏", background="Texture/Aries/Creator/keepwork/World2In1/zi7_62X15_32bits.png#0 0 108 36", project_list = {}},
}

local CommunityWorldModule = NPL.export()
local page


function CommunityWorldModule.OnInit()
    page = document:GetPageCtrl()
end

function CommunityWorldModule.ShowPage()
    local view_width, view_height = 0,0
    local params = {
        url = "script/apps/Aries/Creator/Game/Tasks/Community/Project/ProjectMainPage.html",
        name = "ProjectMainPage.ShowPage", 
        isShowTitleBar = false,
        DestroyOnClose = true,
        style = CommonCtrl.WindowFrame.ContainerStyle,
        allowDrag = false,
        enable_esc_key = true,
        cancelShowAnimation = true,
        directPosition = true,
            align = "_fi",
            x = -view_width/2,
            y = -view_height/2,
            width = view_width,
            height = view_height,
    };
    System.App.Commands.Call("File.MCMLWindowFrame", params);
end