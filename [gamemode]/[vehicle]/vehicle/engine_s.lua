local function batteryExceptions( veh )
	return ( ( getElementData(veh, 'job') or 0 ) ~= 0 ) or getVehicleType( veh ) == 'Plane'
end

local startings = {}

function startEngine( player, veh )
	if not startings[veh] or getTickCount() - startings[veh] > 5000 then
		startings[veh] = getTickCount()
		local status = "ok"

		if ((getElementData( veh, "battery" ) or 100) > 0) or batteryExceptions( veh ) then
			if exports.global:hasItem( veh, 74 ) then
				status = "bomb"
			elseif ( getElementData( veh, 'enginebroke' ) or 0 ) == 1 then
				status = "enginebroke"
			elseif ( getElementData( veh, "fuel") or 0 ) == 0 then
				status = "nofuel"
			elseif getElementData(veh, "hotwired") then
				status = "hotwired"
			end
		else
			exports.hud:sendBottomNotification( player, exports.global:getVehicleName( veh ), "Battery died." )
			triggerEvent('sendAme', player, "attempts to start the engine but fails.")
			return
		end

		if status == "ok" or status == "hotwired" then
			setVehicleEngineState( veh, true )
			exports.anticheat:setEld( veh, "engine", 1 )

			toggleControl(player, "accelerate", true)
			toggleControl(player, "brake_reverse", true)

			local vid = getElementData( veh, "dbid" )
			if vid > 0 then
				exports.anticheat:setEld( veh, "lastused", exports.datetime:now(), "all" )
				dbExec( exports.mysql:getConn(), "UPDATE vehicles SET lastUsed=NOW() WHERE id=?", vid )
			end

			triggerEvent("sendAme", player, "starts the vehicle's engine.")

		else
			setTimer(function ()
				if status == "bomb" then
					blowVehicle(veh)
				elseif status == "enginebroke" then
					exports.hud:sendBottomNotification( player, exports.global:getVehicleName( veh ), "Engine is broken." )
				elseif status == "nofuel" then
					exports.hud:sendBottomNotification( player, exports.global:getVehicleName( veh ), "Fuel tank is empty." )
				end
			end, 1500, 1)
		end
	end
end
addEvent( "vehicle:engine:start", true )
addEventHandler( "vehicle:engine:start", resourceRoot, startEngine )

function stopEngine( veh, player )
	setVehicleEngineState( veh, false )
	exports.anticheat:setEld( veh, "engine", 0 )
	if player then
		toggleControl(player, "accelerate", false)
		toggleControl(player, "brake_reverse", false)
	end
end
addEvent( "vehicle:engine:stop", true )
addEventHandler( "vehicle:engine:stop", resourceRoot, stopEngine )