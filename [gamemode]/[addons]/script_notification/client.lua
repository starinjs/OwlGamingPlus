--[[ 
Enhanced Notification System
Simplified version with maximum 3 notifications visible at once
Free for use by everyone

THE SCRIPT: An advanced notification system with:
- Maximum 3 notifications visible at once
- Regular notifications with customizable colors
- Prompt notifications with key bindings
- Sound effects
- Smooth animations and display
- Optimized code

CLIENT SIDE:
Regular notification: exports.script_notification:showNotification("Hello there!", {200, 200, 200})
Prompt notification: exports.script_notification:showNotification("Pick up item", {200, 200, 200}, "E")

SERVER SIDE:
Regular notification: exports.script_notification:showNotification(element, "Hello there!", {200, 200, 200})
Prompt notification: exports.script_notification:showNotification(element, "Pick up item", {200, 200, 200}, "E")
]]

-- Configuration
local CONFIG = {
    MAX_ACTIVE_NOTIFICATIONS = 3, -- Maximum number of notifications visible at once
    NOTIFICATION_HEIGHT = 30,     -- Height of each notification
    NOTIFICATION_SPACING = 2,     -- Space between notifications
    VERTICAL_OFFSET = 20,         -- Initial offset from the top of the screen
    FADE_IN_DURATION = 500,       -- Time in ms for notification to fade in
    DISPLAY_DURATION = 250,       -- Time in ms notification stays at full opacity
    FADE_OUT_DURATION = 2500,     -- Time in ms for notification to fade out
    DEFAULT_COLOR = {200, 200, 200}, -- Default notification color
    PROMPT_COLOR = {30, 30, 30},  -- Background color for prompt notifications
    TEXT_COLOR = {255, 255, 255}, -- Text color for regular notifications
    PROMPT_TEXT_COLOR = {200, 200, 200}, -- Text color for prompt notifications
    BUTTON_TEXT_COLOR = {30, 30, 30}, -- Text color for the button in prompt notifications
    BUTTON_BG_COLOR = {200, 200, 200}, -- Button background color
    GRADIENT_ALPHA = 3,           -- Divisor for gradient overlay transparency
    BUTTON_WIDTH = 25,            -- Width of the prompt button
    BUTTON_FONT = "default-bold", -- Font for button text
    MESSAGE_FONT = "default-bold" -- Font for notification text
}

-- Resources
local screenX, screenY = guiGetScreenSize()
local activeNotifications = {}    -- Currently active notifications (max 3)
local gradientTexture = dxCreateTexture("files/gradient.png", "dxt5", true)

-- Sound files
local SOUNDS = {
    PROMPT = "files/prompt.mp3",
    MESSAGE = "files/message.mp3"
}

--[[ Utility Functions ]]--

-- Check if a notification with the given text is already active
local function isNotificationActive(text)
    for _, notification in ipairs(activeNotifications) do
        if notification.text == text then
            return true
        end
    end
    return false
end

-- Play a sound effect
local function playNotificationSound(isPrompt)
    local soundFile = isPrompt and SOUNDS.PROMPT or SOUNDS.MESSAGE
    playSound(soundFile)
end

-- Clean up expired notifications
local function cleanupNotifications()
    local currentTick = getTickCount()
    local i = 1
    
    while i <= #activeNotifications do
        local notification = activeNotifications[i]
        
        if notification.state == "closing" and notification.alpha <= 0 then
            table.remove(activeNotifications, i)
        else
            i = i + 1
        end
    end
end

--[[ Core Functions ]]--

-- Main function to show a notification
function showNotification(text, color, button)
    -- Validate input and check if notification already exists
    if not text or isNotificationActive(text) then
        return false
    end
    
    -- Clean up any expired notifications first
    cleanupNotifications()
    
    -- If we already have max notifications, don't show more
    if #activeNotifications >= CONFIG.MAX_ACTIVE_NOTIFICATIONS then
        return false
    end
    
    -- Apply default color if none provided
    local notificationColor = color or CONFIG.DEFAULT_COLOR
    
    -- For prompt notifications, use the prompt color
    if button then
        notificationColor = CONFIG.PROMPT_COLOR
    end
    
    -- Create and add new notification
    table.insert(activeNotifications, {
        text = text,
        prompt = button or false,
        width = dxGetTextWidth(text, 1, CONFIG.MESSAGE_FONT) + 10,
        createdAt = getTickCount(),
        state = "opening",
        alpha = 0,
        color = notificationColor
    })
    
    -- Play appropriate sound
    playNotificationSound(button ~= nil)
    
    return true
