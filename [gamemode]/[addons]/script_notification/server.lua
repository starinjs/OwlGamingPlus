--[[ 
Enhanced Notification System - Server Side
Originally created by Tobzoska, enhanced version with notification limits
Free for use by everyone

SERVER SIDE USAGE:
Regular notification: exports.script_notification:showNotification(element, "Hello there!", {200, 200, 200})
Prompt notification: exports.script_notification:showNotification(element, "Pick up item", {200, 200, 200}, "E")
]]

-- Main function to show a notification to a specific client
function showNotification(element, text, color, button)
    if not isElement(element) or not text then
        return false
    end
    
    triggerClientEvent(element, "insertClientMessageFromServerSide", getRootElement(), text, color, button)
    return true
end

-- Maintain backward compatibility
function insertClientMessage(element, text, color, button)
    return showNotification(element, text, color, button)
end

-- Export the function for external use
exports.script_notification = {}
exports.script_notification.showNotification = showNotification
exports.script_notification.insertClientMessage = insertClientMessage