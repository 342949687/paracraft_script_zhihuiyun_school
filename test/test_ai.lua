local M = NPL.export()

NPL.load("test/ai/ai.lua",true)
local AI = commonlib.gettable("app.hyz.wuziqi.ai.AI")

local opening = commonlib.getfield("app.hyz.wuziqi.ai.opening")
local _math = commonlib.getfield("app.hyz.wuziqi.ai._math")
local _funcs = commonlib.getfield("app.hyz.wuziqi.ai._funcs")

function M.test_1()
    print(_VERSION)

    local tmp1 = 0x01
    local tmp2 = 0x01
    print(_funcs.xor(tmp1,tmp2))  --输出tmp1 异或 tmp2 的操作结果

    local arr = {1,2,3}
    local aaa = {4,5,6}

    local ai = AI:new()

    local time_1 = os.clock()

    local open = ai:start(true,true)

    print("open",open.name)
    _funcs.printBroad(open.board)

    local p = ai:begin()

    local time_2 = os.clock()
    print("p",p[0],p[1])
    _funcs.printBroad(open.board)

    GameLogic.AddBBS(nil,string.format("(%s,%s),time:%s",p[0],p[1],time_2-time_1))
end



