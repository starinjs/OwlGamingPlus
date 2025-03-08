--[[
* ***********************************************************************************************************************
* Copyright (c) 2015 OwlGaming Community - All Rights Reserved
* All rights reserved. This program and the accompanying materials are private property belongs to OwlGaming Community
* Unauthorized copying of this file, via any medium is strictly prohibited
* Proprietary and confidential
* ***********************************************************************************************************************
]]

-- Global variables
local hitPickup = nil
local isLastSourceInterior = nil
local recentlyExitedInterior = false
local exitCooldownTimer = nil
local EXIT_COOLDOWN_TIME = 2000 -- 2 seconds cooldown after exiting an interior
local scrWidth, scrHeight = guiGetScreenSize()
local yOffset = scrHeight - 130 -- Adjusted from 110 to 130 to account for a new line of text for address
local margin = 3
local textShadowDistance = 3
local intNameFont = "default-bold"
local BizNoteFont = "default-bold"

-- Function to handle interior entrance
function enterInterior()
    if not hitPickup then return end

    -- Detect Vehicle
    local vehicleElement = false
    local theVehicle = getPedOccupiedVehicle(localPlayer)
    if theVehicle and getVehicleOccupant(theVehicle, 0) == localPlayer then
        vehicleElement = theVehicle
    end

    local foundInterior = getElementParent(hitPickup)
    local interiorID = getElementData(foundInterior, "dbid")
    
    if not interiorID then return end
    
    local canEnter, errorCode, errorMsg = canEnterInterior(foundInterior)
    if canEnter or isInteriorForSale(foundInterior) then
        if getElementType(foundInterior) == "interior" then
            if not vehicleElement then
                triggerServerEvent("interior:enter", foundInterior)
            end
        else
            triggerServerEvent("elevator:enter", foundInterior, getElementData(hitPickup, "type") == "entrance")
        end
    else
        outputChatBox(errorMsg, 255, 0, 0)
    end
end

-- Key binding functions
function bindKeys()
    bindKey("enter", "down", enterInterior)
    bindKey("f", "down", enterInterior)
    toggleControl("enter_exit", false)
end

function unbindKeys()
    unbindKey("enter", "down", enterInterior)
    unbindKey("f", "down", enterInterior)
    toggleControl("enter_exit", true)
end

-- Pickup handling functions
function hitInteriorPickup(theElement, matchingdimension)
    local pickup = getElementParent(source)
    if getElementType(pickup) ~= "interior" and getElementType(pickup) ~= "elevator" then
        return
    end
    
    local isVehicle = false
    local theVehicle = getPedOccupiedVehicle(localPlayer)
    if theVehicle and theVehicle == theElement and getVehicleOccupant(theVehicle, 0) == localPlayer then
        isVehicle = true
    end

    if matchingdimension and (theElement == localPlayer or isVehicle) then
        bindKeys()
        hitPickup = source
        playSoundFrontEnd(2)
        
        isLastSourceInterior = (getElementType(pickup) == "interior")
    end
    
    cancelEvent()
end
addEventHandler("onClientPickupHit", root, hitInteriorPickup)

function leaveInteriorPickup(theElement, matchingdimension)
    local isVehicle = false
    local theVehicle = getPedOccupiedVehicle(localPlayer)
    if theVehicle and theVehicle == theElement and getVehicleOccupant(theVehicle, 0) == localPlayer then
        isVehicle = true
    end

    if hitPickup == source and (theElement == localPlayer or isVehicle) then
        hitPickup = nil
    end
end
addEventHandler("onClientPickupLeave", root, leaveInteriorPickup)

function hideInteriorPickup()
    hitPickup = nil
end
addEventHandler("account:changingchar", localPlayer, hideInteriorPickup)

-- Track dimension changes to detect when player exits an interior
function onDimensionChange(oldDimension, newDimension)
    if oldDimension > 0 and newDimension == 0 then
        -- Player just exited an interior
        recentlyExitedInterior = true
        
        -- Clear any existing timer
        if exitCooldownTimer and isTimer(exitCooldownTimer) then
            killTimer(exitCooldownTimer)
        end
        
        -- Set a timer to reset the flag after cooldown period
        exitCooldownTimer = setTimer(function()
            recentlyExitedInterior = false
        end, EXIT_COOLDOWN_TIME, 1)
    end
end
addEventHandler("onClientElementDimensionChange", localPlayer, onDimensionChange)

-- Helper functions for permissions
function canPlayerKnowInteriorOwner(theInterior)
    return (getElementData(theInterior, "status").owner == 0) -- unowned
        or (exports.integration:isPlayerTrialAdmin(localPlayer) and (getElementData(localPlayer, "duty_admin") == 1))
        or (getElementData(localPlayer, "dbid") == getElementData(theInterior, "status").owner)
