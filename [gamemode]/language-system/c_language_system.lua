-- Compact Language GUI System
local screenW, screenH = guiGetScreenSize()
local fonts = {
    bold = dxCreateFont(":resources/fonts/Roboto-Bold.ttf", 12) or "default-bold",
    regular = dxCreateFont(":resources/fonts/Roboto-Regular.ttf", 10) or "default",
    light = dxCreateFont(":resources/fonts/Roboto-Light.ttf", 8) or "default",
    awesome = dxCreateFont(":resources/fonts/FontAwesome.otf", 10) or "default-bold"
}

-- Animation variables
local isOpen = false
local animProgress = 0
local targetProgress = 0
local lastTick = getTickCount()
local fadeSpeed = 0.008

-- Faster animations for confirmation window
local confirmLastTick = getTickCount()
local confirmFadeSpeed = 0.016 -- Increased speed even more for smoother animation

-- Color settings
local colors = {
    background = tocolor(20, 20, 20, 220),
    header = tocolor(16, 89, 138, 255),
    buttonHover = tocolor(30, 30, 30, 255),
    buttonNormal = tocolor(40, 40, 40, 255),
    white = tocolor(255, 255, 255, 255),
    progressBg = tocolor(40, 40, 40, 255),
    progressFill = tocolor(16, 89, 138, 255),
    highlight = tocolor(16, 89, 138, 255)
}

-- Language system variables
local tlanguages = nil
local currslot = nil
local hoveredButton = nil
local languageButtons = {}
local closeButton = {}

