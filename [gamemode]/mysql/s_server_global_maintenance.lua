--MAXIME
local timer = nil
local serverMaintenancePassword = nil

-- Function to generate a random password
function generateRandomPassword(length)
    local chars = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
    local password = ""
    for i = 1, length do
        local randomIndex = math.random(1, #chars)
        password = password .. string.sub(chars, randomIndex, randomIndex)
    end
    return password
end

function startWarnings()
    local message = "[SYSTEM] Server is about to shutdown for daily backup & maintenance. Please finish what you're doing then proceed to logout before getting auto-kicked by the system, this is to ensure the data consistence for your account before backup processes start. It could take up to 1 hour and server will be back online again automatically! We're sorry for the inconvenience." 
    local players = exports.pool:getPoolElementsByType("player")
    for k, arrayPlayer in ipairs(players) do
        triggerClientEvent(arrayPlayer,"announcement:post", arrayPlayer, message, 255, 0, 0, 1)
    end
    outputConsole(message)
end

function startKicking()
    -- Generate a random password
    serverMaintenancePassword = generateRandomPassword(16)

    local players = exports.pool:getPoolElementsByType("player")
    for k, arrayPlayer in ipairs(players) do
        kickPlayer(arrayPlayer, "Server daily backup & maintenance")
    end
    
    if not getServerPassword() then
        setServerPassword(serverMaintenancePassword)
    end
    
    -- Send the maintenance password to Discord webhook
    local webhookMessage = "Server is now in maintenance mode. Temporary password: " .. serverMaintenancePassword
    exports.discord_webhooks:send("manager-webhook", webhookMessage)
end

addEventHandler("onResourceStart", resourceRoot, function()
    -- Seed the random number generator
    math.randomseed(getTickCount())
    
    if getServerPassword() then
        setServerPassword('')
    end
    
    timer = setTimer(function()
        local serverTime = getRealTime()
        --outputDebugString(serverTime.hour)
        --outputDebugString(serverTime.minute)
        if serverTime.hour == 6 then
            if serverTime.minute >= 53 then
                if serverTime.minute <=58 then
                    startWarnings()
                else
                    startKicking()
                    killTimer(timer)
                end
            end
        end
    end, 60000, 0)
end)