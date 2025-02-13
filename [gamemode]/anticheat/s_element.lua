--[[
 * ***********************************************************************************************************************
 * Copyright (c) 2015 OwlGaming Community - All Rights Reserved
 * All rights reserved. This program and the accompanying materials are private property belongs to OwlGaming Community
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * ***********************************************************************************************************************
 ]]

local secretHandle = 'DwcbeZdBsd432Hcw2SvySv5FcW'

addEventHandler("onElementDataChange", getRootElement(),
	function(index, oldValue, newValue)
		if not client then return end
		if (index ~= "interiormarker") then
			local isProtected = getElementData(source, secretHandle .. "p:" .. index)
			if (isProtected) then
				local playername = getPlayerName(source) or inspect(source)
				local msg = "[AdmWarn] " .. getPlayerName(client) .. " sent illegal data. "
				local msg2 = " (victim: " ..
					playername ..
					" index: " ..
					index .. " newvalue:" .. tostring(newValue) .. " oldvalue:" .. tostring(oldValue) .. ")"
				exports.global:sendMessageToAdmins(msg)
				exports.global:sendMessageToAdmins(msg2)

				changeProtectedElementDataEx(source, index, oldValue, true)
				exports.bans:ban("[ANTICHEAT]", client, 0, "Hacked Client.")
			end
		end
	end
);

addEventHandler("onPlayerJoin", getRootElement(),
	function()
		protectElementData(source, "account:id")
		protectElementData(source, "account:username")
		protectElementData(source, "legitnamechange")
		protectElementData(source, "dbid")
	end
);

function allowElementData(thePlayer, index)
	return setElementData(thePlayer, secretHandle .. "p:" .. index, false, false)
end

function protectElementData(thePlayer, index)
	return setElementData(thePlayer, secretHandle .. "p:" .. index, true, false)
end

function changeProtectedElementData(thePlayer, index, newvalue)
	if allowElementData(thePlayer, index) then
		local set = setElementData(thePlayer, index, newvalue)
		if protectElementData(thePlayer, index) then
			return set
		end
	end
end

function changeProtectedElementDataEx(thePlayer, index, newvalue, sync)
	if (thePlayer) and (index) then
		if not newvalue then
			newvalue = nil
		end

		if allowElementData(thePlayer, index) then
			local set = setElementData(thePlayer, index, newvalue, sync)

			if protectElementData(thePlayer, index) then
				return set
			end
		end
		return false
	end
	return false
end

function setEld(thePlayer, index, newvalue, sync)
	local sync2 = false
	if sync == "one" then
		sync2 = false
	elseif sync == "all" then
		sync2 = true
	else
		sync2 = false
	end
	return changeProtectedElementDataEx(thePlayer, index, newvalue, sync2)
end

function genHandle()
	local hash = ''
	for i = 1, math.random(5, 16) do
		hash = hash .. string.char(math.random(65, 122))
	end
	return hash
end

function fetchH()
	return secretHandle
end

secretHandle = genHandle()
