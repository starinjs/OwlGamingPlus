--
-- Enhanced Scoreboard v2.0
-- Client-side script.
-- Based on original by Alberto "ryden" Alonso
-- Modernized design and animations
--

--[[ MAIN CONFIGURATION - Edit these values to customize your scoreboard ]]--
local CONFIG = {
    -- Server Display
    SERVER_NAME                 = nil,               -- Set to override server name (nil = use server data)
    
    -- Dimensions
    WIDTH                       = 500,               -- The scoreboard window width
    HEIGHT                      = 600,               -- The scoreboard window height
    HEADER_HEIGHT               = 50,                -- Height for the header
    ROW_HEIGHT                  = 30,                -- Height for each player row
    ROW_GAP                     = 1,                 -- Gap between rows
    CORNER_RADIUS               = 8,                 -- Radius for rounded corners
    AVATAR_SIZE                 = 24,                -- Size of player avatar icons
    
    -- Controls
    TOGGLE_KEY                  = "tab",             -- Control/Key to toggle the scoreboard visibility
    PGUP_CONTROL                = "mouse_wheel_up",  -- Control/Key to move one page up
    PGDN_CONTROL                = "mouse_wheel_down",-- Control/Key to move one page down
    DISABLED_CONTROLS           = { "next_weapon",   -- Controls that are disabled when the scoreboard is showing
                                    "previous_weapon",
                                    "aim_weapon",
                                    "radio_next",
                                    "radio_previous" },
    
    -- Animation
    TOGGLE_TIME                 = 350,               -- Time in milliseconds for animations
    
    -- Layout
    COLUMNS_WIDTH               = {0.10, 0.45, 0.15, 0.15, 0.15}, -- Column widths: id, name, hours, ping, fps
    POSTGUI                     = true,              -- Draw over the GUI
    
    -- Colors (RGBA format)
    BACKGROUND                  = {0, 0, 0, 200},   -- Background color
    HEADER_COLOR                = {30, 105, 170, 230},-- Header background color
    SERVER_NAME_COLOR           = {255, 255, 255, 255},-- Server name text color
    SERVER_INFO_COLOR           = {220, 220, 220, 255},-- Server info text color
    HEADERS_COLOR               = {200, 200, 200, 255},-- Column headers color
    SEPARATOR_COLOR             = {40, 120, 180, 255},-- Separator lines color
    SCROLL_COLOR                = {40, 120, 180, 180},-- Scroll bar color
    SCROLL_HOVER_COLOR          = {60, 140, 200, 230},-- Scroll bar hover color
    ROW_HIGHLIGHT               = {40, 120, 180, 50},-- Row highlight color
    
    -- Player Colors (for different ranks)
    ADMIN_COLOR                 = {220, 180, 60},    -- Admin name color
    REGULAR_COLOR               = {255, 255, 255},   -- Regular player color
    LOGGED_OUT_COLOR            = {127, 127, 127},   -- Logged out player color
    DONATOR_COLOR               = {167, 133, 63},    -- Donator name color
    OWNER_COLOR                 = {255, 255, 255},   -- Owner name color (admin level 10)
}