end

function canPlayerSeeInteriorID(theInterior)
    local factionTable = getElementData(localPlayer, "faction")
    return factionTable[1]  -- LSPD
        or factionTable[3]  -- Gov
        or factionTable[50] -- SCoSA
        or factionTable[59] -- SAHP
        or (exports.integration:isPlayerTrialAdmin(localPlayer) and (getElementData(localPlayer, "duty_admin") == 1))
        or (exports.integration:isPlayerSupporter(localPlayer) and (getElementData(localPlayer, "duty_supporter") == 1))
        or (exports.integration:isPlayerMappingTeamMember(localPlayer))
end

function canPlayerSeeActivity(theInterior)
    -- Only on-duty admin & interior owner can see activity
    return (exports.integration:isPlayerTrialAdmin(localPlayer) and getElementData(localPlayer, "duty_admin") == 1) 
        or (getElementData(localPlayer, "dbid") == getElementData(theInterior, "status").owner)
end

-- Check if player is inside an interior or recently exited
function shouldShowNotifications()
    local dimension = getElementDimension(localPlayer)
    -- Don't show notifications if in interior or recently exited
    return dimension == 0 and not recentlyExitedInterior
end

-- Render interior information
function renderInteriorName()
    if not hitPickup or not isElement(hitPickup) then
        unbindKeys()
        return
    end
    
    local theInterior = hitPickup
    local showNotifications = shouldShowNotifications()
    
    -- Basic setup
    local intInst = "Enter elevator"
    local intStatus = getElementData(theInterior, "status")
    local intName = isLastSourceInterior and getElementData(theInterior, "name") or "Elevator"
    
    -- Calculate text dimensions
    local intName_width = dxGetTextWidth(intName, 1, intNameFont) + textShadowDistance * 2 + 50
    local intName_left = (scrWidth - intName_width) / 2
    local intName_height = dxGetFontHeight(1, intNameFont)
    local intName_top = (yOffset - intName_height)
    local intName_right = intName_left + intName_width
    local intName_bottom = intName_top + intName_height

    -- Determine text color
    local textColor = tocolor(255, 255, 255, 255)
    local protectedText, inactiveText = nil, nil
    
    if canPlayerSeeActivity(theInterior) then
        local protected, details = isProtected(theInterior)
        if protected then
            textColor = tocolor(0, 255, 0, 255)
            protectedText = "[Inactivity protection remaining: " .. details .. "]"
        else
            local active, details2 = isActive(theInterior)
            if not active then
                textColor = tocolor(150, 150, 150, 255)
                inactiveText = "[" .. details2 .. "]"
            end
        end
    end

    -- Interior name positions
    local n_l = intName_left
    local n_t = intName_top
    local n_r = intName_right
    local n_b = intName_bottom

    -- Interior preview positions
    local img_w, img_h = math.max(400, intName_width + 20), 125
    local img_l = (scrWidth - img_w) / 2
    local img_t = scrHeight - img_h - 40

    intName_top = intName_top + intName_height

    if isLastSourceInterior then
        -- Draw business note
        local intType = intStatus.type
        local bizNote = getElementData(theInterior, "business:note")
        if intType == 1 and bizNote and type(bizNote) == "string" and string.len(bizNote) > 0 then
            local bizNote_width = dxGetTextWidth(bizNote, 1, BizNoteFont) + 20
            local bizNote_left = (scrWidth - bizNote_width) / 2
            local bizNote_height = dxGetFontHeight(1, BizNoteFont)
            intName_top = intName_top - margin
            local bizNote_right = bizNote_left + bizNote_width
            local bizNote_bottom = intName_top + bizNote_height
            
            if showNotifications then
                exports.script_notification:showNotification(bizNote, {30, 30, 30})
            end
            
            intName_top = intName_top + bizNote_height
        end

        -- Draw Address
        local intAddress = getElementData(theInterior, "address")
        if intAddress and intAddress ~= "" then
            local addressText = "Address: " .. intAddress
            local intAddress_width = dxGetTextWidth(addressText, 1, "default")
            local intAddress_left = (scrWidth - intAddress_width) / 2
            local intAddress_height = dxGetFontHeight(1, "default")
            intName_top = intName_top + margin
            local intAddress_right = intAddress_left + intAddress_width
            local intAddress_bottom = intName_top + intAddress_height
            
            if showNotifications then
                exports.script_notification:showNotification(addressText, {30, 30, 30})
            end
            
            intName_top = intName_top + intAddress_height
        end

        -- Draw owner information
        local intOwner = ""
        if intStatus.owner > 0 then
            local ownerName = exports.cache:getCharacterNameFromID(intStatus.owner)
            if intType == 3 then
                intOwner = "Rented by " .. (ownerName or "..Loading..")
                intInst = "Enter interior"
            elseif intType ~= 2 then
                intOwner = "Owned by " .. (ownerName or "..Loading..")
                intInst = "Enter interior"
            end
        elseif intStatus.faction > 0 then
            local ownerName = exports.cache:getFactionNameFromId(intStatus.faction)
            if intType ~= 2 then
                intOwner = "Owned by " .. (ownerName or "..Loading..")
                intInst = "Enter interior"
            end
        else
            if intType == 2 then
                intOwner = "Owned by no-one"
                intInst = "Enter interior"
            elseif intType == 3 then
                local intPrice = exports.global:formatMoney(intStatus.cost)
                intOwner = "For rent: $" .. intPrice
                intInst = "Rent interior"
            else
                local intPrice = exports.global:formatMoney(intStatus.cost)
                intOwner = "For sale: $" .. intPrice
                intInst = "Purchase interior"
                local interiorID = getElementData(theInterior, 'interior_id')
                local url = interiorID and string.format(":resources/interiors/%d.jpg", tonumber(interiorID)) or ":resources/images/loading.jpg"
                dxDrawImage(img_l, img_t, img_w, img_h, url)
            end
        end
        
        if intOwner ~= "" then
            local intOwner_width = dxGetTextWidth(intOwner, 1, "default")
            local intOwner_left = (scrWidth - intOwner_width) / 2
            local intOwner_height = dxGetFontHeight(1, "default")
            intName_top = intName_top + margin
            local intOwner_right = intOwner_left + intOwner_width
            local intOwner_bottom = intName_top + intOwner_height
            
            dxDrawText(intOwner, intOwner_left, intName_top, intOwner_right, intOwner_bottom, textColor,
                1, "default", "center", "center", false, true)
            
            intName_top = intName_top + intOwner_height
        end

        -- Draw protection status
        if protectedText then
            local intProtected_width = dxGetTextWidth(protectedText, 1, "default")
            local intProtected_left = (scrWidth - intProtected_width) / 2
            local intProtected_height = dxGetFontHeight(1, "default")
            intName_top = intName_top + margin
            local intProtected_right = intProtected_left + intProtected_width
            local intProtected_bottom = intName_top + intProtected_height

            dxDrawText(protectedText, intProtected_left, intName_top, intProtected_right, intProtected_bottom, textColor,
                1, "default", "center", "center", false, true)
                
            intName_top = intName_top + intProtected_height
        elseif inactiveText then
            local intProtected_width = dxGetTextWidth(inactiveText, 1, "default")
            local intProtected_left = (scrWidth - intProtected_width) / 2
            local intProtected_height = dxGetFontHeight(1, "default")
            intName_top = intName_top + margin
            local intProtected_right = intProtected_left + intProtected_width
            local intProtected_bottom = intName_top + intProtected_height

            dxDrawText(inactiveText, intProtected_left, intName_top, intProtected_right, intProtected_bottom, textColor,
                1, "default", "center", "center", false, true)
                
            intName_top = intName_top + intProtected_height
        end
    end

    -- Draw interior name with shadow
    dxDrawText(intName or "Unknown Interior", n_l + textShadowDistance, n_t + textShadowDistance, 
        n_r + textShadowDistance, n_b + textShadowDistance, tocolor(0, 0, 0, 255),
        1.5, intNameFont, "center", "center", false, true)
        
    dxDrawText(intName or "Unknown Interior", n_l, n_t, n_r, n_b, textColor,
        1.5, intNameFont, "center", "center", false, true)

    -- Draw instructions
    local intInst_width = dxGetTextWidth(intInst, 1, "default")
    local intInst_left = (scrWidth - intInst_width) / 2
    local intInst_height = dxGetFontHeight(1, "default")
    intName_top = intName_top + margin
    local intInst_right = intInst_left + intInst_width
    local intInst_bottom = intName_top + intInst_height
    
    if showNotifications then
        exports.script_notification:showNotification(intInst, {30, 30, 30}, "F")
    end
    
    intName_top = intName_top + intInst_height

    -- Interior ID for admins/factions with MDC access
    if isLastSourceInterior and canPlayerSeeInteriorID(theInterior) then
        local intId = "(( ID: " .. getElementData(theInterior, "dbid") .. " ))"
        local intId_width = dxGetTextWidth(intId, 1, "default")
        local intId_left = (scrWidth - intId_width) / 2
        local intId_height = dxGetFontHeight(1, "default")
        intName_top = intName_top + margin
        local intId_right = intId_left + intId_width
        local intId_bottom = intName_top + intId_height
        
        if showNotifications then
            exports.script_notification:showNotification(intId, {30, 30, 30})
        end
        
        intName_top = intName_top + intId_height
    end
end
addEventHandler("onClientRender", root, renderInteriorName)