function drawLanguageGUI()
    local now = getTickCount()
    local elapsedTime = now - lastTick
    lastTick = now
    
    -- Animation logic
    local oldProgress = animProgress
    if targetProgress > animProgress then
        animProgress = math.min(targetProgress, animProgress + fadeSpeed * elapsedTime)
    elseif targetProgress < animProgress then
        animProgress = math.max(targetProgress, animProgress - fadeSpeed * elapsedTime)
    end
    
    if oldProgress == 0 and animProgress > 0 then
        addEventHandler("onClientClick", root, handleClick)
    elseif animProgress == 0 and oldProgress > 0 then
        removeEventHandler("onClientClick", root, handleClick)
        isOpen = false
        return
    end
    
    -- More compact window size
    local windowWidth = 550 * animProgress
    local windowHeight = 300 * animProgress
    local windowX = screenW/2 - windowWidth/2
    local windowY = screenH/2 - windowHeight/2
    
    -- Draw the background
    dxDrawRectangle(windowX, windowY, windowWidth, windowHeight, colors.background)
    
    -- Draw the header - smaller height
    dxDrawRectangle(windowX, windowY, windowWidth, 35 * animProgress, colors.header)
    dxDrawText("Languages: " .. string.gsub(getPlayerName(localPlayer), "_", " "), 
        windowX + 15, 
        windowY, 
        windowX + windowWidth, 
        windowY + 35 * animProgress, 
        colors.white, 
        0.9 * animProgress, 
        fonts.bold, 
        "left", 
        "center")
    
    -- Reset button array
    languageButtons = {}
    
    -- Draw language options
    if tlanguages and animProgress > 0.9 then
        local offset = 55 -- Start closer to header
        
        for i = 1, 3 do
            local L = tlanguages[i]
            if L then
                local lang, skill = unpack(L)
                
                -- Draw language section background - reduced height
                local sectionY = windowY + offset
                local sectionHeight = 65 -- Reduced from 90
                local isHovered = hoveredButton == "lang_use_"..i or hoveredButton == "lang_unlearn_"..i
                local bgColor = isHovered and colors.buttonHover or colors.buttonNormal
                
                dxDrawRectangle(windowX + 15, sectionY, windowWidth - 30, sectionHeight, bgColor)
                
                -- Draw flag icon (placeholder) - smaller
                local flagPath = ":social/images/flags/" .. (flags[lang] or 'zz') .. ".png"
                if fileExists(flagPath) then
                    dxDrawImage(windowX + 25, sectionY + 12, 18, 18, flagPath)
                else
                    dxDrawRectangle(windowX + 25, sectionY + 12, 18, 18, colors.highlight)
                end
                
                -- Draw language name - smaller font
                local langName = getLanguageName(lang)
                if currslot == i then
                    langName = langName .. " (Current)"
                end
                dxDrawText(langName, 
                    windowX + 50, 
                    sectionY + 12, 
                    windowX + windowWidth - 80, 
                    sectionY + 30, 
                    colors.white, 
                    0.9, 
                    fonts.bold, 
                    "left", 
                    "center")
                
                -- Draw progress bar - smaller and thinner
                if languages[lang] then
                    -- Background
                    dxDrawRectangle(windowX + 50, sectionY + 35, windowWidth - 200, 14, colors.progressBg)
                    -- Fill
                    dxDrawRectangle(windowX + 50, sectionY + 35, (windowWidth - 200) * (skill/100), 14, colors.progressFill)
                    -- Percentage text - smaller font
                    dxDrawText(skill .. "/100", 
                        windowX + 50, 
                        sectionY + 35, 
                        windowX + windowWidth - 150, 
                        sectionY + 49, 
                        colors.white, 
                        0.8, 
                        fonts.regular, 
                        "right", 
                        "center")
                    
                    -- Draw use button - smaller
                    if currslot ~= i then
                        local useButtonX = windowX + windowWidth - 130
                        local useButtonY = sectionY + 12
                        local useButtonW = 80
                        local useButtonH = 20
                        
                        local useHovered = (hoveredButton == "lang_use_"..i)
                        local useButtonColor = useHovered and colors.highlight or colors.buttonNormal
                        
                        dxDrawRectangle(useButtonX, useButtonY, useButtonW, useButtonH, useButtonColor)
                        dxDrawText("Use", 
                            useButtonX, 
                            useButtonY, 
                            useButtonX + useButtonW, 
                            useButtonY + useButtonH, 
                            colors.white, 
                            0.8, 
                            fonts.regular, 
                            "center", 
                            "center")
                        
                        -- Store button data for click handling
                        languageButtons["lang_use_"..i] = {useButtonX, useButtonY, useButtonW, useButtonH, lang}
                    end
                end
                
                -- Draw unlearn button - smaller
                if currslot ~= i then
                    local unlearnButtonX = windowX + windowWidth - 130
                    local unlearnButtonY = sectionY + 36
                    local unlearnButtonW = 80
                    local unlearnButtonH = 20
                    
                    local unlearnHovered = (hoveredButton == "lang_unlearn_"..i)
                    local unlearnButtonColor = unlearnHovered and colors.highlight or colors.buttonNormal
                    
                    dxDrawRectangle(unlearnButtonX, unlearnButtonY, unlearnButtonW, unlearnButtonH, unlearnButtonColor)
                    dxDrawText("Un-learn", 
                        unlearnButtonX, 
                        unlearnButtonY, 
                        unlearnButtonX + unlearnButtonW, 
                        unlearnButtonY + unlearnButtonH, 
                        colors.white, 
                        0.8, 
                        fonts.regular, 
                        "center", 
                        "center")
                    
                    -- Store button data for click handling
                    languageButtons["lang_unlearn_"..i] = {unlearnButtonX, unlearnButtonY, unlearnButtonW, unlearnButtonH, lang}
                end
                
                offset = offset + 75 -- Reduced spacing between sections
            end
        end
        
        -- Draw close button - smaller
        local closeButtonX = windowX + 15
        local closeButtonY = windowY + windowHeight - 45
        local closeButtonW = windowWidth - 30
        local closeButtonH = 30
        
        local closeHovered = (hoveredButton == "close")
        local closeButtonColor = closeHovered and colors.highlight or colors.buttonNormal
        
        dxDrawRectangle(closeButtonX, closeButtonY, closeButtonW, closeButtonH, closeButtonColor)
        dxDrawText("Close", 
            closeButtonX, 
            closeButtonY, 
            closeButtonX + closeButtonW, 
            closeButtonY + closeButtonH, 
            colors.white, 
            0.9, 
            fonts.regular, 
            "center", 
            "center")
        
        -- Store close button data
        closeButton = {closeButtonX, closeButtonY, closeButtonW, closeButtonH}
    end
end

-- Confirmation window variables
local wConfirmUnlearn = nil
local confirmAnimProgress = 0
local confirmTargetProgress = 0
local confirmLang = nil
local confirmButtons = {}

