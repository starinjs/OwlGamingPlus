function insertClientMessage(element, text, color, button)
    triggerClientEvent(element, "insertClientMessageFromServerSide", getRootElement(), text, color, button)
end