local notallowed = { [509] = true, [481] = true, [510] = true, [462] = true, [448] = true, [581] = true, [522] = true,
	[461] = true, [521] = true, [523] = true, [463] = true, [586] = true, [468] = true, [471] = true, [431] = true, [437] = true }

function onVehicleEnter()
	local driver = getVehicleOccupant(source, 0)
	local passenger = getVehicleOccupant(source, 1)
	local alarmfound = true

	if notallowed[getElementModel(source)] then
		return
	end

	if getVehicleType(source) ~= "Automobile" then
		return
	end

	if not getVehicleEngineState(source) then
		return
	end

	if not (driver or passenger) then
		return
	end

	if (driver) then
		if (getElementData(driver, "seatbelt") == true and not passenger) or getElementType(driver) == "ped" then
			return
		end
	end
	if (passenger) then
		if (getElementData(passenger, "seatbelt") == true) or getElementType(passenger) == "ped" then
			if (driver) then
				if (getElementData(driver, "seatbelt") == true) or getElementType(driver) == "ped" then
					return
				end
			end
		end
	end

	if (alarmfound) then
		triggerClientEvent("startSeatBeltWarning", source)
	end
end

addEventHandler("onVehicleEnter", getRootElement(), onVehicleEnter)
addEvent("onVehicleSeatbeltWarning", true)
addEventHandler("onVehicleSeatbeltWarning", getRootElement(), onVehicleEnter)

function checkData(dataName, _)
	if getElementType(source) == "vehicle" then
		if dataName == "engine" then
			if getElementData(source, "engine") == 1 then
				triggerEvent("onVehicleSeatbeltWarning", source)
			end
		end
	elseif getElementType(source) == "player" then
		if dataName == "seatbelt" then
			local vehicle = getPedOccupiedVehicle(source)
			if not getElementData(source, "seatbelt") then
				if vehicle then
					triggerEvent("onVehicleSeatbeltWarning", vehicle)
				end
			end
		end
	end
end

addEventHandler("onElementDataChange", getRootElement(), checkData)
