--[[
* ***********************************************************************************************************************
* Copyright (c) 2015 OwlGaming Community - All Rights Reserved
* All rights reserved. This program and the accompanying materials are private property belongs to OwlGaming Community
* Unauthorized copying of this file, via any medium is strictly prohibited
* Proprietary and confidential
* ***********************************************************************************************************************
]]
-- Production Server
production = (get( "production_server" ) == "1" or false)
socket = get( "socket" ) or ""

-- connection settings
hostname = get( "hostname" )
username = get( "username" )
password = get( "password" )
database = get( "database" )
port = tonumber( get( "port" ) )

local dbConn = nil

function createConnection(res)
	if not dbConn then
		dbConn = dbConnect("mysql","dbname=".. database ..";host="..hostname..";port="..port..";"..socket, username, password, "autoreconnect=1")
		if dbConn then
			if eventName then
				outputDebugString("[MYSQL] createConnection / "..database.." / OK")
			else
				connectToDatabase(res) -- Restart the connection for the MySQL Module
				outputDebugString("[MYSQL] reconnectConnection / "..database.." / OK")
			end
		else
			if eventName then
				cancelEvent(true, "Cannot connect to the database.")
				outputDebugString("[MYSQL] createConnection / "..database.." / FAILED")
			else
				outputDebugString("[MYSQL] reconnectConnection / "..database.." / FAILED")
			end
		end
		-- create the migrations table if it didn't already exist.
		createMigrationsTable()
	end

	if not eventName then
		return dbConn
	end
end
addEventHandler("onResourceStart", resourceRoot, createConnection)

function getConn()
	if isElement(dbConn) then
		return dbConn
	else
		return createConnection(false)
	end
end

function getSmallestID( table, index )
	index = index or 'id'
	return "(SELECT MIN(e1."..index.."+1) FROM "..table.." AS e1 LEFT JOIN "..table.." AS e2 ON e1."..index.." +1 = e2."..index.." WHERE e2."..index.." IS NULL)"
end