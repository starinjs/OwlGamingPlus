local mysql = exports.mysql
--local salt = "wedorp"

function clientReady()
	local thePlayer = source
	local resources = getResources()
	local missingResources = false
	for key, value in ipairs(resources) do
		local resourceName = getResourceName(value)
		if resourceName == "global" or resourceName == "mysql" or resourceNmae == "pool" then
			if getResourceState(value) == "loaded" or getResourceState(value) == "stopping" or getResourceState(value) == "failed to load" then
				missingResources = true
				exports.discord_webhooks:send("manager-webhook","The server is missing dependent resource '"..getResourceName(value).."'.")
				outputChatBox("The server is missing dependent resource '"..getResourceName(value).."'.", thePlayer, 255, 0, 0)
				outputChatBox("Please try again shortly.", thePlayer, 255, 0, 0)
				outputChatBox("       - The Owl Gaming Administration Team", thePlayer, 255, 0, 0)
				break
			end
		end
	end
	if missingResources then return end
	local willPlayerBeBanned = false
	local bannedIPs = exports.global:fetchIPs()
	local playerIP = getPlayerIP(thePlayer)
	for key, value in ipairs(bannedIPs) do
		if playerIP == value then
			outputChatBox("Your IP is blacklisted from the server.", thePlayer, 255, 0, 0)
			setTimer(outputChatBox, 1000, 1, "You will be kicked from the server in 10 secconds.", thePlayer, 255, 0, 0)
			setTimer(kickPlayer, 10000, 1, thePlayer, "You are blacklisted from this server.")
			willPlayerBeBanned = true
			break
		end
	end
	if not willPlayerBeBanned then
		local bannedSerials = exports.global:fetchSerials()
		local playerSerial = getPlayerSerial(thePlayer)
		for key, value in ipairs(bannedSerials) do
			if playerSerial == value then
				outputChatBox("Your serial is blacklisted from the server.", thePlayer, 255, 0, 0)
				setTimer(outputChatBox, 1000, 1, "You will be kicked from the server in 10 secconds.", thePlayer, 255, 0, 0)
				setTimer(kickPlayer, 10000, 1, thePlayer, "You are blacklisted from this server.")
				willPlayerBeBanned = true
				break
			end
		end
	end
	if not willPlayerBeBanned then
		triggerClientEvent(thePlayer, "beginLogin", thePlayer)
	else
		triggerClientEvent(thePlayer, "beginLogin", thePlayer, "Banned.")
	end
end
addEvent("onJoin", true)
addEventHandler("onJoin", getRootElement(), clientReady)

addEventHandler("accounts:login:request", root,
    function ()
        local player = source
        local seamless = getElementData(player, "account:seamless:validated")

        if seamless then
            setElementData(player, "account:seamless:validated", false, true) -- Fixed
            triggerClientEvent(player, "accounts:options", player)
            triggerClientEvent(player, "item:updateclient", player)
            return
        end

        triggerClientEvent(player, "accounts:login:request", player)
    end
)


function quitPlayer(quitReason, reason)
	local accountID = tonumber(getElementData(source, "account:id"))
	if accountID then
		local affected = { "ac"..tostring(accountID) }
		local dbID = getElementData(source,"dbid")
		if dbID then
			table.insert(affected, "ch"..tostring(dbID))
		end
		exports.logs:dbLog("ac"..tostring(accountID), 27, affected, "Disconnected (".. (quitReason or "Unknown reason") ..") (Name: "..getPlayerName(source)..")" )
	end
end
addEventHandler("onPlayerQuit",getRootElement(), quitPlayer)