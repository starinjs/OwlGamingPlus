-- Config
local config = {
    colors = {
        primary = tocolor(22, 101, 151, 255), -- Main theme color
        secondary = tocolor(32, 32, 32, 230), -- Background color
        highlight = tocolor(41, 128, 185, 255), -- Hover/selected color
        text = tocolor(255, 255, 255, 255), -- Main text color
        textDark = tocolor(200, 200, 200, 255), -- Secondary text color
        border = tocolor(60, 60, 60, 255), -- Border color
        shadow = tocolor(0, 0, 0, 100), -- Shadow color
        transparent = tocolor(0, 0, 0, 0) -- Fully transparent
    },
    fonts = {
        title = dxCreateFont(":resources/fonts/Roboto-Bold.ttf", 16) or "default-bold",
        normal = dxCreateFont(":resources/fonts/Roboto-Regular.ttf", 12) or "default",
        small = dxCreateFont(":resources/fonts/Roboto-Light.ttf", 10) or "default",
        icons = dxCreateFont(":resources/fonts/FontAwesome.otf", 14) or "default-bold"
    },
    animation = {
        speed = 8, -- Animation speed (lower = slower)
        current = 0, -- Current animation progress
        target = 0, -- Target animation progress
        state = false -- Menu state
    },
    icons = {
        character = "#", -- Change character
        stats = "S", -- Character statistics
        settings = "S", -- Settings
        premium = "P", -- Premium features
        staff = "S", -- Staff manager
        faction = "F", -- Faction manager
        interior = "I", -- Interior manager
        vehicle = "V", -- Vehicle manager
        vehicleLib = "L", -- Vehicle library
        applications = "A", -- Application manager
        radio = "R", -- Radio station manager
        motd = "M", -- MOTD manager
        maps = "M", -- Map manager
        logout = "#", -- Logout
        close = "#" -- Close
    }
}

-- Variables
local screenWidth, screenHeight = guiGetScreenSize()
local menuWidth = 450 -- Increased from 300 to 400
local menuHeight = 500
local menuX = (screenWidth - menuWidth) / 2
local menuY = (screenHeight - menuHeight) / 2
local buttonHeight = 40
local menuButtons = {}
local isMenuVisible = false
local activeSubmenu = nil
local hoveredButton = nil
local currentPage = 1
local itemsPerPage = 9
local maxPages = 1

-- Font cache to avoid recreating fonts
local fontCache = {}

-- Function to get a font or create it if it doesn't exist
local function getFont(size, bold)
    local key = size .. (bold and "b" or "")
    if not fontCache[key] then
        fontCache[key] = bold and dxCreateFont("fonts/Roboto-Bold.ttf", size) or dxCreateFont("fonts/Roboto-Regular.ttf", size)
        if not fontCache[key] then
            fontCache[key] = bold and "default-bold" or "default"
        end
    end
    return fontCache[key]
end

