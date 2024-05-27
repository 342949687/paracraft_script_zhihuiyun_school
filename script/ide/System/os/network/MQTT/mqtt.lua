--[[
Title: MQTT
Author(s): LiXizhi
Date: 2023/6/26
Desc:
MQTT protocol DOC: http://docs.oasis-open.org/mqtt/mqtt/v3.1.1/errata01/os/mqtt-v3.1.1-errata01-os-complete.html

use the lib:
-------------------------------------------------------
NPL.load("(gl)script/ide/System/os/network/MQTT/mqtt.lua");
local mqtt = commonlib.gettable("System.os.network.mqtt");

-- create MQTT client
local client = mqtt:new():Init({ uri = "mqtt.keepwork.com", username = "", password="", clean = true, client_id = nil })

-- assign MQTT client event handlers
client:on({
    connect = function(connack)
        if connack.rc ~= 0 then
            print("connection to broker failed:", connack:reason_string(), connack)
            return
        end

        -- connection established, now subscribe to test topic and publish a message after
        assert(client:subscribe{ topic="luamqtt/#", qos=1, callback=function()
            assert(client:publish{ topic = "luamqtt/simpletest", payload = "hello" })
        end})
    end,

    message = function(msg)
        assert(client:acknowledge(msg))

        -- receive one message and disconnect
        print("received message", msg)
        client:disconnect()
    end,
    -- subscribe = function(msg)    end, 
    -- unsubscribe = function(msg)    end, 
    -- acknowledge = function(msg)    end, 
    -- close = function(msg)    end, 
    -- error = function(err)    end, 
    -- auth = function(msg)    end, 
})
client:start()
-------------------------------------------------------
]]
NPL.load("(gl)script/ide/System/os/network/MQTT/mqtt_client.lua");
local client = commonlib.gettable("System.os.network.mqtt.client");
local mqtt = commonlib.gettable("System.os.network.mqtt")

-- supported MQTT protocol versions
mqtt.v311 = 4		-- supported protocol version, MQTT v3.1.1
mqtt.v50 = 5		-- supported protocol version, MQTT v5.0
mqtt._VERSION = "1.0.0"

--- Create new MQTT client instance
-- @param same as mqtt.client:new()
function mqtt:new(o)
	return client:new(o)
end