--[[ Global variables - Do not modify unless you know what you're doing ]]--
local g_isShowing = false       -- Marks if the scoreboard is showing
local g_animationProgress = 0   -- Animation progress (0-1)
local g_currentWidth = 0        -- Current window width
local g_currentHeight = 0       -- Current window height
local g_scoreboardDummy         -- The scoreboard element
local g_windowSize = {guiGetScreenSize()}    -- Screen size
local g_localPlayer = getLocalPlayer()       -- The local player
local g_currentPage = 0         -- The current scroll page
local g_hoveredRow = -1         -- Currently hovered row
local g_players                 -- Player cache
local g_oldControlStates        -- Old control states
local g_mouseX, g_mouseY = 0, 0 -- Current mouse position
local g_scrollbarHovered = false-- Scrollbar hover state
local g_scrollDragging = false  -- Scrollbar dragging state
local g_lastClickTime = 0       -- For double-click detection
local SCOREBOARD_ALPHA_MULT = 1 -- For fade animations
local g_fpsList = {}            -- To store FPS data for each player

-- Font definitions
local fonts = {
    roboto_bold = nil,
    roboto_regular = nil,
    roboto_light = nil,
    awesome = nil
}

-- Pre-calculate scoreboard position
local SCOREBOARD_X = math.floor((g_windowSize[1] - CONFIG.WIDTH) / 2)
local SCOREBOARD_Y = math.floor((g_windowSize[2] - CONFIG.HEIGHT) / 2)

-- Convert color tables to color values
local function toColorAlpha(color, alpha)
    local a = alpha or color[4] or 255
    return tocolor(color[1], color[2], color[3], a * SCOREBOARD_ALPHA_MULT)
end

-- Pre-calculate colors
local BACKGROUND_COLOR = toColorAlpha(CONFIG.BACKGROUND)
local HEADER_BG_COLOR = toColorAlpha(CONFIG.HEADER_COLOR)
local SERVER_NAME_COLOR = toColorAlpha(CONFIG.SERVER_NAME_COLOR)
local SERVER_INFO_COLOR = toColorAlpha(CONFIG.SERVER_INFO_COLOR)
local HEADERS_COLOR = toColorAlpha(CONFIG.HEADERS_COLOR)
local SEPARATOR_COLOR = toColorAlpha(CONFIG.SEPARATOR_COLOR)
local SCROLL_COLOR = toColorAlpha(CONFIG.SCROLL_COLOR)
local SCROLL_HOVER_COLOR = toColorAlpha(CONFIG.SCROLL_HOVER_COLOR)
local ROW_HIGHLIGHT_COLOR = toColorAlpha(CONFIG.ROW_HIGHLIGHT)

-- Column positions
local columnPositions = {}
local totalWidth = 0

-- FPS counter variables
local frameCounter = 0
local lastFPSUpdate = 0
local currentFPS = 0

-- Function to recalculate column positions
local function calculateColumnPositions()
    local currentX = SCOREBOARD_X
    totalWidth = 0
    for k=1, #CONFIG.COLUMNS_WIDTH do
        local width = math.floor(CONFIG.COLUMNS_WIDTH[k] * CONFIG.WIDTH)
        columnPositions[k] = {currentX, currentX + width}
        currentX = currentX + width
        totalWidth = totalWidth + width
    end
end

--[[ Function declarations ]]--
local onRender
local animateScoreboard
local drawScoreboard
local drawRoundedRectangle

--[[
* initFonts
Create or load font objects
--]]
local function initFonts()
    -- Try to load custom fonts, fall back to defaults if not available
    fonts.roboto_bold = dxCreateFont(":resources/fonts/Roboto-Bold.ttf", 12) or "default-bold"
    fonts.roboto_regular = dxCreateFont(":resources/fonts/Roboto-Regular.ttf", 10) or "default"
    fonts.roboto_light = dxCreateFont(":resources/fonts/Roboto-Light.ttf", 8) or "default"
    fonts.awesome = dxCreateFont(":resources/fonts/FontAwesome.otf", 10) or "default-bold"
end

--[[
* getFont
Gets the appropriate font with fallback
--]]
local function getFont(fontName)
    return fonts[fontName] or "default"
end

--[[
* drawRoundedRectangle
Draws a rectangle with rounded corners
--]]
function drawRoundedRectangle(x, y, width, height, color, radius)
    local radius = radius or CONFIG.CORNER_RADIUS
    
    -- Draw the main rectangle (slightly smaller to accommodate corners)
    dxDrawRectangle(x + radius, y, width - (radius * 2), height, color, CONFIG.POSTGUI)
    dxDrawRectangle(x, y + radius, width, height - (radius * 2), color, CONFIG.POSTGUI)
    
    -- Draw the four corner circles
    dxDrawCircle(x + radius, y + radius, radius, 180, 270, color, color, 8, 1, CONFIG.POSTGUI)
    dxDrawCircle(x + width - radius, y + radius, radius, 270, 360, color, color, 8, 1, CONFIG.POSTGUI)
    dxDrawCircle(x + radius, y + height - radius, radius, 90, 180, color, color, 8, 1, CONFIG.POSTGUI)
    dxDrawCircle(x + width - radius, y + height - radius, radius, 0, 90, color, color, 8, 1, CONFIG.POSTGUI)
end

--[[
* clamp
Clamps a value into a range
--]]
local function clamp(valueMin, current, valueMax)
    if current < valueMin then
        return valueMin
    elseif current > valueMax then
        return valueMax
    else
        return current
    end
end

--[[
* createPlayerCache
Generates a new player cache
--]]
local function createPlayerCache(ignorePlayer)
    -- Clear the global table
    g_players = {}

    -- Get the list of connected players
    local players = getElementsByType("player")

    -- Dump them to the global table
    for k, player in ipairs(players) do
        if ignorePlayer ~= player then
            table.insert(g_players, player)
        end
    end

    -- Sort the player list by their ID, giving priority to the local player
    table.sort(g_players, function(a, b)
        local idA = getElementData(a, "playerid") or 0
        local idB = getElementData(b, "playerid") or 0

        -- Perform the checks to always set the local player at the beginning
        if a == g_localPlayer then
            idA = -1
        elseif b == g_localPlayer then
            idB = -1
        end

        return tonumber(idA) < tonumber(idB)
    end)
end

--[[
* updateLocalFPS
Updates the local FPS counter
--]]
local function updateLocalFPS()
    frameCounter = frameCounter + 1
    local currentTime = getTickCount()
    
    -- Update FPS count every 1000ms
    if currentTime - lastFPSUpdate >= 1000 then
        currentFPS = frameCounter
        frameCounter = 0
        lastFPSUpdate = currentTime
        
        -- Set local player's FPS to element data so it can be synced
        setElementData(localPlayer, "playerFPS", currentFPS)
    end
    
    -- Store FPS data for each player
    for _, player in ipairs(getElementsByType("player")) do
        local fps = getElementData(player, "playerFPS") or 0
        g_fpsList[player] = fps
    end
end

--[[
* onClientResourceStart
Handles the resource start event
--]]
addEventHandler("onClientResourceStart", getResourceRootElement(getThisResource()), function()
    createPlayerCache()
    initFonts()
    calculateColumnPositions()
    
    -- Add event handler to update FPS continuously
    addEventHandler("onClientRender", root, updateLocalFPS)
end, false)

--[[
* onClientElementDataChange
Updates player cache when playerid changes
--]]
addEventHandler("onClientElementDataChange", root, function(dataName)
    if dataName == "playerid" then
        createPlayerCache()
    end
end)

--[[
* onClientPlayerQuit
Updates the player cache when a player quits
--]]
addEventHandler("onClientPlayerQuit", root, function()
    createPlayerCache(source)
    g_fpsList[source] = nil
end)

--[[
* onClientCursorMove
Tracks mouse position for hover effects
--]]
addEventHandler("onClientCursorMove", root, function(_, _, x, y)
    g_mouseX, g_mouseY = x, y
end)

--[[
* toggleScoreboard
Toggles the visibility of the scoreboard
--]]
local function toggleScoreboard(show)
    if not getPedControlState(localPlayer, 'aim_weapon') then
        -- Force the parameter to be a boolean
        local show = show == true

        -- Check if the status has changed
        if show ~= g_isShowing then
            g_isShowing = show

            if g_isShowing and g_animationProgress == 0 then
                -- Start drawing the scoreboard
                addEventHandler("onClientRender", root, onRender, false)
            end

            -- Disable controls while scoreboard is showing
            if g_isShowing then
                g_oldControlStates = {}
                for k, control in ipairs(CONFIG.DISABLED_CONTROLS) do
                    g_oldControlStates[k] = isControlEnabled(control)
                    toggleControl(control, false)
                end
            else
                for k, control in ipairs(CONFIG.DISABLED_CONTROLS) do
                    toggleControl(control, g_oldControlStates[k])
                end
                g_oldControlStates = nil
            end
        end
    end
end

--[[
* onToggleKey
Function to toggle the scoreboard visibility
--]]
local function onToggleKey(key, keyState)
    -- Check if the scoreboard element has been created
    if not g_scoreboardDummy then
        local elementTable = getElementsByType("scoreboard")
        if #elementTable > 0 then
            g_scoreboardDummy = elementTable[1]
        else
            return
        end
    end

    -- Toggle the scoreboard, and check that it's allowed
    toggleScoreboard(keyState == "down" and getElementData(g_scoreboardDummy, "allow"))
end
bindKey(CONFIG.TOGGLE_KEY, "both", onToggleKey)

--[[
* onScrollKey
Function to change the current page
--]]
local function onScrollKey(direction)
    if g_isShowing then
        if direction then
            g_currentPage = g_currentPage + 1
        else
            g_currentPage = g_currentPage - 1
            if g_currentPage < 0 then
                g_currentPage = 0
            end
        end
    end
end
bindKey(CONFIG.PGUP_CONTROL, "down", function() onScrollKey(false) end)
bindKey(CONFIG.PGDN_CONTROL, "down", function() onScrollKey(true) end)

--[[
* onRender
Event handler for onClientRender
--]]
onRender = function()
    -- Update animation if needed
    animateScoreboard()
    
    -- Draw the scoreboard if animation progress is > 0
    if g_animationProgress > 0 then
        drawScoreboard()
    else if not g_isShowing then
        removeEventHandler("onClientRender", root, onRender)
        end
    end
end

--[[
* animateScoreboard
Animate the scoreboard appearance/disappearance
--]]
function animateScoreboard()
    local targetValue = g_isShowing and 1 or 0
    local currentTime = getTickCount()
    
    -- Smoothly animate between 0 and 1
    if g_animationProgress ~= targetValue then
        local direction = g_isShowing and 1 or -1
        local change = (direction * (currentTime - (g_lastAnimTime or (currentTime - 50))) / CONFIG.TOGGLE_TIME) * 2
        g_animationProgress = clamp(0, g_animationProgress + change, 1)
        SCOREBOARD_ALPHA_MULT = g_animationProgress
        
        -- Update current dimensions
        g_currentWidth = CONFIG.WIDTH * g_animationProgress
        g_currentHeight = CONFIG.HEIGHT * g_animationProgress
    end
    
    g_lastAnimTime = currentTime
end

--[[
* drawServerInfo
Draws the server header information
--]]
local function drawServerInfo()
    -- Get the server information
    local serverName = CONFIG.SERVER_NAME or getElementData(g_scoreboardDummy, "serverName") or "MTA Server"
    local maxPlayers = getElementData(root, "server:Slots") or 1024
    local usagePercent = (#g_players / maxPlayers) * 100
    local playerCountStr = "Players: " .. tostring(#g_players) .. "/" .. tostring(maxPlayers) .. " (" .. math.floor(usagePercent + 0.5) .. "%)"
    
    -- Draw header background
    drawRoundedRectangle(
        SCOREBOARD_X, 
        SCOREBOARD_Y, 
        g_currentWidth, 
        CONFIG.HEADER_HEIGHT, 
        HEADER_BG_COLOR
    )
    
    -- Draw server name
    dxDrawText(
        serverName, 
        SCOREBOARD_X + 10, 
        SCOREBOARD_Y + 5, 
        SCOREBOARD_X + g_currentWidth - 15, 
        SCOREBOARD_Y + 30,
        SERVER_NAME_COLOR, 
        1, 
        getFont("roboto_bold"), 
        "left", 
        "top",
        true, 
        false, 
        CONFIG.POSTGUI,
        true
    )
    
    -- Draw player count
    dxDrawText(
        playerCountStr, 
        SCOREBOARD_X + 15, 
        SCOREBOARD_Y + 28, 
        SCOREBOARD_X + g_currentWidth - 15, 
        SCOREBOARD_Y + CONFIG.HEADER_HEIGHT,
        SERVER_INFO_COLOR, 
        0.9, 
        getFont("roboto_regular"), 
        "left", 
        "top",
        true, 
        false, 
        CONFIG.POSTGUI,
        true
    )
    
    -- Draw current time on the right
    local timeStr = os.date("%H:%M:%S")
    dxDrawText(
        timeStr, 
        SCOREBOARD_X + 15, 
        SCOREBOARD_Y + 10, 
        SCOREBOARD_X + g_currentWidth - 15, 
        SCOREBOARD_Y + CONFIG.HEADER_HEIGHT - 10,
        SERVER_INFO_COLOR, 
        1, 
        getFont("roboto_regular"), 
        "right", 
        "center",
        true, 
        false, 
        CONFIG.POSTGUI,
        true
    )
end

--[[
* drawColumn
Draws a single column of the scoreboard
--]]
local function drawColumn(index, text, y, width, height, color, font, align)
    local x = columnPositions[index][1]
    local maxWidth = columnPositions[index][2] - columnPositions[index][1]
    
    dxDrawText(
        text,
        x + 5, 
        y,
        x + maxWidth - 5, 
        y + height,
        color, 
        1, 
        font, 
        align or "left", 
        "center",
        true, 
        false, 
        CONFIG.POSTGUI,
        false
    )
end

--[[
* drawColumnHeaders
Draws the column headers
--]]
local function drawColumnHeaders(y)
    local headerY = y
    local headerFont = getFont("roboto_bold")
    
    -- Draw the headers background
    dxDrawRectangle(
        SCOREBOARD_X, 
        headerY, 
        g_currentWidth, 
        CONFIG.ROW_HEIGHT,
        toColorAlpha({40, 40, 40, 220}), 
        CONFIG.POSTGUI
    )
    
    -- Draw each header
    drawColumn(1, "ID", headerY, CONFIG.COLUMNS_WIDTH[1], CONFIG.ROW_HEIGHT, HEADERS_COLOR, headerFont, "center")
    drawColumn(2, "Player Name", headerY, CONFIG.COLUMNS_WIDTH[2], CONFIG.ROW_HEIGHT, HEADERS_COLOR, headerFont, "left")
    drawColumn(3, "Hours", headerY, CONFIG.COLUMNS_WIDTH[3], CONFIG.ROW_HEIGHT, HEADERS_COLOR, headerFont, "center")
    drawColumn(4, "Ping", headerY, CONFIG.COLUMNS_WIDTH[4], CONFIG.ROW_HEIGHT, HEADERS_COLOR, headerFont, "center")
    drawColumn(5, "FPS", headerY, CONFIG.COLUMNS_WIDTH[5], CONFIG.ROW_HEIGHT, HEADERS_COLOR, headerFont, "center")
    
    -- Draw separator line
    dxDrawRectangle(
        SCOREBOARD_X, 
        headerY + CONFIG.ROW_HEIGHT, 
        g_currentWidth, 
        2,
        SEPARATOR_COLOR, 
        CONFIG.POSTGUI
    )
    
    return headerY + CONFIG.ROW_HEIGHT + 2
end

--[[
* getPlayerNameColor
Gets the player's name color based on their status
--]]
local function getPlayerNameColor(player)
    local isLoggedIn = getElementData(player, "loggedin") == 1
    
    if not isLoggedIn then
        return CONFIG.LOGGED_OUT_COLOR
    elseif getElementData(player, "donation:nametag") and getElementData(player, "nametag_on") then
        return CONFIG.DONATOR_COLOR
    elseif getElementData(player, "admin_level") and tonumber(getElementData(player, "admin_level")) > 0 then
        return CONFIG.ADMIN_COLOR
    elseif tonumber(getElementData(player, "admin_level")) == 10 then
        return CONFIG.OWNER_COLOR
    end
    
    return CONFIG.REGULAR_COLOR
end

--[[
* drawPlayerRow
Draws a player row in the scoreboard
--]]
local function drawPlayerRow(player, rowIndex, y, isHighlighted)
    local rowY = y
    local rowFont = getFont("roboto_regular")
    local isLoggedIn = getElementData(player, "loggedin") == 1
    
    -- Get player data
    local playerID = getElementData(player, "playerid") or 0
    local playerName = exports.global and exports.global:getPlayerName(player) or getPlayerName(player)
    local playerHours = getElementData(player, "hoursplayed") or 0
    local playerPing = getPlayerPing(player) or 0
    local playerFPS = g_fpsList[player] or 0
    
    -- Get player color
    local playerColor = getPlayerNameColor(player)
    
    -- Draw row background (alternating colors + highlight)
    local bgColor = isHighlighted and ROW_HIGHLIGHT_COLOR or 
                    (rowIndex % 2 == 0 and toColorAlpha({30, 30, 30, 180}) or toColorAlpha({25, 25, 25, 160}))
    
    dxDrawRectangle(
        SCOREBOARD_X, 
        rowY, 
        g_currentWidth, 
        CONFIG.ROW_HEIGHT,
        bgColor, 
        CONFIG.POSTGUI
    )
    
    -- If this is the local player, highlight with a side indicator
    if player == localPlayer then
        dxDrawRectangle(
            SCOREBOARD_X, 
            rowY, 
            3, 
            CONFIG.ROW_HEIGHT,
            toColorAlpha({60, 180, 240, 255}), 
            CONFIG.POSTGUI
        )
    end
    
    -- Player text color
    local textColor = tocolor(playerColor[1], playerColor[2], playerColor[3], 255 * SCOREBOARD_ALPHA_MULT)
    local grayTextColor = tocolor(180, 180, 180, 255 * SCOREBOARD_ALPHA_MULT)
    
    -- Draw player columns
    drawColumn(1, tostring(playerID), rowY, CONFIG.COLUMNS_WIDTH[1], CONFIG.ROW_HEIGHT, textColor, rowFont, "center")
    
    -- Draw player name (directly using the player's color)
    drawColumn(2, playerName, rowY, CONFIG.COLUMNS_WIDTH[2], CONFIG.ROW_HEIGHT, textColor, rowFont, "left")
    
    -- Draw hours and ping
    drawColumn(3, tostring(playerHours), rowY, CONFIG.COLUMNS_WIDTH[3], CONFIG.ROW_HEIGHT, grayTextColor, rowFont, "center")
    
    -- Color ping based on value
    local pingColor
    if playerPing < 80 then
        pingColor = tocolor(100, 220, 100, 255 * SCOREBOARD_ALPHA_MULT)
    elseif playerPing < 150 then
        pingColor = tocolor(220, 220, 100, 255 * SCOREBOARD_ALPHA_MULT)
    else
        pingColor = tocolor(220, 100, 100, 255 * SCOREBOARD_ALPHA_MULT)
    end
    
    drawColumn(4, tostring(playerPing), rowY, CONFIG.COLUMNS_WIDTH[4], CONFIG.ROW_HEIGHT, pingColor, rowFont, "center")
    
    -- Color FPS based on value
    local fpsColor
    if playerFPS > 40 then
        fpsColor = tocolor(100, 220, 100, 255 * SCOREBOARD_ALPHA_MULT)
    elseif playerFPS > 25 then
        fpsColor = tocolor(220, 220, 100, 255 * SCOREBOARD_ALPHA_MULT)
    else
        fpsColor = tocolor(220, 100, 100, 255 * SCOREBOARD_ALPHA_MULT)
    end
    
    drawColumn(5, tostring(playerFPS), rowY, CONFIG.COLUMNS_WIDTH[5], CONFIG.ROW_HEIGHT, fpsColor, rowFont, "center")
    
    return rowY + CONFIG.ROW_HEIGHT + CONFIG.ROW_GAP
end

--[[
* drawScrollBar
Draws the scrollbar
--]]
local function drawScrollBar(startY, endY, position, maxPosition)
    -- Use the full width instead of the 6th column
    local scrollX = SCOREBOARD_X + g_currentWidth - 20 -- 20px width for scrollbar
    local scrollWidth = 20
    local height = endY - startY
    
    -- Draw scrollbar background
    dxDrawRectangle(
        scrollX, 
        startY, 
        scrollWidth, 
        height,
        toColorAlpha({0, 0, 0, 100}), 
        CONFIG.POSTGUI
    )
    
    -- Only draw scrollbar if necessary
    if maxPosition > 0 then
        local scrollHeight = math.max(40, height / (maxPosition + 1))
        local scrollY = startY + (position / maxPosition) * (height - scrollHeight)
        
        -- Check if mouse is hovering over scrollbar
        g_scrollbarHovered = isCursorShowing() and 
                            g_mouseX >= scrollX and 
                            g_mouseX <= scrollX + scrollWidth and
                            g_mouseY >= scrollY and 
                            g_mouseY <= scrollY + scrollHeight
        
        -- Draw scrollbar handle
        dxDrawRectangle(
            scrollX + 2, 
            scrollY, 
            scrollWidth - 4, 
            scrollHeight,
            g_scrollbarHovered and SCROLL_HOVER_COLOR or SCROLL_COLOR, 
            CONFIG.POSTGUI
        )
    end
end

--[[
* drawScoreboard
Draws the complete scoreboard
--]]
drawScoreboard = function()
    -- Check that we have player data
    if not g_players then return end
    
    -- First draw the main background
    drawRoundedRectangle(
        SCOREBOARD_X, 
        SCOREBOARD_Y + CONFIG.HEADER_HEIGHT, 
        g_currentWidth, 
        g_currentHeight - CONFIG.HEADER_HEIGHT, 
        BACKGROUND_COLOR
    )
    
    -- Draw server info header
    drawServerInfo()
    
    -- Calculate content area
    local contentY = SCOREBOARD_Y + CONFIG.HEADER_HEIGHT
    local contentStartY = drawColumnHeaders(contentY)
    local contentHeight = SCOREBOARD_Y + g_currentHeight - contentStartY
    
    -- Calculate how many players can fit in the view
    local playersPerPage = math.floor(contentHeight / (CONFIG.ROW_HEIGHT + CONFIG.ROW_GAP))
    
    -- Calculate max pages based on player count
    local maxPage = math.max(0, math.ceil(#g_players / playersPerPage) - 1)
    
    -- Clamp current page
    g_currentPage = clamp(0, g_currentPage, maxPage)
    
    -- Calculate which players to display
    local startIndex = g_currentPage * playersPerPage + 1
    local endIndex = math.min(startIndex + playersPerPage - 1, #g_players)
    
    -- Draw player rows
    local currentY = contentStartY
    for i = startIndex, endIndex do
        local player = g_players[i]
        local rowIndex = i - startIndex
        
        -- Check if this row is being hovered
        local isRowHovered = isCursorShowing() and 
            g_mouseY >= currentY and 
            g_mouseY <= currentY + CONFIG.ROW_HEIGHT and
            g_mouseX >= SCOREBOARD_X and 
            g_mouseX <= SCOREBOARD_X + g_currentWidth - 20 -- Account for scrollbar width
        
        if isRowHovered then
            g_hoveredRow = i
        end
        
        currentY = drawPlayerRow(player, rowIndex, currentY, isRowHovered or g_hoveredRow == i)
    end
    
    -- Draw scrollbar
    drawScrollBar(
        contentStartY, 
        SCOREBOARD_Y + g_currentHeight, 
        g_currentPage, 
        maxPage
    )
end

-- Add click handler for player selection
addEventHandler("onClientClick", root, function(button, state)
    if not g_isShowing or g_hoveredRow == -1 or not g_players[g_hoveredRow] then return end
    
    if button == "left" and state == "down" then
        local currentTime = getTickCount()
        local timeDiff = currentTime - g_lastClickTime
        
        if timeDiff < 500 then
            -- Double click detected
            local selectedPlayer = g_players[g_hoveredRow]
            
            -- Add your double-click action here (e.g. open player menu)
            -- For example: triggerEvent("onPlayerMenuRequest", selectedPlayer)
        end
        
        g_lastClickTime = currentTime
    end
end)

-- Add mouse wheel handler when scoreboard is showing
addEventHandler("onClientKey", root, function(button, press)
    if not g_isShowing or not isCursorShowing() then return end
    
    if (button == "mouse_wheel_up" or button == "mouse_wheel_down") and press then
        onScrollKey(button == "mouse_wheel_down")
    end
end)