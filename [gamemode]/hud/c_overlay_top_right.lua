local localPlayer = getLocalPlayer()
local show = false
local width, height = 246, 300
local sx, sy = guiGetScreenSize()
local screenWidth, screenHeight = guiGetScreenSize()
local content = {}
local timerClose = nil
local cooldownTime = 20 --seconds
local robotoFont = dxCreateFont(":resources/fonts/Roboto-Regular.ttf", 9)
local robotoBold = dxCreateFont(":resources/fonts/Roboto-Bold.ttf", 10)
local toBeDrawnWidth = width
local justClicked = false
local isPinned = false

-- Colors based on your example image
local colors = {
    background = tocolor(0, 0, 0, 180),      -- Dark background with higher opacity
    header = tocolor(27, 94, 145, 255),      -- Blue header background
    headerText = tocolor(255, 255, 255, 255),-- White header text
    pinText = tocolor(100, 180, 255, 255),   -- Blue text for pin button
    separatorLine = tocolor(80, 80, 80, 255) -- Gray separator line
}

function drawOverlayTopRight(info, widthNew, posXOffsetNew, posYOffsetNew, cooldown)
    local pinned = getElementData(localPlayer, "hud:pin")
    if not pinned and timerClose and isTimer(timerClose) then
        killTimer(timerClose)
        timerClose = nil
    end
    if info then
        content = info
        if content[1] then
            content[1][1] = string.sub(content[1][1], 1, 1)..string.sub(content[1][1], 2)
        end
    else
        return false
    end
    
    if widthNew then
        width = widthNew
        toBeDrawnWidth = width
    end
    
    if posXOffsetNew then
        posXOffset = posXOffsetNew
    end
    if posYOffsetNew then
        posYOffset = posYOffsetNew
    end
    if cooldown then
        cooldownTime = cooldown
    end
    if content then
        show = true
    end
    
    playSoundFrontEnd(101)
    if cooldownTime ~= 0 and not pinned then
        timerClose = setTimer(function()
            show = false
            setElementData(localPlayer, "hud:overlayTopRight", 0, false)
        end, cooldownTime*1000, 1)
    end
    
    for i=1, #info do
        outputConsole(info[i][1] or "")
    end
end
addEvent("hudOverlay:drawOverlayTopRight", true)
addEventHandler("hudOverlay:drawOverlayTopRight", localPlayer, drawOverlayTopRight)

