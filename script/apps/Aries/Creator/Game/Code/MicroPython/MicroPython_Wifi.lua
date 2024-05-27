--[[
Title: micro python
Author(s): LiXizhi
Date: 2023/8/2
Desc: 
use the lib:
-------------------------------------------------------
import network
my_wifi = wifi()
my_wifi.connectWiFi("TP-LINK_BFAA", "86571207tc")
-------------------------------------------------------
]]
MicroPython = NPL.load("./MicroPython.lua");

NPL.export({

{
	type = "cmdExamples", 
	message0 = "%1",
	arg0 = {
		{
			name = "value",
			type = "field_dropdown",
			options = {
				{ L"/tip", "tip" },
				{ L"发送事件", "sendevent" },
				{ L"改变时间[-1,1]", "time"},
				{ L"加载世界:项目id", "loadworld"},
			},
		},
	},
	hide_in_toolbox = true,
	category = "wifi", 
	output = {type = "null",},
	helpUrl = "", 
	canRun = false,
	func_description = '"%s"',
	ToNPL = function(self)
		return self:getFieldAsString('value');
	end,
	examples = {{desc = "", canRun = true, code = [[
]]}},
},

{
	type = "paracraft.runCmd", 
	message0 = L"向主机发命令%1 内容%2",
	arg0 = {
		{
			name = "cmdName",
			type = "input_value",
			shadow = { type = "text", value = "sendevent",},
            -- shadow = { type = "cmdExamples", value = "sendevent",},
			text = "sendevent", 
		},
		{
			name = "cmdParams",
			type = "input_value",
            shadow = { type = "text", value = "hello msg",},
			text = "hello msg", 
		},
	},
	category = "wifi", 
	helpUrl = "", 
	canRun = false,
	previousStatement = true,
	nextStatement = true,
	headerText = "",
	func_description = 'print("/%s %s")',
	ToNPL = function(self)
		local cmdName = self:getFieldAsString('cmdName')
		cmdName = cmdName:gsub("^/", "");
		return string.format('print("/%s %s")\n', cmdName, self:getFieldAsString('cmdParams'));
	end,
	ToMicroPython = function(self)
		local cmdName = self:GetValueAsString('cmdName')
		cmdName = cmdName:gsub("^([\"'])/", "%1");
		return string.format('print("/"+str(%s)+" "+str(%s))\n', cmdName, self:GetValueAsString('cmdParams'));
	end,
	examples = {{desc = "", canRun = false, code = [[
print("/tip hello")
print("/sendevent hello {'msg'}")
]]}},
},


{
	type = "network.wifi", 
	message0 = L"连接Wi-Fi 名称 %1 密码 %2",
	arg0 = {
		{
			name = "username",
			type = "input_value",
            shadow = { type = "text", value = "username",},
			text = "username", 
		},
		{
			name = "password",
			type = "input_value",
            shadow = { type = "text", value = "password",},
			text = "password", 
		},
	},
	category = "wifi", 
	helpUrl = "", 
	canRun = false,
	funcName = "network.wifi",
	previousStatement = true,
	nextStatement = true,
	headerText = "from mpython import *\nimport network",
	func_description = 'my_wifi.connectWiFi(%s, %s)',
	ToNPL = function(self)
		return string.format('my_wifi.connectWiFi("%s", "%s")\n', self:getFieldAsString('username'), self:getFieldAsString('password'));
	end,
	ToMicroPython = function(self)
		self:GetBlockly():AddUnqiueHeader("my_wifi = wifi()");
		return string.format('my_wifi.connectWiFi(%s, %s)\n', self:GetValueAsString('username'), self:GetValueAsString('password'));
	end,
	examples = {{desc = "", canRun = true, code = [[
import network
my_wifi = wifi()
my_wifi.connectWiFi("TF-Guest", "password")

if my_wifi.sta.isconnected():
    oled.fill(0)
    oled.DispChar(str('connected'), 0, 0, 1)
    oled.show()
]]}},
},

{
	type = "network.wifi.isconnected", 
	message0 = L"已连接到Wi-fi",
	arg0 = {
	},
	output = {type = "null",},
	category = "wifi", 
	helpUrl = "", 
	funcName = "wifi.isconnected",
	canRun = false,
	headerText = "from mpython import *\nimport network",
	func_description = 'my_wifi.sta.isconnected()',
	ToNPL = function(self)
		return "my_wifi.sta.isconnected()";
	end,
	ToMicroPython = function(self)
		self:GetBlockly():AddUnqiueHeader("my_wifi = wifi()");
		return "my_wifi.sta.isconnected()";
	end,
	examples = {{desc = "", canRun = true, code = [[
]]}},
},

{
	type = "mqtt", 
	message0 = L"MQTT client_id %1 服务器 %2 端口 %3",
	message1 = L"用户名 %1 密码 %2",
	message2 = L"keepalive %1",
	arg0 = {
		{
			name = "client_id",
			type = "input_value",
            shadow = { type = "text", value = "",},
			text = "", 
		},
		{
			name = "server",
			type = "input_value",
            shadow = { type = "text", value = "iot.keepwork.com",},
			text = "iot.keepwork.com", 
		},
		{
			name = "port",
			type = "input_value",
            shadow = { type = "math_number", value = 1883,},
			text = 1883, 
		},
	},
	arg1 = {
		{
			name = "username",
			type = "input_value",
            shadow = { type = "text", value = "",},
			text = "", 
		},
		{
			name = "password",
			type = "input_value",
            shadow = { type = "text", value = "", isPassWord = true},
			text = "", 
			isPassWord = true,
		},
	},
	arg2 = {
		{
			name = "keepalive",
			type = "input_value",
            shadow = { type = "math_number", value = 30,},
			text = 30, 
		},
	},
	category = "wifi", 
	helpUrl = "", 
	canRun = false,
	funcName = "MQTTClient",
	previousStatement = true,
	nextStatement = true,
	headerText = "from mpython import *\nfrom umqtt.simple import MQTTClient",
	func_description = 'mqtt = MQTTClient(%s, %s, %s, %s, %s, %s)',
	ToNPL = function(self)
		return string.format('mqtt = MQTTClient("%s", "%s", %s, "%s", "%s", %s)\n', 
			self:getFieldAsString('client_id'), self:getFieldAsString('server'), self:getFieldAsString('port'),
			self:getFieldAsString('username'), self:getFieldAsString('password'),
			self:getFieldAsString('keepalive'));
	end,
	ToMicroPython = function(self)
		return string.format('mqtt = MQTTClient(%s, %s, %s, %s, %s, %s)\n', 
			self:GetValueAsString('client_id'), self:GetValueAsString('server'), self:getFieldAsString('port'),
			self:GetValueAsString('username'), self:GetValueAsString('password'),
			self:getFieldAsString('keepalive'));
	end,
	examples = {{desc = "", canRun = true, code = [[
from umqtt.simple import MQTTClient
mqtt = MQTTClient('mpy', 'iot.keepwork.com', 1883, 'liuqi672', '86571207tc', 30)
try:
    mqtt.connect()
    print('Connected')
except:
    print('Disconnected')
]]}},
},

{
	type = "mqtt_paracraft", 
	message0 = L"帕拉卡MQTT 用户名 %1 密码 %2",
	arg0 = {
		{
			name = "username",
			type = "input_value",
            shadow = { type = "text", value = System.User.username or "",},
			text = System.User.username or "", 
		},
		{
			name = "password",
			type = "input_value",
            shadow = { type = "text", value = "", isPassWord = true},
			text = "", 
			isPassWord = true,
		},
	},
	category = "wifi", 
	helpUrl = "", 
	canRun = false, 
	funcName = "MQTTClient_paracraft",
	previousStatement = true,
	nextStatement = true,
	headerText = "from mpython import *\nfrom umqtt.simple import MQTTClient",
	func_description = 'mqtt = MQTTClient("", "iot.keepwork.com", "1883", %s, %s, 30)',
	ToNPL = function(self)
		return string.format('mqtt = MQTTClient("", "iot.keepwork.com", 1883, "%s", "%s", 30)\n', 
			self:getFieldAsString('username'), self:getFieldAsString('password'));
	end,
	ToMicroPython = function(self)
		return string.format('mqtt = MQTTClient("", "iot.keepwork.com", 1883, %s, %s, 30)\n', 
			self:GetValueAsString('username'), self:GetValueAsString('password'));
	end,
	examples = {{desc = "", canRun = true, code = [[
]]}},
},

{
	type = "MQTT.connect", 
	message0 = L"连接MQTT",
	arg0 = {
	},
	category = "wifi", 
	helpUrl = "", 
	canRun = false,
	previousStatement = true,
	nextStatement = true,
	headerText = "from mpython import *\nfrom umqtt.simple import MQTTClient\nfrom machine import Timer\nimport time",
	func_description = 'mqtt.connect()',
	ToNPL = function(self)
		return string.format("try:\n    mqtt.connect()\n    print('MQTT Connected')\nexcept:\n    print('MQTT Disconnected')\ndef timerMqtt_tick(_):\n    mqtt.ping()\ntimerMqtt = Timer(99)\ntimerMqtt.init(period=20000, mode=Timer.PERIODIC, callback=timerMqtt_tick)\n");
	end,
	ToMicroPython = function(self)
		local block_indent = self:GetIndent();
		local block_indent2 = block_indent .. self:GetBlockly().Const.Indent
		local id = self:GetBlockly():GetNextId();
		return string.format("try:\n%smqtt.connect()\n%sprint('MQTT Connected')\n%sexcept:\n%sprint('MQTT Disconnected')\n%sdef timerMqtt_tick(_):\n%smqtt.ping()\n%stimerMqtt = Timer(99)\n%stimerMqtt.init(period=20000, mode=Timer.PERIODIC, callback=timerMqtt_tick)\n", 
			block_indent2, block_indent2, block_indent, block_indent2, block_indent, block_indent2, block_indent, block_indent);
	end,
	examples = {{desc = "", canRun = true, code = [[
]]}},
},


{
	type = "mqtt.subscribe", 
	message0 = L"当从主题 %1 接受到消息时",
	message1 = L"%1",
	arg0 = {
		{
			name = "topic",
			type = "input_value",
            shadow = { type = "text", value = (System.User.username or "").."/name",},
			text = (System.User.username or "").."/name", 
		},
	},
	arg1 = {
			{
				name = "input",
				type = "input_statement",
				text = "pass",
			},
		},
	category = "wifi", 
	helpUrl = "", 
	canRun = false,
	funcName = "mqtt.subscribe",
	previousStatement = true,
	nextStatement = true,
	headerText = "from mpython import *\nfrom umqtt.simple import MQTTClient",
	func_description = 'mqtt.subscribe(%s)\n    %s',
	ToNPL = function(self)
		local precode = "def mqtt_callback(topic, msg):\n    try:\n        topic = topic.decode('utf-8', 'ignore')\n        _msg = msg.decode('utf-8', 'ignore')\n        eval('mqtt_topic_' + str(topic) + '(\"' + _msg + '\")')\n    except: print((topic, msg))\nmqtt.set_callback(mqtt_callback)\n"
		local input = self:getFieldAsString('input');
		if(input == "") then
			input = "pass"
		end
		local cbCode = string.format("def mqtt_topic_%s(_msg):\n    %s\n", self:getFieldAsString('topic'), input);
		return string.format('%s\n%s\nmqtt.subscribe("%s")\n', precode, cbCode, self:getFieldAsString('topic'));
	end,
	ToMicroPython = function(self)
		local hexFunc  =  'def str2name(str):\n    return "".join([c if (c.isalpha() or c.isdigit() or c==\'_\') else "_%x" % ord(c) for c in str])\n';
		self:GetBlockly():AddUnqiueHeader(hexFunc );
		local precode = "def mqtt_callback(topic, msg):\n    try:\n        topic = topic.decode('utf-8', 'ignore')\n        _msg = msg.decode('utf-8', 'ignore')\n        eval('mqtt_topic_' + str2name(topic) + \"('\" + _msg + \"')\")\n    except: print((topic, msg))\n"
		self:GetBlockly():AddUnqiueHeader(precode);
		local block_indent = self:GetIndent();
		self:SetIndent("") -- tricky: since we are moving the code to header, so we need to remove the indent
		local input = self:getFieldAsString('input');
		
		local global_vars = MicroPython:GetGlobalVarsDefString(self)

		local cbCode = string.format("def mqtt_topic_%s(_msg):\n%s%s\n", commonlib.Encoding.toValidParamName(self:getFieldAsString('topic')), global_vars, input);
		self:SetIndent(block_indent)

		self:GetBlockly():AddUnqiueHeader(cbCode);
		return string.format('mqtt.set_callback(mqtt_callback)\nmqtt.subscribe(%s)\n', self:GetValueAsString('topic'));
	end,
	examples = {{desc = "", canRun = true, code = [[
]]}},
},


{
	type = "mqtt.msg", 
	message0 = L"从MQTT接收到的消息",
	arg0 = {
	},
	output = {type = "null",},
	category = "wifi", 
	helpUrl = "", 
	funcName = "mqtt.msg",
	canRun = false,
	headerText = "",
	func_description = '_msg',
	ToNPL = function(self)
		return "_msg";
	end,
	ToMicroPython = function(self)
		return "_msg";
	end,
	examples = {{desc = "", canRun = true, code = [[
]]}},
},

{
	type = "mqtt.check_msg", 
	message0 = L"等待主题消息以%1模式",
	arg0 = {
		{
			name = "mode",
			type = "field_dropdown",
			options = {
				{ L"非阻塞", "check_msg()" },
				{ L"阻塞", "wait_msg()" },
			}
		},
	},
	category = "wifi", 
	helpUrl = "", 
	canRun = false,
	previousStatement = true,
	nextStatement = true,
	headerText = "from mpython import *\nfrom umqtt.simple import MQTTClient",
	func_description = 'mqtt.%s',
	ToNPL = function(self)
		return string.format("mqtt.%s\n", self:getFieldAsString('mode'));
	end,
	ToMicroPython = function(self)
		return string.format("mqtt.%s\n", self:getFieldAsString('mode'));
	end,
	examples = {{desc = "", canRun = true, code = [[
for i in range(1, 10):
    mqtt.publish('test', str(i))
    time.sleep(1)
    mqtt.check_msg()
]]}},
},

{
	type = "mqtt.publish", 
	message0 = L"发布到主题 %1 内容 %2",
	arg0 = {
		{
			name = "topic",
			type = "input_value",
            shadow = { type = "text", value = (System.User.username or "").."/name",},
			text = (System.User.username or "").."/name", 
		},
		{
			name = "data",
			type = "input_value",
            shadow = { type = "text", value = "",},
			text = "", 
		},
	},
	category = "wifi", 
	helpUrl = "", 
	canRun = false,
	previousStatement = true,
	nextStatement = true,
	headerText = "from mpython import *\nfrom umqtt.simple import MQTTClient",
	func_description = 'mqtt.publish(%s, %s)',
	ToNPL = function(self)
		return string.format('mqtt.publish("%s", "%s")\n', self:getFieldAsString('topic'), self:getFieldAsString('data'));
	end,
	ToMicroPython = function(self)
		return string.format('mqtt.publish(%s, %s)\n', self:GetValueAsString('topic'), self:GetValueAsString('data'));
	end,
	examples = {{desc = "", canRun = false, code = [[
]]}},
},


{
	type = "i2c.Init", 
	message0 = L"初始化%1 SCL%2 SDA%3 速率%4",
	arg0 = {
		{
			name = "name",
			type = "field_dropdown",
			options = {
				{ L"i2c_1", "i2c_1" },
				{ L"i2c_2", "i2c_2" },
			}
		},
		{
			name = "SCL",
			type = "field_dropdown",
			options = {
				{ "P13", "13" },
				{ "P14", "14" },
				{ "P15", "15" },
				{ "P16", "16" },
			},
			text = "13",
		},
		{
			name = "SDA",
			type = "field_dropdown",
			options = {
				{ "P13", "13" },
				{ "P14", "14" },
				{ "P15", "15" },
				{ "P16", "16" },
			},
			text = "14",
		},
		{
			name = "Frequency",
			type = "field_dropdown",
			options = {
				{ "400000",  "400000"},
				{ "100000", "100000" },
			}
		},
	},
	output = {type = "null",},
	category = "wifi", 
	helpUrl = "", 
	canRun = false,
	previousStatement = true,
	nextStatement = true,
	headerText = "from mpython import *\n",
	func_description = '%s = I2C(scl=Pin(Pin.P%s), sda=Pin(Pin.P%s), freq=%s)',
	ToNPL = function(self)
		return string.format('%s = I2C(scl=Pin(Pin.P%s), sda=Pin(Pin.P%s), freq=%s)\n', 
			self:getFieldAsString('name'),self:getFieldAsString('SCL'),self:getFieldAsString('SDA'),self:getFieldAsString('Frequency'));
	end,
	ToMicroPython = function(self)
		local precode = string.format('%s = I2C(scl=Pin(Pin.P%s), sda=Pin(Pin.P%s), freq=%s)\n', 
				self:getFieldAsString('name'),self:getFieldAsString('SCL'),self:getFieldAsString('SDA'),self:getFieldAsString('Frequency'))
		self:GetBlockly():AddUnqiueHeader(precode);
		return "";
	end,
	examples = {{desc = "", canRun = true, code = [[
from mpython import *
i2c_1 = I2C(scl=Pin(Pin.P13), sda=Pin(Pin.P14), freq=400000)
i2c.writeto(1, (bytearray([2, 80, 0,80,0])), True)
]]}},
},

{
	type = "i2c.writeto", 
	message0 = L"%1 设备地址 %2 写入数据bytearray[%3] 停止位%4",
	arg0 = {
		{
			name = "name",
			type = "field_dropdown",
			options = {
				{ L"i2c", "i2c" },
				{ L"i2c_1", "i2c_1" },
				{ L"i2c_2", "i2c_2" },
			}
		},
		{
			name = "address",
			type = "input_value",
            shadow = { type = "math_number", value = 38,},
			text = 1, 
		},
		{
			name = "data",
			type = "input_value",
            shadow = { type = "text", value = "",},
			text = "2, 80,0,80,0", 
		},
		{
			name = "endingBit",
			type = "field_dropdown",
			options = {
				{ L"真", "True" },
				{ L"假", "False" },
			  }
		},
	},
	output = {type = "null",},
	category = "wifi", 
	helpUrl = "", 
	canRun = false,
	previousStatement = true,
	nextStatement = true,
	headerText = "from mpython import *\n",
	func_description = '%s.writeto(%s, bytearray([%s])), %s)',
	ToNPL = function(self)
		return string.format('%s.writeto(%s, (bytearray([%s])), %s)\n', 
			self:getFieldAsString('name'),self:getFieldAsString('address'),self:getFieldAsString('data'),self:getFieldAsString('endingBit'));
	end,
	ToMicroPython = function(self)
		return string.format('%s.writeto(%s, (bytearray([%s])), %s)\n', 
			self:getFieldAsString('name'),self:getFieldAsString('address'),self:getFieldAsString('data'),self:getFieldAsString('endingBit'));
	end,
	examples = {{desc = "", canRun = true, code = [[
from mpython import *
i2c_1 = I2C(scl=Pin(Pin.P13), sda=Pin(Pin.P14), freq=400000)
i2c.writeto(1, (bytearray([2, 80, 0,80,0])), True)
]]}},
},

{
	type = "i2c.readfrom", 
	message0 = L"%1 设备地址 %2 读取字节数%3 停止位%4",
	arg0 = {
		{
			name = "name",
			type = "field_dropdown",
			options = {
				{ L"i2c", "i2c" },
				{ L"i2c_1", "i2c_1" },
				{ L"i2c_2", "i2c_2" },
			}
		},
		{
			name = "address",
			type = "input_value",
            shadow = { type = "math_number", value = 38,},
			text = 1, 
		},
		{
			name = "byteCount",
			type = "input_value",
            shadow = { type = "math_number", value = 38,},
			text = 1, 
		},
		{
			name = "endingBit",
			type = "field_dropdown",
			options = {
				{ L"真", "True" },
				{ L"假", "False" },
			  }
		},
	},
	output = {type = "null",},
	category = "wifi", 
	helpUrl = "", 
	canRun = false,
	headerText = "from mpython import *\n",
	func_description = '%s.readfrom(%s, %s, %s)',
	ToNPL = function(self)
		return string.format('%s.readfrom(%s, %s, %s)\n', 
			self:getFieldAsString('name'),self:getFieldAsString('address'),self:getFieldAsString('byteCount'),self:getFieldAsString('endingBit'));
	end,
	ToMicroPython = function(self)
		return string.format('%s.readfrom(%s, %s, %s)\n', 
			self:getFieldAsString('name'),self:getFieldAsString('address'),self:getFieldAsString('byteCount'),self:getFieldAsString('endingBit'));
	end,
	examples = {{desc = "", canRun = true, code = [[
from mpython import *
i2c_1 = I2C(scl=Pin(Pin.P13), sda=Pin(Pin.P14), freq=400000)
A = i2c.readfrom(1, 1, True)
]]}},
},

{
	type = "i2c.motor", 
	message0 = L"设置马达速度 M1 %1 M2 %2",
	arg0 = {
		{
			name = "M1",
			type = "input_value",
            shadow = { type = "math_number", value = 70,},
			text = 70, 
		},
		{
			name = "M2",
			type = "input_value",
            shadow = { type = "math_number", value = -70,},
			text = -70, 
		},
	},
	output = {type = "null",},
	category = "wifi", 
	helpUrl = "", 
	canRun = false,
	funcName = "i2c.motor",
	previousStatement = true,
	nextStatement = true,
	headerText = "from mpython import *\n",
	func_description = 'i2c.writeto(1, (bytearray([2, %s, 0, %s,0])), True)',
	ToNPL = function(self)
		return string.format('i2c.writeto(1, (bytearray([2, %s, 0, %s,0])), True)\n', 
			self:getFieldAsString('M1'),self:getFieldAsString('M2'));
	end,
	ToMicroPython = function(self)
		self:GetBlockly():AddUnqiueHeader("i2c_1 = I2C(scl=Pin(Pin.P13), sda=Pin(Pin.P14), freq=400000)\n");
		local m1, m2 = self:getFieldAsString('M1'), self:getFieldAsString('M2');
		return string.format('i2c.writeto(1, (bytearray([2, round(%s/100*255) if (%s)>0 else 0, 0 if (%s)>0 else -round(%s/100*255), round(%s/100*255) if (%s)>0 else 0, 0 if (%s)>0 else -round(%s/100*255)])), True)\n', m1,m1,m1, m1, m2, m2, m2, m2);
	end,
	examples = {{desc = "", canRun = true, code = [[
]]}},
},


{
	type = "i2c.readSensorbyte", 
	message0 = L"读取巡线小车的值",
	arg0 = {
	},
	output = {type = "null",},
	category = "wifi", 
	helpUrl = "", 
	canRun = false,
	headerText = "from mpython import *\nimport struct\n",
	func_description = 'i2c.readfrom(1, 1, True)',
	ToNPL = function(self)
		return "i2c.readfrom(1, 1, True)";
	end,
	ToMicroPython = function(self)
		self:GetBlockly():AddUnqiueHeader("i2c_1 = I2C(scl=Pin(Pin.P13), sda=Pin(Pin.P14), freq=400000)\n");
		return 'struct.unpack("<b", i2c.readfrom(1, 1, True))[0]';
	end,
	examples = {{desc = "", canRun = true, code = [[
]]}},
},


{
	type = "hcsr04.init", 
	message0 = L"初始化声波传感器%1 trigger %2 echo %3",
	arg0 = {
		{
			name = "name",
			type = "input_value",
            shadow = { type = "text", value = "hcsr04"},
			text = "hcsr04", 
		},
		{
			name = "trigger_pin",
			type = "field_dropdown",
			options = {
				{ L"P0", "0" },
				{ L"P1", "1" },
				{ L"P2", "2" },
				{ L"P5(button_A)", "5" },
				{ L"P6(buzzer)", "6" },
				{ L"P7(RGB)", "7" },
				{ L"P8", "8" },
				{ L"P9", "9" },
				{ L"P11(button_B)", "11" },
				{ L"P12", "12" },
				{ L"P13", "13" },
				{ L"P14", "14" },
				{ L"P15", "15" },
				{ L"P16", "16" },
				{ L"P19(SCL)", "19" },
				{ L"P20(SDA", "20" },
			},
			text = "0",
		},
		{
			name = "echo_pin",
			type = "field_dropdown",
			options = {
				{ L"P0", "0" },
				{ L"P1", "1" },
				{ L"P2", "2" },
				{ L"P5(button_A)", "5" },
				{ L"P6(buzzer)", "6" },
				{ L"P7(RGB)", "7" },
				{ L"P8", "8" },
				{ L"P9", "9" },
				{ L"P11(button_B)", "11" },
				{ L"P12", "12" },
				{ L"P13", "13" },
				{ L"P14", "14" },
				{ L"P15", "15" },
				{ L"P16", "16" },
				{ L"P19(SCL)", "19" },
				{ L"P20(SDA", "20" },
			},
			text = "1",
		},
	},
	output = {type = "null",},
	category = "wifi", 
	helpUrl = "", 
	canRun = false,
	funcName = "hcsr04.init",
	previousStatement = true,
	nextStatement = true,
	headerText = "from mpython import *\nfrom hcsr04 import HCSR04\n",
	func_description = '%s = HCSR04(trigger_pin=Pin.P%s, echo_pin=Pin.P%s)',
	ToNPL = function(self)
		return string.format('%s = HCSR04(trigger_pin=Pin.P%s, echo_pin=Pin.P%s)\n', 
			self:getFieldAsString('name'),self:getFieldAsString('trigger_pin'),self:getFieldAsString('echo_pin'));
	end,
	ToMicroPython = function(self)
		local precode = string.format('%s = HCSR04(trigger_pin=Pin.P%s, echo_pin=Pin.P%s)\n', 
			self:getFieldAsString('name'),self:getFieldAsString('trigger_pin'),self:getFieldAsString('echo_pin'));
		self:GetBlockly():AddUnqiueHeader(precode);
		return "";
	end,
	examples = {{desc = "", canRun = true, code = [[
from hcsr04 import HCSR04
from mpython import *
hcsr04 = HCSR04(trigger_pin=Pin.P16, echo_pin=Pin.P15)
A = None
A = hcsr04.distance_mm()
]]}},
},

{
	type = "hcsr04.distance", 
	message0 = L"%1 hcsr04超声波距离 单位%2",
	arg0 = {
		{
			name = "name",
			type = "input_value",
            shadow = { type = "text", value = "hcsr04"},
			text = "hcsr04", 
		},
		{
			name = "unit",
			type = "field_dropdown",
			options = {
				{ L"毫米", "mm" },
				{ L"厘米", "cm" },
			},
		},
	},
	output = {type = "null",},
	category = "wifi", 
	helpUrl = "", 
	canRun = false,
	headerText = "from mpython import *\nfrom hcsr04 import HCSR04\n",
	func_description = '%s.distance_%s()',
	ToNPL = function(self)
		return string.format('%s.distance_%s()', self:getFieldAsString('name'),self:getFieldAsString('unit'));
	end,
	ToMicroPython = function(self)
		return string.format('%s.distance_%s()', self:getFieldAsString('name'),self:getFieldAsString('unit'));
	end,
	examples = {{desc = "", canRun = true, code = [[
]]}},
},


{
	type = "IRRecever", 
	message0 = L"当从红外接收端 %1 收到消息时",
	message1 = L"%1",
	arg0 = {
		{
			name = "pin",
			type = "field_dropdown",
			options = {
				{ L"P0", "0" },
				{ L"P1", "1" },
				{ L"P2", "2" },
				{ L"P5(button_A)", "5" },
				{ L"P6(buzzer)", "6" },
				{ L"P7(RGB)", "7" },
				{ L"P8", "8" },
				{ L"P9", "9" },
				{ L"P11(button_B)", "11" },
				{ L"P12", "12" },
				{ L"P13", "13" },
				{ L"P14", "14" },
				{ L"P15", "15" },
				{ L"P16", "16" },
				{ L"P19(SCL)", "19" },
				{ L"P20(SDA", "20" },
			},
			text = "8",
		},
	},
	arg1 = {
			{
				name = "input",
				type = "input_statement",
				text = "pass",
			},
		},
	category = "wifi", 
	helpUrl = "", 
	canRun = false,
	funcName = "IRRecever",
	previousStatement = true,
	nextStatement = true,
	headerText = "from mpython import *\nfrom ir_remote import IRReceiver",
	func_description = 'receiver = IRReceiver(Pin.P%s) %s',
	ToNPL = function(self)
		local input = self:getFieldAsString('input');
		if(input == "") then
			input = "pass"
		end
		return string.format('receiver = IRReceiver(Pin.P%s)\nreceiver.daemon()\ndef remote_callback(_address, _command):\n    %s\nreceiver.set_callback(remote_callback)\n', 
			self:getFieldAsString('pin'), input);
	end,
	ToMicroPython = function(self)
		local precode = format("receiver = IRReceiver(Pin.P%s)\nreceiver.daemon()\n", self:getFieldAsString('pin'))
		self:GetBlockly():AddUnqiueHeader(precode);
		local block_indent = self:GetIndent();
		self:SetIndent("") -- tricky: since we are moving the code to header, so we need to remove the indent
		local input = self:getFieldAsString('input');
		
		local global_vars = MicroPython:GetGlobalVarsDefString(self)

		local cbCode = string.format("def remote_callback(_address, _command):\n%s%s\nreceiver.set_callback(remote_callback)\n", 
			global_vars, input);
		self:SetIndent(block_indent)
		self:GetBlockly():AddUnqiueHeader(cbCode);
		return "";
	end,
	examples = {{desc = "", canRun = true, code = [[
]]}},
},

{
	type = "IRReceiver._command", 
	message0 = L"红外接收的数据",
	arg0 = {
	},
	output = {type = "null",},
	category = "wifi", 
	helpUrl = "", 
	canRun = false,
	headerText = "from mpython import *\n",
	func_description = '_command',
	ToNPL = function(self)
		return "_command";
	end,
	ToMicroPython = function(self)
		return '_command';
	end,
	examples = {{desc = "", canRun = true, code = [[
]]}},
},

{
	type = "IRReceiver.send", 
	message0 = L"红外发送 %1 地址 %2 命令%3",
	arg0 = {
		{
			name = "pin",
			type = "field_dropdown",
			options = {
				{ L"P0", "0" },
				{ L"P1", "1" },
				{ L"P2", "2" },
				{ L"P5(button_A)", "5" },
				{ L"P6(buzzer)", "6" },
				{ L"P7(RGB)", "7" },
				{ L"P8", "8" },
				{ L"P9", "9" },
				{ L"P11(button_B)", "11" },
				{ L"P12", "12" },
				{ L"P13", "13" },
				{ L"P14", "14" },
				{ L"P15", "15" },
				{ L"P16", "16" },
				{ L"P19(SCL)", "19" },
				{ L"P20(SDA", "20" },
			},
			text = "8",
		},
		{
			name = "address",
			type = "input_value",
            shadow = { type = "math_number", value = 0,},
			text = 0, 
		},
		{
			name = "command",
			type = "input_value",
            shadow = { type = "math_number", value = 1,},
			text = 1, 
		},
		
	},
	output = {type = "null",},
	category = "wifi", 
	helpUrl = "", 
	canRun = false,
	previousStatement = true,
	nextStatement = true,
	headerText = "from mpython import *\nfrom ir_remote import IRTransmit",
	func_description = 'ir = IRTransmit(Pin.P%s)\nir.send(%s, %s)\n',
	ToNPL = function(self)
		return string.format('ir = IRTransmit(Pin.P%s)\nir.send(%s, %s)\n', 
			self:getFieldAsString('pin'),self:getFieldAsString('address'),self:getFieldAsString('command'));
	end,
	ToMicroPython = function(self)
		self:GetBlockly():AddUnqiueHeader(string.format('ir = IRTransmit(Pin.P%s)\n', self:getFieldAsString('pin')));
		return string.format('ir.send(%s, %s)\n', 
			self:getFieldAsString('address'),self:getFieldAsString('command'));
	end,
	examples = {{desc = "", canRun = true, code = [[
]]}},
},

{
	type = "radio.on", 
	message0 = L"无线广播 %1",
	arg0 = {
		{
			name = "mode",
			type = "field_dropdown",
			options = {
				{ L"打开", "on()" },
				{ L"关闭", "off()" },
			}
		},
	},
	category = "wifi", 
	helpUrl = "", 
	canRun = false,
	previousStatement = true,
	nextStatement = true,
	headerText = "import radio",
	func_description = 'radio.%s',
	ToNPL = function(self)
		return string.format("radio.%s\n", self:getFieldAsString('mode'));
	end,
	ToMicroPython = function(self)
		return string.format("radio.%s\n", self:getFieldAsString('mode'));
	end,
	examples = {{desc = "", canRun = true, code = [[
]]}},
},

{
	type = "radio.channel", 
	message0 = L"无线广播的频道设置为%1",
	arg0 = {
		{
			name = "channel",
			type = "input_value",
            shadow = { type = "math_number", value = 13,},
			text = 13, 
		},
	},
	category = "wifi", 
	helpUrl = "", 
	canRun = false,
	previousStatement = true,
	nextStatement = true,
	headerText = "import radio",
	func_description = 'radio.config(channel=%s)',
	ToNPL = function(self)
		return string.format("radio.config(channel=%s)\n", self:getFieldAsString('channel'));
	end,
	ToMicroPython = function(self)
		return string.format("radio.config(channel=%s)\n", self:getFieldAsString('channel'));
	end,
	examples = {{desc = "", canRun = true, code = [[
]]}},
},

{
	type = "radio.send", 
	message0 = L"无线广播 发送 %1",
	arg0 = {
		{
			name = "msg",
			type = "input_value",
            shadow = { type = "text", value = "msg"},
			text = "msg", 
		},
	},
	category = "wifi", 
	helpUrl = "", 
	canRun = false,
	previousStatement = true,
	nextStatement = true,
	headerText = "import radio",
	func_description = 'radio.send("%s")',
	ToNPL = function(self)
		return string.format("radio.send('%s')\n", self:getFieldAsString('msg'));
	end,
	ToMicroPython = function(self)
		return string.format("radio.send(%s)\n", self:GetValueAsString('msg'));
	end,
	examples = {{desc = "", canRun = true, code = [[
]]}},
},


{
	type = "radio.receive", 
	message0 = L"当收到无线广播消息时",
	message1 = L"%1",
	arg0 = {
	},
	arg1 = {
			{
				name = "input",
				type = "input_statement",
				text = "pass",
			},
		},
	category = "wifi", 
	helpUrl = "", 
	canRun = false,
	funcName = "radio.receive",
	previousStatement = true,
	nextStatement = true,
	headerText = "from mpython import *\nfrom machine import Timer\nimport radio",
	func_description = 'def radio_recv(_radiomsg):\n    %s',
	ToNPL = function(self)
		local input = self:getFieldAsString('input');
		if(input == "") then
			input = "pass"
		end
		return string.format('def radio_recv(_radiomsg):\n    %s\n', input);
	end,
	ToMicroPython = function(self)
		local hexFunc  =  'def str2name(str):\n    return "".join([c if (c.isalpha() or c.isdigit() or c==\'_\') else "_%x" % ord(c) for c in str])\n';
		self:GetBlockly():AddUnqiueHeader(hexFunc);

		local block_indent = self:GetIndent();
		self:SetIndent("") -- tricky: since we are moving the code to header, so we need to remove the indent
		local input = self:getFieldAsString('input');
		
		local global_vars = MicroPython:GetGlobalVarsDefString(self)
		local cbCode = string.format("def radio_recv(_radiomsg):\n%s%s\n", global_vars, input);
		self:SetIndent(block_indent)
		self:GetBlockly():AddUnqiueHeader(cbCode);

		local precode = [[_radio_msg_list = []
def radio_callback(_msg):
    global _radio_msg_list
    try: radio_recv(_msg)
    except: pass
    if _msg in _radio_msg_list:
        eval('radio_recv_' + str2name(_msg) + '()')

tim13 = Timer(13)

def timer13_tick(_):
    _msg = radio.receive()
    if not _msg: return
    radio_callback(_msg)

tim13.init(period=20, mode=Timer.PERIODIC, callback=timer13_tick)]]
		self:GetBlockly():AddUnqiueHeader(precode);

		return "";
	end,
	examples = {{desc = "", canRun = true, code = [[
]]}},
},

{
	type = "radio.radiomsg", 
	message0 = L"收到的无线广播消息",
	arg0 = {
	},
	output = {type = "null",},
	category = "wifi", 
	helpUrl = "", 
	canRun = false,
	headerText = "",
	func_description = '_radiomsg',
	ToNPL = function(self)
		return "_radiomsg";
	end,
	ToMicroPython = function(self)
		return "_radiomsg";
	end,
	examples = {{desc = "", canRun = true, code = [[
]]}},
},

{
	type = "radio.receiveGivenMsg", 
	message0 = L"当收到特定无线广播消息%1时",
	message1 = L"%1",
	arg0 = {
		{
			name = "msg",
			type = "input_value",
            shadow = { type = "text", value = "on"},
			text = "on", 
		},
	},
	arg1 = {
			{
				name = "input",
				type = "input_statement",
				text = "pass",
			},
		},
	category = "wifi", 
	helpUrl = "", 
	canRun = false,
	funcName = "radio.receiveGivenMsg",
	previousStatement = true,
	nextStatement = true,
	headerText = "from mpython import *\nfrom machine import Timer\nimport radio",
	func_description = 'def radio_recv_%s():\n    %s',
	ToNPL = function(self)
		local input = self:getFieldAsString('input');
		if(input == "") then
			input = "pass"
		end
		return string.format('def radio_recv_%s():\n    %s\n', commonlib.Encoding.toValidParamName(self:getFieldAsString('msg')), input);
	end,
	ToMicroPython = function(self)
		local hexFunc  =  'def str2name(str):\n    return "".join([c if (c.isalpha() or c.isdigit() or c==\'_\') else "_%x" % ord(c) for c in str])\n';
		self:GetBlockly():AddUnqiueHeader(hexFunc);

		local block_indent = self:GetIndent();
		self:SetIndent("") -- tricky: since we are moving the code to header, so we need to remove the indent
		local input = self:getFieldAsString('input');
	
		local precode = [[_radio_msg_list = []
def radio_callback(_msg):
    global _radio_msg_list
    try: radio_recv(_msg)
    except: pass
    if _msg in _radio_msg_list:
        eval('radio_recv_' + str2name(_msg) + '()')

tim13 = Timer(13)

def timer13_tick(_):
    _msg = radio.receive()
    if not _msg: return
    radio_callback(_msg)

tim13.init(period=20, mode=Timer.PERIODIC, callback=timer13_tick)]]
		self:GetBlockly():AddUnqiueHeader(precode);

		local global_vars = MicroPython:GetGlobalVarsDefString(self)
		return string.format('_radio_msg_list.append(%s)\ndef radio_recv_%s():\n%s%s\n', self:GetValueAsString('msg'), commonlib.Encoding.toValidParamName(self:getFieldAsString('msg')), global_vars, input);
	end,
	examples = {{desc = "", canRun = true, code = [[
]]}},
},


});