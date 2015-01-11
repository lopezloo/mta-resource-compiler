addCommandHandler("compile", 
	function(player, cmd, resourceName)
		if hasObjectPermissionTo(player, "general.ModifyOtherObjects") then
			if getResourceFromName(resourceName) then
				compileResource(resourceName)
			else
				outputServerLog("ERROR: Resource doesn't exist.")
			end
		end
	end
)

addCommandHandler("setting",
	function(player, cmd, setting, value)
		if hasObjectPermissionTo(player, "general.ModifyOtherObjects") then
			if compileSettings[setting] then
				if value == "0" or value == "1" or setting == "extensionInput" or setting == "extensionOutput" then
					compileSettings[setting] = value
					outputServerLog("Setting changed.")
				else
					outputServerLog("ERROR: Wrong value.")
				end
			else
				outputServerLog("ERROR: This setting doesn't exist (you can change: debug, obfuscate, blockdecompile, encrypt, extensionInput, extensionOutput).")
			end
		end
	end
)

addCommandHandler("showsettings",
	function(player)
		if hasObjectPermissionTo(player, "general.ModifyOtherObjects") then
			outputServerLog("Compile settings:")
			for k, v in pairs(compileSettings) do
				outputServerLog(k .. " = " .. v)
			end
		end
	end
)