end

-- Handle notifications from server side
function showNotificationFromServer(text, color, button)
    showNotification(text, color, button)
end

addEvent("insertClientMessageFromServerSide", true)
addEventHandler("insertClientMessageFromServerSide", getRootElement(), showNotificationFromServer)

--[[ Rendering ]]--

-- Main render function
addEventHandler("onClientRender", getRootElement(), function()
    local currentTick = getTickCount()
    
    -- Process each active notification
    for i, notification in ipairs(activeNotifications) do
        -- Handle animation states
        if notification.state == "opening" then
            local elapsedTime = currentTick - notification.createdAt
            local progress = elapsedTime / CONFIG.FADE_IN_DURATION
            
            notification.alpha = interpolateBetween(0, 0, 0, 230, 0, 0, progress, "Linear")
            
            if progress >= 1 then
                notification.createdAt = currentTick
                notification.state = "displaying"
            end
        elseif notification.state == "displaying" then
            notification.alpha = 230
            
            local elapsedTime = currentTick - notification.createdAt
            if elapsedTime >= CONFIG.DISPLAY_DURATION then
                notification.createdAt = currentTick
                notification.state = "closing"
            end
        elseif notification.state == "closing" then
            local elapsedTime = currentTick - notification.createdAt
            local progress = elapsedTime / CONFIG.FADE_OUT_DURATION
            
            notification.alpha = interpolateBetween(230, 0, 0, 0, 0, 0, progress, "Linear")
        end
        
        -- Calculate positions and colors for rendering
        local alpha = notification.alpha
        local width, height = notification.width, CONFIG.NOTIFICATION_HEIGHT
        local verticalPosition = CONFIG.VERTICAL_OFFSET + (i - 1) * (height + CONFIG.NOTIFICATION_SPACING)
        
        -- Position differently based on notification type
        local x = notification.prompt and 
            (screenX/2 - width/2) + (CONFIG.BUTTON_WIDTH/2) or 
            (screenX/2 - width/2)
        local y = verticalPosition
        
        -- Colors with alpha
        local bgColor = tocolor(
            notification.color[1], 
            notification.color[2], 
            notification.color[3], 
            alpha
        )
        
        local textColor = notification.prompt and 
            tocolor(CONFIG.PROMPT_TEXT_COLOR[1], CONFIG.PROMPT_TEXT_COLOR[2], CONFIG.PROMPT_TEXT_COLOR[3], alpha) or 
            tocolor(CONFIG.TEXT_COLOR[1], CONFIG.TEXT_COLOR[2], CONFIG.TEXT_COLOR[3], alpha)
        
        -- Draw notification background
        dxDrawRectangle(x, y, width, height, bgColor)
        
        -- Draw notification text
        dxDrawText(
            notification.text, 
            x + width/2, y + height/2, 
            x + width/2, y + height/2, 
            textColor, 
            1, CONFIG.MESSAGE_FONT, 
            "center", "center"
        )
        
        -- Draw prompt button if needed
        if notification.prompt then
            local buttonX = x - CONFIG.BUTTON_WIDTH
            
            -- Draw button background
            dxDrawRectangle(
                buttonX, y, 
                CONFIG.BUTTON_WIDTH, height, 
                tocolor(CONFIG.BUTTON_BG_COLOR[1], CONFIG.BUTTON_BG_COLOR[2], CONFIG.BUTTON_BG_COLOR[3], alpha)
            )
            
            -- Draw button text
            dxDrawText(
                notification.prompt, 
                buttonX + CONFIG.BUTTON_WIDTH/2, y + height/2, 
                buttonX + CONFIG.BUTTON_WIDTH/2, y + height/2, 
                tocolor(CONFIG.BUTTON_TEXT_COLOR[1], CONFIG.BUTTON_TEXT_COLOR[2], CONFIG.BUTTON_TEXT_COLOR[3], alpha), 
                1.5, CONFIG.BUTTON_FONT, 
                "center", "center"
            )
        end
        
        -- Apply gradient overlay
        if gradientTexture then
            dxDrawImage(
                x, y, 
                width, height, 
                gradientTexture, 
                0, 0, 0, 
                tocolor(0, 0, 0, alpha/CONFIG.GRADIENT_ALPHA)
            )
        end
    end
end, true, "low-99999")

-- Export the function for external use
exports.script_notification = {}
exports.script_notification.showNotification = showNotification

-- Maintain backward compatibility
exports.script_notification.insertClientMessage = showNotification