--[[
Title: WebSocketClient
Author: leio, big
Create Date: 2020.4.27
Modify Date: 2024.3.6
Desc: this is a client to connect websocket server by websocket protocol http://tools.ietf.org/html/rfc6455
the implementation of frame is based on https://github.com/lipp/lua-websockets
-----------------------------------------------
test example: https://github.com/websockets/ws/blob/master/examples/express-session-parse/index.js#L58
local WebSocketClient = NPL.load("(gl)script/ide/System/os/network/WebSocket/WebSocketClient.lua");
WebSocketClient.Connect("ws://localhost:3000");
-----------------------------------------------
]]

NPL.load("(gl)script/ide/socket/url.lua");
NPL.load("(gl)script/ide/timer.lua");
local handshake = NPL.load("./handshake");
local frame = NPL.load("./frame");
local tools = NPL.load("./tools");

local WebSocketClient = NPL.export();

WebSocketClient.state = "CLOSED";
WebSocketClient.keepalive_interval = 10000;

function WebSocketClient.GetNID()
    local user_nid = "user_1";
    return user_nid;
end

function WebSocketClient.GetServerAddr()
	local server_addr = string.format("%s:tcp", WebSocketClient.GetNID());
    return server_addr;
end

local counter = 1;

function WebSocketClient.Connect(url)
    if (WebSocketClient.state == "OPEN") then
        return;
    end
    local protocol, host, port, uri = tools.parse_url(url);
    commonlib.echo({ protocol, host, port, uri });

    local ws_protocols_tbl = { "" };
    if (ws_protocol and type(ws_protocol) == "string") then
        ws_protocols_tbl = { ws_protocol };
    elseif (ws_protocol and type(ws_protocol) == "table") then
        ws_protocols_tbl = ws_protocol;
    end

    local key = tools.generate_key();
    local req = handshake.upgrade_request({
        key = key,
        host = host,
        port = port,
        protocols = ws_protocols_tbl,
        origin = "",
        uri = uri
    })
    WebSocketClient.key = key;
    WebSocketClient.state = "CONNECTING";

	NPL.AddNPLRuntimeAddress({ host = host, port = tostring(port), nid = WebSocketClient.GetNID() });
	
    NPL.load("(gl)script/ide/System/os/network/TcpConnection.lua");
    local TcpConnection = commonlib.gettable("System.os.network.TcpConnection");
    TcpConnection.AddConnectionHandler(WebSocketClient.GetNID(), WebSocketClient.onReceiveMsg);

    if (NPL.activate_with_timeout(2, WebSocketClient.GetServerAddr(), req) == 0) then
        -- TODO
    end
end

function WebSocketClient.OnOpen()
    WebSocketClient.state = "OPEN";
    WebSocketClient.KeepAlive();

    if WebSocketClient.BlueToothOnOpen then
        WebSocketClient.BlueToothOnOpen();
    end
end

function WebSocketClient.KeepAlive()
    if (not WebSocketClient.timer) then
        WebSocketClient.timer = commonlib.Timer:new({
            callbackFunc = function(timer)
                if (WebSocketClient.state == "OPEN") then
                    WebSocketClient.Ping();
                end
            end
        });
        WebSocketClient.timer:Change(0, WebSocketClient.keepalive_interval);
    end
end

function WebSocketClient.Ping()
    local result = WebSocketClient.SendPacket("", frame.PING);
    if (result ~= 0) then
        WebSocketClient.state = "CLOSED";
    end
end

-- send a msg to server
-- @param message: a lua table which is valid on json format
function WebSocketClient.SendMsg(message)
    message = NPL.ToJson(message);
    WebSocketClient.SendPacket(message);
end

-- send a packet to server
function WebSocketClient.SendPacket(message, opcode)
    local encoded = frame.encode(message, opcode or frame.TEXT, true);
    return NPL.activate(WebSocketClient.GetServerAddr(), encoded);
end

function WebSocketClient.HandleClose(nid, decoded)
    LOG.std(nil, "info", "WebSocketClient", "HandleClose nid: %s, decode: %s", nid, decode);
    WebSocketClient.state = "CLOSED";

    if (WebSocketClient.BlueToothOnClose) then
        WebSocketClient.BlueToothOnClose();
    end
end

-- received a msg from server
-- @param message: a lua table which is valid on json format
function WebSocketClient.HandleMsg(nid, message)
    LOG.std(nil, "info", "WebSocketClient", "HandleMsg nid: %s, message: %s", nid, message);

    if (WebSocketClient.BlueToothOnMsg) then
        WebSocketClient.BlueToothOnMsg(message);
    end
end

function WebSocketClient.HandlePong(nid, decoded)
    LOG.std(nil, "debug", "WebSocketClient", "HandlePong nid: %s, decoded: %s", nid, decoded);
end

function WebSocketClient.HandlePacket(nid, decoded, fin, opcode)
    if (opcode == frame.CLOSE) then
        WebSocketClient.HandleClose(nid, decoded);
    elseif (opcode == frame.PONG) then
        WebSocketClient.HandlePong(nid, decoded);
    elseif (opcode == frame.TEXT) then
        local out = {};
        if (NPL.FromJson(decoded, out)) then
            WebSocketClient.HandleMsg(nid, out);
        end
    else
		LOG.std(nil, "warn", "WebSocketClient", "%s received an unknown msg with opcode:%s", tostring(nid), tostring(opcode));
    end
end

function WebSocketClient.onReceiveMsg(msg)
    if (msg and msg.code == 12) then
        WebSocketClient.HandleClose("", "");
        return;
    end

    -- waitting for handshake
    if (WebSocketClient.state == "CONNECTING") then
        local response = msg[1];
        local headers = handshake.http_headers(response);
        
        if (not headers or not headers["sec-websocket-accept"]) then
            return;
        end

        local expected_accept = handshake.sec_websocket_accept(WebSocketClient.key);
        if (headers["sec-websocket-accept"] ~= expected_accept) then
            WebSocketClient.state = "CLOSED";
            return;
        end
        WebSocketClient.OnOpen();
    else
        local response = msg[1];
        local nid = msg.nid;
        local decoded, fin, opcode = frame.decode(response or {});

        WebSocketClient.HandlePacket(nid, decoded, fin, opcode);
    end
end