function drawConfirmWindow()
    local now = getTickCount()
    local elapsedTime = now - confirmLastTick
    confirmLastTick = now
    
    -- Animation logic - USING FASTER ANIMATION SPEED with separate lastTick
    local oldProgress = confirmAnimProgress
    if confirmTargetProgress > confirmAnimProgress then
        confirmAnimProgress = math.min(confirmTargetProgress, confirmAnimProgress + confirmFadeSpeed * elapsedTime)
    elseif confirmTargetProgress < confirmAnimProgress then
        confirmAnimProgress = math.max(confirmTargetProgress, confirmAnimProgress - confirmFadeSpeed * elapsedTime)
    end
    
    if oldProgress == 0 and confirmAnimProgress > 0 then
        addEventHandler("onClientClick", root, handleConfirmClick)
    elseif confirmAnimProgress == 0 and oldProgress > 0 then
        removeEventHandler("onClientClick", root, handleConfirmClick)
        wConfirmUnlearn = nil
        confirmLang = nil
        return
    end
    
    -- Smaller confirmation window with smoother animation
    local windowWidth = 350 * confirmAnimProgress
    local windowHeight = 120 * confirmAnimProgress
    local windowX = screenW/2 - windowWidth/2
    local windowY = screenH/2 - windowHeight/2
    
    -- Draw the background
    dxDrawRectangle(windowX, windowY, windowWidth, windowHeight, colors.background)
    
    -- Draw the header - smaller
    dxDrawRectangle(windowX, windowY, windowWidth, 30 * confirmAnimProgress, colors.header)
    dxDrawText("Confirmation", 
        windowX, 
        windowY, 
        windowX + windowWidth, 
        windowY + 30 * confirmAnimProgress, 
        colors.white, 
        0.9 * confirmAnimProgress, 
        fonts.bold, 
        "center", 
        "center")
    
    -- Draw question
    if confirmAnimProgress > 0.9 and confirmLang then
        dxDrawText("Do you really want to forget all your knowledge of " .. getLanguageName(confirmLang) .. "?", 
            windowX + 15, 
            windowY + 40, 
            windowX + windowWidth - 15, 
            windowY + 70, 
            colors.white, 
            0.8, 
            fonts.regular, 
            "center", 
            "center",
            true, false)
        
        -- Draw Yes button - smaller
        local yesButtonX = windowX + 25
        local yesButtonY = windowY + 80
        local yesButtonW = 80
        local yesButtonH = 25
        
        local yesHovered = (hoveredButton == "confirm_yes")
        local yesButtonColor = yesHovered and colors.highlight or colors.buttonNormal
        
        dxDrawRectangle(yesButtonX, yesButtonY, yesButtonW, yesButtonH, yesButtonColor)
        dxDrawText("Yes", 
            yesButtonX, 
            yesButtonY, 
            yesButtonX + yesButtonW, 
            yesButtonY + yesButtonH, 
            colors.white, 
            0.8, 
            fonts.regular, 
            "center", 
            "center")
        
        -- Store button data
        confirmButtons["confirm_yes"] = {yesButtonX, yesButtonY, yesButtonW, yesButtonH}
        
        -- Draw No button - smaller
        local noButtonX = windowX + windowWidth - 105
        local noButtonY = windowY + 80
        local noButtonW = 80
        local noButtonH = 25
        
        local noHovered = (hoveredButton == "confirm_no")
        local noButtonColor = noHovered and colors.highlight or colors.buttonNormal
        
        dxDrawRectangle(noButtonX, noButtonY, noButtonW, noButtonH, noButtonColor)
        dxDrawText("No", 
            noButtonX, 
            noButtonY, 
            noButtonX + noButtonW, 
            noButtonY + noButtonH, 
            colors.white, 
            0.8, 
            fonts.regular, 
            "center", 
            "center")
        
        -- Store button data
        confirmButtons["confirm_no"] = {noButtonX, noButtonY, noButtonW, noButtonH}
    end
end

-- Skill increase notification - smaller font and faster animation
function renderSkillIncrease()
    local now = getTickCount()
    local toRemove = {}
    
    for i, data in ipairs(skillInc) do
        local elapsed = now - data.tick
        local alpha = 255 - (elapsed / 15) -- Faster fade
        local y = data.y - (elapsed / 40) -- Slower rise
        
        if alpha > 0 then
            dxDrawText(data.text, data.x, y, data.x, y, tocolor(255, 255, 255, alpha), 0.8, fonts.bold, "center", "center")
        else
            table.insert(toRemove, i)
        end
    end
    
    -- Remove expired notifications
    for i = #toRemove, 1, -1 do
        table.remove(skillInc, toRemove[i])
    end
    
    if #skillInc == 0 then
        removeEventHandler("onClientRender", root, renderSkillIncrease)
    end
end

function handleClick(button, state)
    if button ~= "left" or state ~= "down" then return end
    
    -- Handle language buttons
    for id, data in pairs(languageButtons) do
        local x, y, width, height, lang = unpack(data)
        if isMouseInPosition(x, y, width, height) then
            if string.find(id, "use") then
                triggerServerEvent("useLanguage", localPlayer, lang)
                hideLanguageGUI()
                return
            elseif string.find(id, "unlearn") then
                unlearnLanguage(lang)
                return
            end
        end
    end
    
    -- Handle close button
    if closeButton and #closeButton > 0 then
        local x, y, width, height = unpack(closeButton)
        if isMouseInPosition(x, y, width, height) then
            hideLanguageGUI()
            return
        end
    end