addEventHandler("onClientRender", getRootElement(), function()
    if show and not getElementData(localPlayer, "integration:previewPMShowing") and getElementData(localPlayer, 'loggedin') == 1 then 
        if (getPedWeapon(localPlayer) ~= 43 or not getPedControlState(localPlayer, "aim_weapon")) then
            local posXOffset, posYOffset = 0, 0
            local hudDxHeight = getElementData(localPlayer, "hud:whereToDisplayY") or 0
            if hudDxHeight then
                posYOffset = posYOffset + hudDxHeight + 40
            end
            
            local reportDxHeight = getElementData(localPlayer, "report-system:dxBoxHeight") or 0
            if reportDxHeight then
                posYOffset = posYOffset + reportDxHeight
            end
            
            local panelWidth = toBeDrawnWidth
            local lineHeight = 16 -- Fixed line height to prevent overlapping
            local totalContentHeight = lineHeight * (#content + 2) -- +2 for some buffer space
            local panelHeight = totalContentHeight + 30 -- 30 for the header
            local panelX = sx - panelWidth - 5 + posXOffset
            local panelY = 5 + posYOffset
            
            -- Calculate total content to prevent overlap
            for i=1, #content do
                if content[i] and content[i][1] then
                    -- Check if text contains multiple lines
                    local textLines = 1
                    local text = content[i][1] or ""
                    for _ in string.gmatch(text, "\n") do
                        textLines = textLines + 1
                    end
                    totalContentHeight = totalContentHeight + (textLines - 1) * lineHeight
                end
            end
            
            panelHeight = totalContentHeight + 30 -- Recalculate with updated height
            
            -- Main background - fill from top to bottom with no gaps
            dxDrawRectangle(panelX, panelY, panelWidth, panelHeight, colors.background)
            
            -- Header background
            dxDrawRectangle(panelX, panelY, panelWidth, 30, colors.header)
            
            -- Draw title in header
            if content[1] then
                dxDrawText(content[1][1] or "", panelX + 10, panelY + 5, panelX + panelWidth - 60, panelY + 25, colors.headerText, 1, robotoBold or "default-bold", "left", "center")
            end
            
            -- Pin text button
            local pinned = getElementData(localPlayer, "hud:pin")
            local pinText = "PIN"
            local pinTextWidth = dxGetTextWidth(pinText, 1, robotoBold or "default-bold")
            local pinButtonX = panelX + panelWidth - pinTextWidth - 15
            local pinButtonY = panelY + 7
            
            if isCursorShowing() then
                local cursorX, cursorY = getCursorPosition()
                cursorX, cursorY = cursorX * screenWidth, cursorY * screenHeight
                
                if justClicked and isInBox(cursorX, cursorY, pinButtonX, pinButtonX + pinTextWidth, pinButtonY, pinButtonY + 16) then
                    if pinned then
                        unpinIt()
                    else
                        pinIt()
                    end
                    playToggleSound()
                end
            end
            justClicked = false
            
            -- Draw pin text
            dxDrawText(pinText, pinButtonX, pinButtonY, pinButtonX + pinTextWidth, pinButtonY + 16, 
                colors.pinText, 1, robotoBold or "default-bold")
            
            -- Update overlay height for other UI elements
            setElementData(localPlayer, "hud:overlayTopRight", panelHeight, false)
            
            -- Draw content with proper spacing - starting immediately below header with no gap
            local currentY = panelY + 30 -- Start position exactly at header bottom
            
            for i=2, #content do
                if content[i] then
                    local text = content[i][1] or ""
                    local currentWidth = dxGetTextWidth(text, 1, robotoFont or "default") + 30
                    if currentWidth > toBeDrawnWidth then
                        toBeDrawnWidth = currentWidth
                    end
                    
                    local contentX = panelX + 10
                    local contentY = currentY
                    
                    -- Check if this is a section header (usually has a colon)
                    local isHeader = string.find(text, ":") == #text
                    
                    -- Check if this is a value line (usually starts with dash)
                    local isValue = string.find(text, "^%s*[-]") ~= nil
                    
                    -- Format differently based on content type
                    if isHeader then
                        -- Section headers
                        dxDrawLine(contentX, contentY - 2, panelX + panelWidth - 10, contentY - 2, colors.separatorLine, 1)
                        dxDrawText(text, contentX, contentY, contentX + panelWidth - 20, contentY + lineHeight, 
                            tocolor(content[i][2] or 200, content[i][3] or 200, content[i][4] or 200, content[i][5] or 255), 
                            content[i][6] or 1, robotoBold or "default-bold")
                        currentY = currentY + lineHeight + 5
                    elseif isValue then
                        -- Indented values (like languages, skills)
                        local indent = 10
                        dxDrawText(text, contentX + indent, contentY, contentX + panelWidth - 20, contentY + lineHeight, 
                            tocolor(content[i][2] or 255, content[i][3] or 255, content[i][4] or 255, content[i][5] or 255), 
                            content[i][6] or 1, robotoFont or "default")
                        currentY = currentY + lineHeight
                    else
                        -- Check for progress bars (like in your example - "Carried Weight: 2.50/30.00")
                        local weightPattern = "(%d+%.?%d*)/(%d+%.?%d*)"
                        local currentWeight, maxWeight = string.match(text, weightPattern)
                        
                        if currentWeight and maxWeight then
                            -- Showing progress bar for weight
                            local numCurrentWeight = tonumber(currentWeight)
                            local numMaxWeight = tonumber(maxWeight)
                            local progress = numCurrentWeight / numMaxWeight
                            
                            -- Draw text
                            dxDrawText(text, contentX, contentY, contentX + panelWidth - 20, contentY + lineHeight, 
                                tocolor(content[i][2] or 255, content[i][3] or 255, content[i][4] or 255, content[i][5] or 255), 
                                content[i][6] or 1, robotoFont or "default")
                            currentY = currentY + lineHeight
                            
                            -- Draw progress bar
                            local barWidth = panelWidth - 30
                            local barHeight = 5
                            
                            -- Progress bar background
                            dxDrawRectangle(contentX, currentY, barWidth, barHeight, tocolor(30, 30, 30, 255))
                            
                            -- Progress bar fill
                            dxDrawRectangle(contentX, currentY, barWidth * (progress > 1 and 1 or progress), barHeight, colors.progressBar)
                            
                            currentY = currentY + barHeight + 5
                        else
                            -- Regular text
                            dxDrawText(text, contentX, contentY, contentX + panelWidth - 20, contentY + lineHeight, 
                                tocolor(content[i][2] or 255, content[i][3] or 255, content[i][4] or 255, content[i][5] or 255), 
                                content[i][6] or 1, robotoFont or "default")
                            currentY = currentY + lineHeight
                        end
                    end
                end
            end
        end
    end
end, false)

function pinIt()
    setElementData(localPlayer, "hud:pin", true, false)
    if timerClose and isTimer(timerClose) then
        killTimer(timerClose)
        timerClose = nil
    end
end

function unpinIt()
    setElementData(localPlayer, "hud:pin", false, false)
    timerClose = setTimer(function()
        show = false
        setElementData(localPlayer, "hud:overlayTopRight", 0, false)
    end, 3000, 1)
end

function isInBox(absX, absY, leftX, rightX, topY, bottomY)
    return (absX >= leftX and absX <= rightX and absY >= topY and absY <= bottomY)
end

-- TO DETECT CLICK ON DX BOX
addEventHandler("onClientClick", root,
    function(button, state)
        if show and button == "left" and state == "up" then
            justClicked = true
        end
    end
)

-- Function for playing toggle sound
function playToggleSound()
    playSoundFrontEnd(4) -- You can change this sound ID as needed
end