-- Settings menu variables
local settingsCategories = {
    "Graphics",
    "Interface",
    "Audio",
    "Chat",
    "Overlay"
}
local activeSettingsCategory = 1
local settingsOptions = {
    Graphics = {
        {name = "Motion Blur", type = "checkbox", setting = "motionblur", value = tonumber(loadSavedData("motionblur", "1")) == 1},
        {name = "Sky Clouds", type = "checkbox", setting = "skyclouds", value = tonumber(loadSavedData("skyclouds", "1")) == 1},
        {name = "Radar Shader", type = "checkbox", setting = "enable_radar_shader", value = tonumber(loadSavedData("enable_radar_shader", "1")) == 1},
        {name = "Water Shader", type = "checkbox", setting = "enable_water_shader", value = tonumber(loadSavedData("enable_water_shader", "1")) == 1},
        {name = "Vehicle Shader", type = "checkbox", setting = "enable_vehicle_shader", value = tonumber(loadSavedData("enable_vehicle_shader", "1")) == 1}
    },
    Interface = {
        {name = "Show Nametags", type = "checkbox", setting = "shownametags", value = tonumber(loadSavedData("shownametags", "1")) == 1}
    },
    Audio = {
        {name = "Streaming Audio", type = "checkbox", setting = "streamingmedia", value = tonumber(loadSavedData("streamingmedia", "1")) == 1}
    },
    Chat = {
        {name = "Chat Bubbles", type = "checkbox", setting = "chatbubbles", value = tonumber(loadSavedData("chatbubbles", "1")) == 1},
        {name = "Typing Icons", type = "checkbox", setting = "chaticons", value = tonumber(loadSavedData("chaticons", "1")) == 1},
        {name = "Chat Logging", type = "checkbox", setting = "logsenabled", value = tonumber(loadSavedData("logsenabled", "1")) == 1}
    },
    Overlay = {
        {name = "Enable All Overlays", type = "checkbox", setting = "enableOverlayDescription", value = tonumber(loadSavedData("enableOverlayDescription", "1")) == 1},
        {name = "Vehicle Overlays", type = "checkbox", setting = "enableOverlayDescriptionVeh", value = tonumber(loadSavedData("enableOverlayDescriptionVeh", "1")) == 1},
        {name = "Pin Vehicle Overlays", type = "checkbox", setting = "enableOverlayDescriptionVehPin", value = tonumber(loadSavedData("enableOverlayDescriptionVehPin", "1")) == 1},
        {name = "Property Overlays", type = "checkbox", setting = "enableOverlayDescriptionPro", value = tonumber(loadSavedData("enableOverlayDescriptionPro", "1")) == 1},
        {name = "Pin Property Overlays", type = "checkbox", setting = "enableOverlayDescriptionProPin", value = tonumber(loadSavedData("enableOverlayDescriptionProPin", "1")) == 1}
    }
}