end

function handleMouseMovement()
    if not isOpen then return end
    
    hoveredButton = nil
    
    -- Check language buttons
    for id, data in pairs(languageButtons) do
        local x, y, width, height = unpack(data)
        if isMouseInPosition(x, y, width, height) then
            hoveredButton = id
            return
        end
    end
    
    -- Check close button
    if closeButton and #closeButton > 0 then
        local x, y, width, height = unpack(closeButton)
        if isMouseInPosition(x, y, width, height) then
            hoveredButton = "close"
            return
        end
    end
end

function handleConfirmClick(button, state)
    if button ~= "left" or state ~= "down" then return end
    
    -- Check confirm buttons
    for id, data in pairs(confirmButtons) do
        local x, y, width, height = unpack(data)
        if isMouseInPosition(x, y, width, height) then
            if id == "confirm_yes" and confirmLang then
                triggerServerEvent("unlearnLanguage", localPlayer, confirmLang)
                -- Hide both confirmation window AND main GUI
                hideConfirmWindow()
                hideLanguageGUI()
                return
            elseif id == "confirm_no" then
                hideConfirmWindow()
                return
            end
        end
    end
end

function handleConfirmMouseMovement()
    if not wConfirmUnlearn then return end
    
    hoveredButton = nil
    
    -- Check confirm buttons
    for id, data in pairs(confirmButtons) do
        local x, y, width, height = unpack(data)
        if isMouseInPosition(x, y, width, height) then
            hoveredButton = id
            return
        end
    end
end

function isMouseInPosition(x, y, width, height)
    if not isCursorShowing() then return false end
    
    local mouseX, mouseY = getCursorPosition()
    mouseX, mouseY = mouseX * screenW, mouseY * screenH
    
    return (mouseX >= x and mouseX <= x + width and mouseY >= y and mouseY <= y + height)
end

function displayGUI(remotelanguages, rcurrslot)
    local logged = getElementData(getLocalPlayer(), "loggedin")
    if (logged ~= 1) then return end
    
    if not isOpen then
        tlanguages = remotelanguages
        currslot = tonumber(rcurrslot)
        
        showCursor(true)
        targetProgress = 1
        isOpen = true
        
        if not isEventHandlerAdded("onClientRender", root, drawLanguageGUI) then
            addEventHandler("onClientRender", root, drawLanguageGUI)
        end
        
        if not isEventHandlerAdded("onClientCursorMove", root, handleMouseMovement) then
            addEventHandler("onClientCursorMove", root, handleMouseMovement)
        end
    else
        hideLanguageGUI()
    end
end
addEvent("showLanguages", true)
addEventHandler("showLanguages", getLocalPlayer(), displayGUI)

function unlearnLanguage(lang)
    if lang > 0 then
        if not languages[lang] then
            hideLanguageGUI()
            triggerServerEvent("unlearnLanguage", localPlayer, lang)
        else
            showConfirmWindow(lang)
        end
    end
end

function showConfirmWindow(lang)
    confirmLang = lang
    wConfirmUnlearn = true
    confirmTargetProgress = 1
    confirmButtons = {}
    confirmLastTick = getTickCount() -- Reset the confirm animation timer
    
    if not isEventHandlerAdded("onClientRender", root, drawConfirmWindow) then
        addEventHandler("onClientRender", root, drawConfirmWindow)
    end
    
    if not isEventHandlerAdded("onClientCursorMove", root, handleConfirmMouseMovement) then
        addEventHandler("onClientCursorMove", root, handleConfirmMouseMovement)
    end
end

function hideConfirmWindow()
    confirmTargetProgress = 0
    confirmButtons = {}
end -- Fixed the missing "end" here

function hideLanguageGUI()
    targetProgress = 0
    confirmTargetProgress = 0 -- Also make sure confirmation window is hidden
    showCursor(false)
end

-- Utility function to check if event handler is already added
function isEventHandlerAdded(eventName, attachedTo, functionToCall)
    if type(eventName) == "string" and isElement(attachedTo) and type(functionToCall) == "function" then
        local attachedFunctions = getEventHandlers(eventName, attachedTo)
        if type(attachedFunctions) == "table" and #attachedFunctions > 0 then
            for i, v in ipairs(attachedFunctions) do
                if v == functionToCall then
                    return true
                end
            end
        end
    end
    return false
end