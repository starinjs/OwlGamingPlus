-- Scripter rank
local function getPlayerScripterRank( player )
    if exports.integration:isPlayerLeadScripter( player ) then
        return "Scripter"
    elseif exports.integration:isPlayerScripter( player ) then
        return "Trial Scripter"
    elseif exports.integration:isPlayerTester( player ) then
        return "Tester"
    else
        return ""
    end
end

-- Function to show administrators only
function showAdmins(thePlayer, commandName)
    local logged = getElementData(thePlayer, "loggedin")
    local info = {}
    local isOverlayDisabled = getElementData(thePlayer, "hud:isOverlayDisabled")

    -- ADMINS --
    if(logged==1) then
        local players = exports.global:getAdmins()
        local counter = 0

        admins = {}

        if isOverlayDisabled then
            outputChatBox("ADMINISTRATORS:", thePlayer, 255, 194, 14)
        else
            table.insert(info, {"Administration Team:", 255, 194, 14, 255, 1, "title"})
            table.insert(info, {""})
        end

        for k, arrayPlayer in ipairs(players) do
            local hiddenAdmin = getElementData(arrayPlayer, "hiddenadmin")
            local logged = getElementData(arrayPlayer, "loggedin")

            if logged == 1 then
                if tonumber(getElementData( arrayPlayer, "admin_level" )) < 10 then
                    if exports.integration:isPlayerTrialAdmin(arrayPlayer) and ( hiddenAdmin == 0 or ( exports.integration:isPlayerTrialAdmin(thePlayer) or exports.integration:isPlayerScripter(thePlayer) ) ) and not exports.integration:isPlayerIA( arrayPlayer ) then
                        admins[ #admins + 1 ] = { arrayPlayer, getElementData( arrayPlayer, "admin_level" ), getElementData( arrayPlayer, "duty_admin" ), exports.global:getPlayerName( arrayPlayer ) }
                    end
                end
            end
        end

        table.sort( admins, sortTable )

        for k, v in ipairs(admins) do
            arrayPlayer = v[1]
            local adminTitle = exports.global:getPlayerAdminTitle(arrayPlayer)
            local hiddenAdmin = getElementData(arrayPlayer, "hiddenadmin")
            if hiddenAdmin == 0 or exports.integration:isPlayerTrialAdmin(thePlayer) then
                v[4] = v[4] .. " (" .. tostring(getElementData(arrayPlayer, "account:username")) .. ")"
                local afk = getElementData(arrayPlayer, "afk")
                r, g, b = 0, 200, 10
                r2, g2, b2 = 0, 255, 0
                if afk then
                    r, g, b = 100, 100, 100 -- outputChatBox
                    r2, g2, b2 = 200, 200, 200 -- Overlay
                end

                if not exports.integration:isPlayerTrialAdmin(thePlayer) then -- Regular players see all admins without  a duty status
                    if isOverlayDisabled then
                        outputChatBox("-    " .. tostring(adminTitle) .. " " .. tostring(v[4]):gsub("_"," ") .. (afk and " - AFK" or ""), thePlayer, r, g, b)
                    else
                        table.insert(info, {"-    " .. tostring(adminTitle) .. " " .. tostring(v[4]):gsub("_"," ") .. (afk and " - AFK" or ""), r2, g2, b2, 255, 1, "default"})
                    end
                else -- Admins can see the duty status of other admins
                    if(v[3]==1)then
                        if isOverlayDisabled then
                            outputChatBox("-    " .. tostring(adminTitle) .. " " .. tostring(v[4]):gsub("_"," ").." - On Duty" .. (afk and " - AFK" or ""), thePlayer, 0, 200, 10)
                        else
                            table.insert(info, {"-    " .. tostring(adminTitle) .. " " .. tostring(v[4]):gsub("_"," ").." - On Duty" .. (afk and " - AFK" or ""), 0, 255, 0, 255, 1, "default"})
                        end
                    else
                        if isOverlayDisabled then
                            outputChatBox("-    " .. tostring(adminTitle) .. " " .. tostring(v[4]):gsub("_"," ").." - Off Duty" .. (afk and " - AFK" or ""), thePlayer, 100, 100, 100)
                        else
                            table.insert(info, {"-    " .. tostring(adminTitle) .. " " .. tostring(v[4]):gsub("_"," ").." - Off Duty" .. (afk and " - AFK" or ""), 200, 200, 200, 255, 1, "default"})
                        end
                    end
                end
            end
        end

        if #admins == 0 then
            if isOverlayDisabled then
                outputChatBox("-    Currently no administrators online.", thePlayer)
            else
                table.insert(info, {"-    Currently no administrators online.", 255, 255, 255, 255, 1, "default"})
            end
        end
    end

    if logged == 1 then
        if not isOverlayDisabled then
            exports.hud:sendTopRightNotification(thePlayer, info, 350)
        end
    end
end
addCommandHandler("admins", showAdmins, false, false)
addCommandHandler("staff", showAdmins, false, false)

-- Function to show vehicle team only
function showVehicleTeam(thePlayer, commandName)
    local logged = getElementData(thePlayer, "loggedin")
    local info = {}
    local isOverlayDisabled = getElementData(thePlayer, "hud:isOverlayDisabled")

    if(logged==1) then
        local players = exports.pool:getPoolElementsByType("player")
        local counter = 0

        if isOverlayDisabled then
            outputChatBox("VEHICLE TEAM:", thePlayer, 255, 194, 14)
        else
            table.insert(info, {"Vehicle Team:", 255, 194, 14, 255, 1, "title"})
            table.insert(info, {""})
        end

        for k, arrayPlayer in ipairs(players) do
            local logged = getElementData(arrayPlayer, "loggedin")
            local afk = getElementData(arrayPlayer, "afk")
            if logged == 1 then
                if exports.integration:isPlayerVCTMember(arrayPlayer) then
                    local hiddenAdmin = getElementData(arrayPlayer, "hiddenadmin")
                    local stuffToPrint
                    if (hiddenAdmin == 1) then
                        stuffToPrint = "-    "..(exports.integration:isPlayerVehicleConsultant(arrayPlayer) and "Leader" or "Member").." (Hidden) "..exports.global:getPlayerName(arrayPlayer).." ("..getElementData(arrayPlayer, "account:username")..")".. (afk and " - AFK" or "")
                    else
                        stuffToPrint = "-    "..(exports.integration:isPlayerVehicleConsultant(arrayPlayer) and "Leader" or "Member").." "..exports.global:getPlayerName(arrayPlayer).." ("..getElementData(arrayPlayer, "account:username")..")".. (afk and " - AFK" or "")
                    end
                    if (hiddenAdmin == 0 or ( exports.integration:isPlayerTrialAdmin(thePlayer) or exports.integration:isPlayerScripter(thePlayer) ) ) then
                        local r, g, b = 0, 255, 0 --hud colour
                        local cR, cG, cB = 0, 200, 10 --chatbox colour
                        if(hiddenAdmin == 1) or afk then
                            r, g, b = 200, 200, 200
                            cR, cG, cB = 100, 100, 100
                        end
                        if isOverlayDisabled then
                            outputChatBox(stuffToPrint, thePlayer, cR, cG, cB)
                        else
                            table.insert(info, {stuffToPrint, r, g, b, 255, 1, "default"})
                        end
                        counter = counter + 1
                    end
                end
            end
        end

        if counter == 0 then
            if isOverlayDisabled then
                outputChatBox("-    Currently no members online.", thePlayer)
            else
                table.insert(info, {"-    Currently no members online.", 255, 255, 255, 255, 1, "default"})
            end
        end
    end

    if logged == 1 then
        if not isOverlayDisabled then
            exports.hud:sendTopRightNotification(thePlayer, info, 350)
        end
    end
end
addCommandHandler("vct", showVehicleTeam, false, false)

-- Function to show scripters only
function showScripters(thePlayer, commandName)
    local logged = getElementData(thePlayer, "loggedin")
    local info = {}
    local isOverlayDisabled = getElementData(thePlayer, "hud:isOverlayDisabled")

    if(logged==1) then
        local players = exports.pool:getPoolElementsByType("player")
        local counter = 0

        if isOverlayDisabled then
            outputChatBox("SCRIPTERS:", thePlayer, 255, 194, 14)
        else
            table.insert(info, {"Scripters:", 255, 194, 14, 255, 1, "title"})
            table.insert(info, {""})
        end

        for k, arrayPlayer in ipairs(players) do
            local logged = getElementData(arrayPlayer, "loggedin")
            if logged == 1 then
                if exports.integration:isPlayerScripter(arrayPlayer) then
                    local hiddenAdmin = getElementData(arrayPlayer, "hiddenadmin")
                    local adminTitle = getPlayerScripterRank( arrayPlayer )
                    local stuffToPrint
                    if (hiddenAdmin == 1) then
                        stuffToPrint = "-    (Hidden) "..tostring(adminTitle).." "..exports.global:getPlayerName(arrayPlayer).." ("..getElementData(arrayPlayer, "account:username")..")"
                    else
                        stuffToPrint = "-    "..tostring(adminTitle).." "..exports.global:getPlayerName(arrayPlayer).." ("..getElementData(arrayPlayer, "account:username")..")"
                    end
                    if (hiddenAdmin == 0 or ( exports.integration:isPlayerTrialAdmin(thePlayer) or exports.integration:isPlayerScripter(thePlayer) ) ) then
                        local r, g, b = 0, 255, 0 --hud colour
                        local cR, cG, cB = 0, 200, 10 --chatbox colour
                        if(hiddenAdmin == 1) then
                            r, g, b = 200, 200, 200
                            cR, cG, cB = 100, 100, 100
                        end
                        if isOverlayDisabled then
                            outputChatBox(stuffToPrint, thePlayer, cR, cG, cB)
                        else
                            table.insert(info, {stuffToPrint, r, g, b, 255, 1, "default"})
                        end
                        counter = counter + 1
                    end
                end
            end
        end

        if counter == 0 then
            if isOverlayDisabled then
                outputChatBox("-    Currently no scripters online.", thePlayer)
            else
                table.insert(info, {"-    Currently no scripters online.", 255, 255, 255, 255, 1, "default"})
            end
        end
    end

    if logged == 1 then
        if not isOverlayDisabled then
            exports.hud:sendTopRightNotification(thePlayer, info, 350)
        end
    end
end
addCommandHandler("scripters", showScripters, false, false)

-- Helper functions
local function sortTable( a, b )
    if b[2] < a[2] then
        return true
    end

    if b[2] == a[2] and b[4] > a[4] then
        return true
    end

    return false
end

function toggleOverlay(thePlayer, commandName)
    if getElementData(thePlayer, "hud:isOverlayDisabled") then
        setElementData(thePlayer, "hud:isOverlayDisabled", false)
        outputChatBox("You enabled overlay menus.",thePlayer)
    else
        setElementData(thePlayer, "hud:isOverlayDisabled", true)
        outputChatBox("You disabled overlay menus.", thePlayer)
    end
end
addCommandHandler("toggleOverlay", toggleOverlay, false, false)
addCommandHandler("togOverlay", toggleOverlay, false, false)