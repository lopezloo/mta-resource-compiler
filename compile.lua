if not hasObjectPermissionTo(getThisResource(), "function.fetchRemote") or not hasObjectPermissionTo(getThisResource(), "general.ModifyOtherObjects") then
	outputServerLog("ERROR: fetchRemote or ModifyOtherObjects disallowed. Please use \"aclrequest allow " .. getResourceName(getThisResource()) .. " all\" and restart resource.")
	return
end

local fileTypes = { "client", "server", "shared" }
local files = {
	client = {},
	server = {},
	shared = {}
}

compileSettings = {
	debug = 0,
	obfuscate = 1,
	encrypt = 1,
	extensionInput = ".lua",
	extensionOutput = ".luac",
}

local currentCompile = {
	resource,
	path,
}

function compileResource(resourceName)
	local metaNode = xmlLoadFile(":" .. resourceName .. "/meta.xml")
	if not metaNode then
		outputServerLog("ERROR: Can't load " .. resourceName .. " meta.")
		return
	end

	local time = getRealTime()
	currentCompile.path = "output/" .. resourceName .. " " .. time.monthday .. "." .. (time.month + 1) .. "." .. (time.year + 1900) .. " " .. time.hour .. "." .. time.minute .. "/"
	currentCompile.resource = resourceName

	for k, v in pairs( xmlNodeGetChildren(metaNode) ) do
		local src = xmlNodeGetAttribute(v, "src")
		if xmlNodeGetName(v) == "script" then
			if string.find(src, compileSettings.extensionInput) and not string.find(src, compileSettings.extensionOutput) then
				local scriptType = xmlNodeGetAttribute(v, "type") or "server"
				table.insert( files[ scriptType ], src )
			end

		elseif xmlNodeGetName(v) == "file" or xmlNodeGetName(v) == "map" then -- copying files/map
			local filepath = ":" .. resourceName .. "/" .. src

			if fileExists(filepath) then
				outputServerLog("Copying " .. src)
				fileCopy(filepath, currentCompile.path .. src, true)
			else
				outputServerLog("WARNING: File/map " .. src .. " doesn't exists.")
			end
		end
	end
	xmlUnloadFile(metaNode)

	compileCode(1, 1)
end

function onCodeCompiled(data, errno, typeID, id)
	local src = string.gsub(files[ fileTypes[typeID] ][id], compileSettings.extensionInput, "")
	local filepath = currentCompile.path .. src
	if errno == 0 then
		local file = fileCreate(filepath .. compileSettings.extensionOutput)
		fileWrite(file, data)
		fileClose(file)
	else
		outputServerLog("ERROR: Error compiling " .. filepath .. " (error " .. errno .. ").")
	end

	if id < #files[ fileTypes[typeID] ] then
		compileCode(typeID, id + 1)
	elseif typeID < #fileTypes then
		compileCode(typeID + 1, 1)
	else
		endCompiling()
	end
end

function endCompiling()
	-- copying meta
	local meta = fileOpen(":" .. currentCompile.resource .. "/meta.xml")
	local metaData = fileRead(meta, fileGetSize(meta))
	fileClose(meta)
	metaData = string.gsub(metaData, compileSettings.extensionInput .. '"', compileSettings.extensionOutput .. '"') -- changing old extensions in copied meta to new ones

	local copiedMeta = fileCreate(currentCompile.path .. "meta.xml")
	fileWrite(copiedMeta, metaData)
	fileFlush(copiedMeta)
	fileClose(copiedMeta)

	files = {
		client = {},
		server = {},
		shared = {}
	}

	outputServerLog("Compiled successfull.")
end

function compileCode(typeID, id)
	if #files[ fileTypes[typeID] ] == 0 then
		if typeID < #fileTypes then
			compileCode(typeID + 1, 1)
		else
			endCompiling()
		end
		return
	end

	outputServerLog("Compiling " .. tostring(files[ fileTypes[typeID] ][id]) )

	local file = fileOpen(":" .. currentCompile.resource .. "/" .. files[ fileTypes[typeID] ][id])
	local data = fileRead(file, fileGetSize(file))
	fileClose(file)
	fetchRemote("http://luac.mtasa.com/?compile=1&debug=" .. compileSettings.debug .. "&obfuscate=" .. compileSettings.obfuscate .. "&encrypt=" .. compileSettings.encrypt, onCodeCompiled, data, true, typeID, id)
end