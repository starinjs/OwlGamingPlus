--[[
	Author: Fernando

	Discord Webhooks MTA Resource (Examples)

    Command: /testwebhooks [test ID]
]]

-- For these examples to work, you need to change the TEST_WEBHOOK_URL variable to a valid webhook URL.
local TEST_WEBHOOK_URL = "https://discord.com/api/webhooks/1074743328454754376/Yr6IjUUou90uqy9SHv-vuGuoRjp9pIWEqPwpP4ezwdva8jtsurc0bVBGqBSU83BQDOVu"

-- Webhook names are assigned to URLs in the WEB_HOOKS table located in config.lua
-- This will assign one on runtime, so you don't need to edit the config.lua file
WEB_HOOKS["test_webhook"] = TEST_WEBHOOK_URL

addEvent("testWebHook-result", false)
addEventHandler("testWebHook-result", root, function(info, player)
    if isElement(player) then
        outputChatBox("Webhook call "..(info.responseInfo.success and "#00ff00succeeded" or "#ff0000failed").." #fffffffor:", thePlayer, 255, 255, 255, true)
        outputChatBox((info.name or info.url), thePlayer, 187, 187, 187, true)
        if not info.responseInfo.success then
            outputChatBox("Check debug console for more info.", thePlayer, 255, 255, 255, true)
            iprint(info.responseData)
            iprint(info.responseInfo)
        end
    end
end, false)

