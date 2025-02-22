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
	-- Example:
	["my_webhook"] = "https://discord.com/api/webhooks/123456/abcdefgh",
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
