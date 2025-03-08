--[[
	Author: https://github.com/Fernando-A-Rocha

	Discord Webhooks MTA Resource (Config)
]]

--[[
	List of defined webhooks
	Format: name => URL

		name: can be any string of your choice,
			it is what you will use to trigger it
		URL: webhook URL must be the one you copied
			from channel settings -> Integrations -> Webhooks -> Your webhook -> Copy URL
]]
WEB_HOOKS = {
	["staff-webhook"] = "https://discord.com/api/webhooks/1347992202252652705/v9-D5bhVEdtE4JZdXVbRr75h4WA2YoW15K4dlTXSo2UZz7OLuAdiIMInFY1hG6weS_kR",
	["manager-webhook"] = "https://discord.com/api/webhooks/1347992439042084915/T5kaXRFINftXzRqOhUueyuB_xIQhI8h_4H_3xqw5Eg9_QqfepEgUdM2SGEsmEttV2kW3",
	["ads-webhook"] = "https://discord.com/api/webhooks/1347992610098380860/v-_E3gxPUrbz7xGkbScG0ReZz5_uON-H-wH0CuRBrgqXhnMwGcyRTnSijce0ssFpArQW",
	["player-webhook"] = "https://discord.com/api/webhooks/1347992732672720958/I94GptcmIGY0RXSL03wj-81ZXo6gXWtB9-HXp0i6eBRuTKXFyQmeIcCct7MgS7HPkmt4",
}

-- Custom Log messages format (e.g. add prefix, etc.):
_outputDebugString = outputDebugString
function outputDebugString(message, ...)
	return _outputDebugString("[Discord Webhooks] " .. tostring(message), ...)
end
_outputServerLog = outputServerLog
function outputServerLog(message)
	return _outputServerLog("[Discord Webhooks] " .. tostring(message))
end

-- Set to true to log informative messages to debug console:
LOG_INFO_DEBUG = false

-- Set to true to log errors to debug console:
LOG_ERRORS_DEBUG = true

-- (OPTIONAL) You may want to add a setting to your server's Settings Registry to disable Webhooks
-- 		e.g. You are running a Development server which mirrors your Production server's resources
-- 		and you want to prevent Webhooks from being triggered on the Development server
-- Set it to "1" or "true" to disable webhooks from being triggered
-- Custom Setting name:
SETTING_DISABLE = "@discord_webhooks.disabled"