local EXAMPLES = {
    --[[
        Sends a text message with some variables to the webhook
    ]]
    function(player, vehicleName, vehicleID)
        local request, failReason = exports.discord_webhooks:send(
            "test_webhook",
            "**"..getPlayerName(player).."** has created a `"..vehicleName.." (#"..vehicleID..")` at "..getElementZoneName(player)..".",
            {name="testWebHook-result", source=root, args={player}}
        )
        if not request then
            outputChatBox(tostring(failReason), player, 255, 0, 0)
        end
    end,

    --[[
        Converts an embed as a JSON object to a Lua table and sends it to the webhook
    ]]
    function(player)
        local JSON_RAW = '{"fields":[{"name":"aaaa","value":"eeeee","inline":false},{"name":"yyyyyyyyyyyyyy","value":"eeeeeeeeeeeeeee","inline":true},{"name":"xxxxxxxx","value":" sa asas sa as a","inline":false}],"title":"this is awesome lmao","author":{"name":"Nando","url":""},"color":2105893,"footer":{"text":"yeet"}}'
        local request, failReason = exports.discord_webhooks:sendToURL(
            TEST_WEBHOOK_URL,
            fromJSON(JSON_RAW),
            {name="testWebHook-result", source=root, args={player}}
        )
        if not request then
            outputChatBox(tostring(failReason), player, 255, 0, 0)
        end
    end,

    --[[
        Converts a JSON array containing several embed objects and a text content to a Lua table and sends it to the webhook
    ]]
    function(player)
        local JSON_RAW = '{"content":"You can even send some text along with ur embeds!","embeds":[{"fields":[{"name":"aaaa","value":"eeeee","inline":false},{"name":"yyyyyyyyyyyyyy","value":"eeeeeeeeeeeeeee","inline":true},{"name":"xxxxxxxx","value":" sa asas sa as a","inline":false}],"title":"this is awesome lmao","author":{"name":"Nando","url":""},"color":2105893,"footer":{"text":"yeet"}},{"fields":[{"name":"aaaa","value":"eeeee","inline":false},{"name":"cccccccccccccccccc","value":"eeeeeeeeeeeeeevvvvvvv","inline":true},{"name":"aaaaaaaaaaaa","value":"xxxsas sa as a","inline":false}],"title":"look at this, its sending 2 embeds!!!!","author":{"name":"Nando","url":""},"color":2105893,"footer":{"text":"yeet"}}]}'
        local request, failReason = exports.discord_webhooks:sendToURL(
            TEST_WEBHOOK_URL,
            fromJSON(JSON_RAW),
            {name="testWebHook-result", source=root, args={player}}
        )
        if not request then
            outputChatBox(tostring(failReason), player, 255, 0, 0)
        end
    end,

    --[[
        Tests if a message table is valid (POSSIBILITY #1)
    ]]
    function (player)
        local myMessage = {}
        myMessage.title = "Test"
        myMessage.description = "This is a test"
        myMessage.timestamp = "now"
        myMessage.color = tocolor(math.random(0, 255), math.random(0, 255), math.random(0, 255))
        local newMessage, failReason = exports.discord_webhooks:validateMessage(myMessage)
        if newMessage then
            outputChatBox("Message is valid!", player, 0, 255, 0)
        else
            outputChatBox("Message is invalid: "..tostring(failReason), player, 255, 0, 0)
        end
    end,

    --[[
        Tests if a message table is valid (POSSIBILITY #2)
    ]]
    function (player)
        local myMessage = {
            content = "I'm sending this text along with two embeds!!",
            embeds = {
                {
                    title = "1st Embed",
                    description = "This is a test",
                    timestamp = "now",
                    color = tocolor(math.random(0, 255), math.random(0, 255), math.random(0, 255))
                },
                {
                    title = "2nd Embed",
                    description = "This is a test",
                    timestamp = "now",
                    color = tocolor(math.random(0, 255), math.random(0, 255), math.random(0, 255))
                }
            }
        }
        local newMessage, failReason = exports.discord_webhooks:validateMessage(myMessage)
        if newMessage then
            outputChatBox("Message is valid!", player, 0, 255, 0)
        else
            outputChatBox("Message is invalid: "..tostring(failReason), player, 255, 0, 0)
        end
    end,

    --[[
        Tests if a message table is valid (POSSIBILITY #3)
    ]]
    function (player)
        local myMessage = {
            {
                title = "1st Embed",
                description = "This is a test",
                timestamp = "now",
                color = tocolor(math.random(0, 255), math.random(0, 255), math.random(0, 255))
            },
            {
                title = "2nd Embed",
                description = "This is a test",
                timestamp = "now",
                color = tocolor(math.random(0, 255), math.random(0, 255), math.random(0, 255))
            }
        }
        local newMessage, failReason = exports.discord_webhooks:validateMessage(myMessage)
        if newMessage then
            outputChatBox("Message is valid!", player, 0, 255, 0)
        else
            outputChatBox("Message is invalid: "..tostring(failReason), player, 255, 0, 0)
        end
    end,

    --[[
        Sends a simple text message to a webhook URL
    ]]
    function (player)
        local request, failReason = exports.discord_webhooks:sendToURL(
            TEST_WEBHOOK_URL,
            "HELLO!!!!"
        )
        if request then
            -- According to the wiki, you may use abortRemoteRequest(request) to cancel the request
            outputChatBox("Request sent successfully. Check debug console.", player, 0, 255, 0)
            iprint(request, getRemoteRequestInfo(request))
        else
            outputChatBox(tostring(failReason), player, 255, 0, 0)
        end
    end,

    --[[
        Sends a custom embed table to a webhook URL
    ]]
    function (player)
        local randColor = tocolor(math.random(0, 255), math.random(0, 255), math.random(0, 255))
        local request, failReason = exports.discord_webhooks:sendToURL(
            TEST_WEBHOOK_URL,
            {
                title = "Test",
                description = "This is a test",
                timestamp = "now",
                color = randColor,
                footer = {
                    text = "Footer text"
                },
                image = {
                    url = "https://i.imgur.com/bquJ4J9.png"
                },
                thumbnail = {
                    url = "https://i.imgur.com/v63JeLU.png"
                },
                video = {
                    url = "https://www.youtube.com/watch?v=CcCw1ggftuQ"
                },
                author = {
                    name = "Nando",
                    url = "https://github.com/Fernando-A-Rocha",
                    icon_url = "https://i.imgur.com/FA4tKt2.png"
                },
                url = "https://google.com",
                fields = {
                    {name="Field 1", value="Value 1"},
                    {name="Field 2", value="Value 2", inline=true},
                    {name="Field 3", value="Value 3", inline=true},
                }
            },
            {name="testWebHook-result", source=root, args={player}}
        )
        if not request then
            outputChatBox(tostring(failReason), player, 255, 0, 0)
        end
    end,
}

local function webHookExamples(thePlayer, cmd, id)
    local account = getPlayerAccount(thePlayer)
    if (isGuestAccount(account) or not isObjectInACLGroup("user."..getAccountName(account), aclGetGroup("Admin"))) then
        outputChatBox("You don't have permission to use this command.", thePlayer, 255, 0, 0)
        return
    end
    id = tonumber(id)
    if not id or not EXAMPLES[id] then
        outputChatBox("USAGE: /"..cmd.." [test ID]", thePlayer, 255, 255, 255)
        outputChatBox("   Test IDs: 1 to "..#EXAMPLES, thePlayer, 255, 255, 255)
        return
    end
    if id == 1 then
        EXAMPLES[id](thePlayer, "Landstalker", 400)
    else
        EXAMPLES[id](thePlayer)
    end
end
addCommandHandler("testwebhooks", webHookExamples, false, false)