-- Initialize the button list
local function initializeMenuButtons()
    menuButtons = {
        {text = "Change Character", icon = config.icons.character, action = function() options_logOut() end},
        {text = "Character Statistics", icon = config.icons.stats, action = function() triggerServerEvent("showStats", localPlayer, localPlayer); toggleOptionsMenu() end},
        {text = "Settings", icon = config.icons.settings, action = function() activeSubmenu = "settings" end},
    }
    
    -- Add conditional buttons based on player access
    if getResourceFromName("donators") then
        table.insert(menuButtons, {text = "Premium Features", icon = config.icons.premium, action = function() triggerServerEvent("donation-system:GUI:open", localPlayer); toggleOptionsMenu() end})
    end
    
    if getResourceFromName("admin-system") and exports['admin-system']:canPlayerAccessStaffManager(localPlayer) then
        table.insert(menuButtons, {text = "Staff Manager", icon = config.icons.staff, action = function() executeCommandHandler("staffs"); toggleOptionsMenu() end})
    end
    
    if getResourceFromName("factions") and exports.factions:canAccessFactionManager(localPlayer) then
        table.insert(menuButtons, {text = "Faction Manager", icon = config.icons.faction, action = function() executeCommandHandler("factions"); toggleOptionsMenu() end})
    end
    
    if getResourceFromName("interior_system") and getResourceFromName("interior-manager") and exports.integration:isPlayerAdmin(localPlayer) then
        table.insert(menuButtons, {text = "Interior Manager", icon = config.icons.interior, action = function() triggerServerEvent("interiorManager:openit", localPlayer, localPlayer); toggleOptionsMenu() end})
    end
    
    if getResourceFromName("vehicle") and getResourceFromName("vehicle_manager") and exports.vehicle_manager:canAccessVehicleManager(localPlayer) then
        table.insert(menuButtons, {text = "Vehicle Manager", icon = config.icons.vehicle, action = function() executeCommandHandler("vehs"); toggleOptionsMenu() end})
    end
    
    if getResourceFromName('vehicle') and getResourceFromName("vehicle_manager") then
        local thePlayer = localPlayer
        if exports.integration:isPlayerVCTMember(thePlayer) or exports.integration:isPlayerSupporter(thePlayer) or 
           exports.integration:isPlayerTrialAdmin(thePlayer) or exports.integration:isPlayerScripter(thePlayer) or 
           exports.integration:isPlayerVehicleConsultant(thePlayer) then
            table.insert(menuButtons, {text = "Vehicle Library", icon = config.icons.vehicleLib, action = function() triggerServerEvent("vehlib:sendLibraryToClient", localPlayer, localPlayer); toggleOptionsMenu() end})
        end
    end
    
    if getResourceFromName("apps") and (exports.integration:isPlayerTrialAdmin(localPlayer) or exports.integration:isPlayerSupporter(localPlayer)) then
        table.insert(menuButtons, {text = "Application Manager", icon = config.icons.applications, action = function() executeCommandHandler("apps"); toggleOptionsMenu() end})
    end
    
    if getResourceFromName("carradio") then
        table.insert(menuButtons, {text = "Radio Station Manager", icon = config.icons.radio, action = function() executeCommandHandler("radios"); toggleOptionsMenu() end})
    end
    
    if getResourceFromName("announcement") and exports.announcement:canPlayerAccessMotdManager(localPlayer) then
        table.insert(menuButtons, {text = "MOTD Manager", icon = config.icons.motd, action = function() executeCommandHandler("motd"); toggleOptionsMenu() end})
    end
    
    if getResourceFromName("map_manager") then
        table.insert(menuButtons, {text = "Map Manager", icon = config.icons.maps, action = function() executeCommandHandler("maps"); toggleOptionsMenu() end})
    end
    
    -- Add these buttons for everyone
    table.insert(menuButtons, {text = "Logout", icon = config.icons.logout, action = function() 
        fadeCamera(false, 2, 0, 0, 0)
        setTimer(function() triggerServerEvent("accounts:settings:reconnectPlayer", localPlayer) end, 2000, 1)
        toggleOptionsMenu()
    end})
    
    table.insert(menuButtons, {text = "Close", icon = config.icons.close, action = function() toggleOptionsMenu() end})
    
    -- Calculate max pages
    maxPages = math.ceil(#menuButtons / itemsPerPage)
end

-- Function to toggle the menu
function toggleOptionsMenu()
    if not isMenuVisible and getElementData(localPlayer, "exclusiveGUI") or not isCameraOnPlayer() then
        return
    end
    
    isMenuVisible = not isMenuVisible
    
    if isMenuVisible then
        initializeMenuButtons()
        setElementData(localPlayer, "exclusiveGUI", true, false)
        triggerEvent("hud:blur", resourceRoot, 6, false, 0.5, nil)
        config.animation.target = 1
        showCursor(true)
        addEventHandler("onClientRender", root, renderOptionsMenu)
        addEventHandler("onClientClick", root, handleMenuClick)
    else
        config.animation.target = 0
        setElementData(localPlayer, "exclusiveGUI", false, false)
        triggerEvent("hud:blur", resourceRoot, "off")
        showCursor(false)
        activeSubmenu = nil
        
        -- Remove event handlers after animation completes
        setTimer(function()
            if config.animation.current <= 0.05 then
                removeEventHandler("onClientRender", root, renderOptionsMenu)
                removeEventHandler("onClientClick", root, handleMenuClick)
            end
        end, 300, 1)
    end
end

-- Function to get position with animation
local function getAnimatedPosition(x, y, width, height)
    local progress = config.animation.current
    local centerX = screenWidth / 2
    local centerY = screenHeight / 2
    
    local newWidth = width * progress
    local newHeight = height * progress
    local newX = centerX - (newWidth / 2)
    local newY = centerY - (newHeight / 2)
    
    return newX, newY, newWidth, newHeight, progress
end

-- Function to render rounded rectangle
local function dxDrawRoundedRectangle(x, y, width, height, radius, color, postGUI)
    dxDrawRectangle(x + radius, y, width - (radius * 2), height, color, postGUI)
    dxDrawRectangle(x, y + radius, width, height - (radius * 2), color, postGUI)
    
    dxDrawCircle(x + radius, y + radius, radius, 180, 270, color, color, 16, 1, postGUI)
    dxDrawCircle(x + width - radius, y + radius, radius, 270, 360, color, color, 16, 1, postGUI)
    dxDrawCircle(x + radius, y + height - radius, radius, 90, 180, color, color, 16, 1, postGUI)
    dxDrawCircle(x + width - radius, y + height - radius, radius, 0, 90, color, color, 16, 1, postGUI)
end

-- Function to draw a button
local function drawButton(x, y, width, height, text, icon, isHovered, isActive)
    local buttonColor = isActive and config.colors.highlight or (isHovered and tocolor(50, 50, 50, 230) or config.colors.secondary)
    
    -- Draw button background with subtle animation for hover
    dxDrawRoundedRectangle(x, y, width, height, 5, buttonColor, true)
    
    -- Draw icon using text from FontAwesome (now using letter indicators instead of emojis)
    if icon then
        -- Draw circle background for the icon
        local iconSize = 25
        local iconX = x + 20
        local iconY = y + (height/2) - (iconSize/2)
        dxDrawRectangle(iconX - 2, iconY - 2, iconSize + 4, iconSize + 4, tocolor(60, 60, 60, 200), true)
        dxDrawText(icon, iconX, iconY, iconX + iconSize, iconY + iconSize, config.colors.text, 1, config.fonts.title, "center", "center", false, false, true)
    end
    
    -- Draw text with more space for wider menu
    dxDrawText(text, x + 60, y, x + width - 15, y + height, config.colors.text, 1, config.fonts.normal, "left", "center", true, false, true)
    
    -- Draw subtle line at bottom of button for separation
    dxDrawRectangle(x + 10, y + height - 1, width - 20, 1, tocolor(80, 80, 80, 100), true)
    
    return isHovered
end

-- Function to draw a checkbox
local function drawCheckbox(x, y, width, height, text, checked, isHovered)
    local checkboxSize = 20
    local checkboxX = x + width - checkboxSize - 15
    local checkboxY = y + (height - checkboxSize) / 2
    
    -- Draw text (with more space for the wider menu)
    dxDrawText(text, x + 15, y, x + width - checkboxSize - 25, y + height, config.colors.text, 1, config.fonts.normal, "left", "center", true, false, true)
    
    -- Draw checkbox background
    local checkboxColor = isHovered and tocolor(60, 60, 60, 255) or tocolor(40, 40, 40, 255)
    dxDrawRoundedRectangle(checkboxX, checkboxY, checkboxSize, checkboxSize, 3, checkboxColor, true)
    
    -- Draw checkbox border
    local borderColor = isHovered and config.colors.highlight or config.colors.border
    dxDrawRectangle(checkboxX, checkboxY, checkboxSize, 1, borderColor, true) -- Top
    dxDrawRectangle(checkboxX, checkboxY + checkboxSize - 1, checkboxSize, 1, borderColor, true) -- Bottom
    dxDrawRectangle(checkboxX, checkboxY, 1, checkboxSize, borderColor, true) -- Left
    dxDrawRectangle(checkboxX + checkboxSize - 1, checkboxY, 1, checkboxSize, borderColor, true) -- Right
    
    -- Draw checkmark if checked
    if checked then
        local inset = 4
        dxDrawRectangle(checkboxX + inset, checkboxY + inset, checkboxSize - (inset * 2), checkboxSize - (inset * 2), config.colors.highlight, true)
    end
    
    return isHovered
end

-- Function to render the options menu
function renderOptionsMenu()
    -- Update animation
    if config.animation.current < config.animation.target then
        config.animation.current = math.min(config.animation.current + 0.05 * config.animation.speed * (1 - config.animation.current), config.animation.target)
    elseif config.animation.current > config.animation.target then
        config.animation.current = math.max(config.animation.current - 0.05 * config.animation.speed, config.animation.target)
    end
    
    -- If animation is complete and target is 0, stop rendering
    if config.animation.current <= 0.05 and config.animation.target == 0 then
        return
    end
    
    -- Get animated position and size
    local x, y, width, height, alpha = getAnimatedPosition(menuX, menuY, menuWidth, menuHeight)
    
    -- Don't render if too small
    if width < 30 or height < 30 then return end
    
    -- Calculate current mouse position for hover effects
    local mouseX, mouseY = getCursorPosition()
    if mouseX then
        mouseX, mouseY = mouseX * screenWidth, mouseY * screenHeight
    else
        mouseX, mouseY = -1, -1
    end
    
    hoveredButton = nil
    
    -- Draw main menu background
    dxDrawRoundedRectangle(x, y, width, height, 10, config.colors.secondary, true)
    
    -- Draw header
    dxDrawRoundedRectangle(x, y, width, 50, 10, config.colors.primary, true)
    dxDrawRectangle(x, y + 40, width, 10, config.colors.primary, true)
    dxDrawText("Game Options", x, y, x + width, y + 50, config.colors.text, 1, config.fonts.title, "center", "center", true, false, true)
    
    -- Draw content based on current submenu
    if activeSubmenu == "settings" then
        renderSettingsMenu(x, y, width, height, mouseX, mouseY)
    else
        renderMainMenu(x, y, width, height, mouseX, mouseY)
    end
end

-- Function to render the main menu
function renderMainMenu(x, y, width, height, mouseX, mouseY)
    -- Calculate button dimensions
    local buttonWidth = width - 20
    local buttonX = x + 10
    local contentStartY = y + 60
    local contentHeight = height - 90
    
    -- Draw page navigation if needed
    if maxPages > 1 then
        -- Draw page indicator
        local pageText = "Page " .. currentPage .. "/" .. maxPages
        dxDrawText(pageText, x, y + height - 45, x + width, y + height - 25, config.colors.textDark, 1, config.fonts.small, "center", "center", true, false, true)
        
        -- Draw prev/next buttons
        local navButtonWidth = 30
        local navButtonHeight = 30
        local prevX = x + 10
        local nextX = x + width - navButtonWidth - 10
        local navY = y + height - 45
        
        -- Previous button
        if currentPage > 1 then
            local isHovered = (mouseX >= prevX and mouseX <= prevX + navButtonWidth and mouseY >= navY and mouseY <= navY + navButtonHeight)
            local buttonColor = isHovered and config.colors.highlight or config.colors.primary
            dxDrawRoundedRectangle(prevX, navY, navButtonWidth, navButtonHeight, 5, buttonColor, true)
            dxDrawText("<", prevX, navY, prevX + navButtonWidth, navY + navButtonHeight, config.colors.text, 1, config.fonts.normal, "center", "center", false, false, true)
            
            if isHovered then
                hoveredButton = {action = "prevPage"}
            end
        end
        
        -- Next button
        if currentPage < maxPages then
            local isHovered = (mouseX >= nextX and mouseX <= nextX + navButtonWidth and mouseY >= navY and mouseY <= navY + navButtonHeight)
            local buttonColor = isHovered and config.colors.highlight or config.colors.primary
            dxDrawRoundedRectangle(nextX, navY, navButtonWidth, navButtonHeight, 5, buttonColor, true)
            dxDrawText(">", nextX, navY, nextX + navButtonWidth, navY + navButtonHeight, config.colors.text, 1, config.fonts.normal, "center", "center", false, false, true)
            
            if isHovered then
                hoveredButton = {action = "nextPage"}
            end
        end
    end
    
    -- Calculate start and end indices for current page
    local startIndex = (currentPage - 1) * itemsPerPage + 1
    local endIndex = math.min(startIndex + itemsPerPage - 1, #menuButtons)
    
    -- Draw buttons
    for i = startIndex, endIndex do
        local button = menuButtons[i]
        local buttonIndex = i - startIndex
        local buttonY = contentStartY + (buttonIndex * buttonHeight)
        
        -- Check if mouse is hovering over button
        local isHovered = (mouseX >= buttonX and mouseX <= buttonX + buttonWidth and 
                          mouseY >= buttonY and mouseY <= buttonY + buttonHeight)
        
        drawButton(buttonX, buttonY, buttonWidth, buttonHeight, button.text, button.icon, isHovered)
        
        if isHovered then
            hoveredButton = button
        end
    end
end

-- Function to render the settings menu
function renderSettingsMenu(x, y, width, height, mouseX, mouseY)
    local categoryHeight = 40
    local categoryWidth = width / #settingsCategories
    local contentStartY = y + 60
    
    -- Draw category tabs
    for i, category in ipairs(settingsCategories) do
        local categoryX = x + (i-1) * categoryWidth
        local isActive = (i == activeSettingsCategory)
        local isHovered = (mouseX >= categoryX and mouseX <= categoryX + categoryWidth and 
                          mouseY >= contentStartY and mouseY <= contentStartY + categoryHeight)
        
        local bgColor = isActive and config.colors.highlight or (isHovered and tocolor(50, 50, 50, 230) or config.colors.secondary)
        dxDrawRectangle(categoryX, contentStartY, categoryWidth, categoryHeight, bgColor, true)
        dxDrawText(category, categoryX, contentStartY, categoryX + categoryWidth, contentStartY + categoryHeight, config.colors.text, 1, isActive and config.fonts.title or config.fonts.normal, "center", "center", true, false, true)
        
        if isHovered then
            hoveredButton = {action = "settingsCategory", category = i}
        end
    end
    
    -- Draw settings for active category
    local settingsStartY = contentStartY + categoryHeight + 10
    local currentCategory = settingsCategories[activeSettingsCategory]
    local options = settingsOptions[currentCategory]
    
    for i, option in ipairs(options) do
        local optionY = settingsStartY + (i-1) * buttonHeight
        
        if option.type == "checkbox" then
            local isHovered = (mouseX >= x + 10 and mouseX <= x + width - 10 and 
                              mouseY >= optionY and mouseY <= optionY + buttonHeight)
            
            drawCheckbox(x + 10, optionY, width - 20, buttonHeight, option.name, option.value, isHovered)
            
            if isHovered then
                hoveredButton = {action = "settingsToggle", category = currentCategory, option = i}
            end
        end
    end
    
    -- Draw back button
    local backBtnY = y + height - buttonHeight - 10
    local isHovered = (mouseX >= x + 10 and mouseX <= x + width - 10 and 
                      mouseY >= backBtnY and mouseY <= backBtnY + buttonHeight)
    
    drawButton(x + 10, backBtnY, width - 20, buttonHeight, "Back to Menu", "<", isHovered)
    
    if isHovered then
        hoveredButton = {action = "settingsBack"}
    end
end

-- Function to handle menu clicks
function handleMenuClick(button, state)
    if button == "left" and state == "down" and hoveredButton then
        playClickSound()
        
        if hoveredButton.action == "prevPage" then
            if currentPage > 1 then
                currentPage = currentPage - 1
            end
        elseif hoveredButton.action == "nextPage" then
            if currentPage < maxPages then
                currentPage = currentPage + 1
            end
        elseif hoveredButton.action == "settingsCategory" then
            activeSettingsCategory = hoveredButton.category
        elseif hoveredButton.action == "settingsToggle" then
            local category = hoveredButton.category
            local optionIndex = hoveredButton.option
            local option = settingsOptions[category][optionIndex]
            
            -- Toggle value
            option.value = not option.value
            
            -- Save setting
            appendSavedData(option.setting, option.value and "1" or "0")
            
            -- Apply setting
            triggerEvent("accounts:settings:loadGraphicSettings", localPlayer)
        elseif hoveredButton.action == "settingsBack" then
            activeSubmenu = nil
        else
            -- Regular button action
            if type(hoveredButton.action) == "function" then
                hoveredButton.action()
            end
        end
    end
end

-- Function to play click sound
function playClickSound()
    playSound("sounds/click.mp3")
end

-- Utility function to save settings
function appendSavedData(setting, value)
    triggerEvent("accounts:settings:update", localPlayer, setting, value)
    return true
end

-- Function to load saved data
function loadSavedData(setting, default)
    return getElementData(localPlayer, setting) or default
end

-- Utility function to check if camera is on player
function isCameraOnPlayer()
    local vehicle = getPedOccupiedVehicle(localPlayer)
    if vehicle then
        return getCameraTarget() == vehicle
    else
        return getCameraTarget() == localPlayer
    end
end

-- Function for logging out
function options_logOut(message)
    toggleOptionsMenu()
    triggerServerEvent("updateCharacters", localPlayer)
    triggerServerEvent("accounts:characters:change", localPlayer, "Change Character")
    triggerEvent("onClientChangeChar", getRootElement())
    options_disable()
    Characters_showSelection()
    clearChat()
    if message then
        LoginScreen_showWarningMessage(message)
    end
end

-- Register events
function options_enable()
    addCommandHandler("home", toggleOptionsMenu)
    bindKey("F10", "down", "home")
end
addEventHandler("accounts:options", getRootElement(), options_enable)

function options_disable()
    removeCommandHandler("home", toggleOptionsMenu)
    unbindKey("home", "down", "home")
    unbindKey("F10", "down", "home")
end