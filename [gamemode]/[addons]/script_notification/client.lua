--[[ 
Created by Tobzoska, free of use for everyone

THE SCRIPT: a basic notification script, with prompt notficiations added in it, + sound effects and {R, G, B} Color coding for regular notification

CLIENT SIDE:
usage for basic notification: exports.script_notification:insertClientMessage("Hello there!")
usage for a prompt: exports.script_notification:insertClientMessage("Pick up item", "E")

SERVER SIDE:
usage for basic notification: exports.script_notification:insertClientMessage(element, "Hello there!")
usage for a prompt: exports.script_notification:insertClientMessage(element, "Pick up item", "E")

]]

local screenX, screenY = guiGetScreenSize()
local clientMessagesTable = {}
local texture = dxCreateTexture("files/gradient.png", "dxt5", true)

local buttonFont = "default-bold"
local messageFont = "default-bold"

-- check, if the message is alredy displayed on the client's screen

function isClientMessageRendering(text)
    for i = 1, #clientMessagesTable do
        if clientMessagesTable[i]["text"] == text then
            return true
        end
    end

    return false
end

-- the main function for inserting a message, if you add a "button" argument, it will register as a prompt message

function insertClientMessage(text, color, button)
    if text and not isClientMessageRendering(text) then
        local color = color and color or {200, 200, 200}

        table.insert(clientMessagesTable, 
            {
                ["text"] = text,
                ["prompt"] = button and button or false,
                ["rectangleSize"] = dxGetTextWidth(text, 1, messageFont) + 10,
                ["tick"] = getTickCount(),
                ["animState"] = "open",
                ["alpha"] = 0,
                ["color"] = button and {30, 30, 30} or color
            }
        )

        if button then
            playSound("files/prompt.mp3")
        else
            playSound("files/message.mp3")
        end
    end
end

-- server side sync, to display a message/prompt to a client

function insertClientMessageFromServerSide(text, button)
    insertClientMessage(text, color, button)
end

addEvent("insertClientMessageFromServerSide", true)
addEventHandler("insertClientMessageFromServerSide", getRootElement(), insertClientMessageFromServerSide)

-- here is the test, to check it for yourself

addCommandHandler("testme", 
    function()
        insertClientMessage("This is a notficiation test with my new script, hello! :)", {224, 181, 204})
        insertClientMessage("To open the shop next to you", {30, 30, 30}, "E")
    end
)

-- the rendering phase, witch is responsible for the display on the screen
-- you can change the design here if you want

addEventHandler("onClientRender", getRootElement(), 
    function()
        for i = 1, #clientMessagesTable do
            if clientMessagesTable[i] then
                if clientMessagesTable[i]["animState"] == "open" then
                    clientMessagesTable[i]["alpha"] = interpolateBetween(
                        0, 0, 0, 
                        230, 0, 0, 
                        (getTickCount() - clientMessagesTable[i]["tick"]) / 500, 
                        "Linear"
                    )
        
                    if clientMessagesTable[i]["alpha"] == 230 then
                        setTimer(function()
                            clientMessagesTable[i]["tick"] = getTickCount()
                            clientMessagesTable[i]["animState"] = "hide"
                        end, 1000, 1)
                    end
                elseif clientMessagesTable[i]["animState"] == "hide" then
                    clientMessagesTable[i]["alpha"] = interpolateBetween(
                        235, 0, 0, 
                        0, 0, 0, 
                        (getTickCount() - clientMessagesTable[i]["tick"]) / 7500, 
                        "Linear"
                    )
        
                    if (clientMessagesTable[i]["alpha"] == 0) then
                        table.remove(clientMessagesTable, i)
                    end
                end
        
                if clientMessagesTable[i] then
                    local messageAlpha = clientMessagesTable[i]["alpha"]
                    local messageW, messageH = clientMessagesTable[i]["rectangleSize"], 30
                    local messageX, messageY = clientMessagesTable[i]["prompt"] and (screenX/2 - messageW/2) + 12.5 or screenX/2 - messageW/2, 0 + (i * (messageH + 2))
                    local color = tocolor(clientMessagesTable[i]["color"][1], clientMessagesTable[i]["color"][2], clientMessagesTable[i]["color"][3], messageAlpha)
                    local textColor = clientMessagesTable[i]["prompt"] and tocolor(200, 200, 200, messageAlpha) or tocolor(clientMessagesTable[i]["color"][1]/2, clientMessagesTable[i]["color"][2]/2, clientMessagesTable[i]["color"][3]/2, messageAlpha)

                    dxDrawRectangle(messageX, messageY, messageW, messageH, color)
                    dxDrawText(clientMessagesTable[i]["text"], messageX + messageW/2, messageY + messageH/2, messageX + messageW/2, messageY + messageH/2, textColor, 1, messageFont, "center", "center")

                    if clientMessagesTable[i]["prompt"] then
                        dxDrawRectangle(messageX - 25, messageY, 25, messageH, tocolor(200, 200, 200, messageAlpha))
                        dxDrawText(clientMessagesTable[i]["prompt"], messageX + 25/2 - 25, messageY + messageH/2, messageX + 25/2 - 25, messageY + messageH/2, tocolor(30, 30, 30, messageAlpha), 1.5, buttonFont, "center", "center")
                    end

                    if texture then
                        dxDrawImage(messageX, messageY, messageW, messageH, texture, 0, 0, 0, tocolor(0, 0, 0, messageAlpha/3))
                    end
                end
            end
        end
    end, true, "low-99999"
)
