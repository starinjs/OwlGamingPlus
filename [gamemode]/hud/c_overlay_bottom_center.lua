local localPlayer = getLocalPlayer()
local show = false
local sx, sy = guiGetScreenSize()
local content = {}
local timerClose = getTickCount()
local cooldownTime = 5 --seconds
local toBeDrawnWidth = 0
local animationProgress = 0
local boxAlpha = 0
local isAnimating = false

-- Fonts
local titleFont = nil
local textFont = nil

-- Colors
local headerBgColor = tocolor(25, 132, 197, 255) -- Blue header color
local bodyBgColor = tocolor(0, 0, 0, 220)        -- Darker body background
local textColor = tocolor(255, 255, 255, 255)    -- White text

-- Design settings
local paddingX = 15
local paddingY = 10
local headerHeight = 30
local contentLineHeight = 22
local minWidth = 300

local function removeRender()
    if show then
        removeEventHandler("onClientRender", root, clientRender)
        show = false
        isAnimating = false
    end
end

local function makeFonts()
    if not titleFont then
        titleFont = dxCreateFont(":resources/fonts/Roboto-Bold.ttf", 11) or "default-bold"
    end
    
    if not textFont then
        textFont = dxCreateFont(":resources/fonts/Roboto-Regular.ttf", 10) or "default"
    end
end

function isEventHandlerAdded(sEventName, pElementAttachedTo, func)
    if type(sEventName) == 'string' and isElement(pElementAttachedTo) and type(func) == 'function' then
        local aAttachedFunctions = getEventHandlers(sEventName, pElementAttachedTo)
        if type(aAttachedFunctions) == 'table' and #aAttachedFunctions > 0 then
            for _, v in ipairs(aAttachedFunctions) do
                if v == func then
                    return true
                end
            end
        end
    end
    return false
end

function drawOverlayBottomCenter(info, widthNew, woffsetNew, hoffsetNew, cooldown)
    if getElementData(localPlayer, "loggedin") == 1 then
        makeFonts()
        content = info
        
        -- Calculate width based on content
        toBeDrawnWidth = 0
        for i=1, #info do
            local font = i == 1 and titleFont or (info[i][7]) or textFont
            local textWidth = dxGetTextWidth(info[i][1] or "", (info[i][6] or 1), font)
            if textWidth > toBeDrawnWidth then
                toBeDrawnWidth = textWidth
            end
        end
        
        toBeDrawnWidth = math.max(toBeDrawnWidth + paddingX * 2, minWidth)
        
        -- Play sound
        playSoundFrontEnd(101)
        
        -- Output to console
        for i=1, #info do
            outputConsole(info[i][1] or "")
        end
        
        -- Start animation
        animationProgress = 0
        boxAlpha = 0
        isAnimating = true
        
        if not show and not isEventHandlerAdded("onClientRender", root, clientRender) then
            addEventHandler("onClientRender", root, clientRender)
            show = true
        end
        
        -- Reset timer
        timerClose = getTickCount()
        cooldownTime = cooldown or 5
    else
        removeRender()
    end
end
addEvent("hudOverlay:drawOverlayBottomCenter", true)
addEventHandler("hudOverlay:drawOverlayBottomCenter", localPlayer, drawOverlayBottomCenter)

function clientRender()
    if not show then return end
    
    -- Don't show while aiming with camera
    if (getPedWeapon(localPlayer) == 43 and getPedControlState(localPlayer, "aim_weapon")) then
        return
    end
    
    -- Calculate box dimensions
    local contentHeight = (#content - 1) * contentLineHeight + paddingY * 2
    local boxHeight = headerHeight + contentHeight
    local boxWidth = toBeDrawnWidth
    
    -- Animation handling
    local currentTick = getTickCount()
    local elapsedTime = currentTick - timerClose
    
    if isAnimating and animationProgress < 1 then
        animationProgress = math.min(1, animationProgress + 0.08)
        boxAlpha = 255 * animationProgress
    elseif elapsedTime > (cooldownTime * 1000 - 800) and elapsedTime < (cooldownTime * 1000) then
        -- Fade out animation in the last 0.8 seconds
        local fadeOutProgress = (elapsedTime - (cooldownTime * 1000 - 800)) / 800
        boxAlpha = 255 * (1 - fadeOutProgress)
    elseif elapsedTime >= cooldownTime * 1000 then
        removeRender()
        return
    else
        boxAlpha = 255
    end
    
    -- Calculate position (centered at bottom)
    local posX = (sx / 2) - (boxWidth / 2)
    local posY = sy - boxHeight - 40 -- 40px from bottom
    
    -- Draw the header background (no border) with reduced alpha
    dxDrawRectangle(posX, posY, boxWidth, headerHeight, tocolor(25, 132, 197, boxAlpha * 0.6))
    
    -- Draw the body background (no border) with reduced alpha
    dxDrawRectangle(posX, posY + headerHeight, boxWidth, contentHeight, tocolor(0, 0, 0, boxAlpha * 0.5))
    
    -- Draw content with both X and Y centered
    for i=1, #content do
        if content[i] then
            local font = i == 1 and titleFont or (content[i][7]) or textFont
            local scale = content[i][6] or 1
            
            if i == 1 then
                -- Header text - centered on both axes
                local textAlpha = math.min(255, boxAlpha * 1.2)
                local textCol = tocolor(255, 255, 255, textAlpha)
                
                -- Center text horizontally and vertically
                dxDrawText(content[i][1] or "", posX, posY, posX + boxWidth, posY + headerHeight, 
                           textCol, scale, font, "center", "center")
            else
                -- Body text - centered on both axes
                local bodyStartY = posY + headerHeight
                local bodyItemHeight = contentLineHeight
                local itemY = bodyStartY + ((i-2) * bodyItemHeight)
                
                local textAlpha = math.min(255, boxAlpha * 1.1)
                local textCol = tocolor(content[i][2] or 255, content[i][3] or 255, content[i][4] or 255, 
                                       ((content[i][5] or 255) * (textAlpha/255)))
                
                -- Center text horizontally and vertically within its line
                dxDrawText(content[i][1] or "", posX, itemY, posX + boxWidth, itemY + bodyItemHeight, 
                           textCol, scale, font, "center", "center")
            end
        end
    end
end