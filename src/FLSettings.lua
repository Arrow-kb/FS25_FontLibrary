FLSettings = {}

local modDirectory = g_currentModDirectory
local modName = g_currentModName
local modSettingsDirectory = g_currentModSettingsDirectory

g_gui:loadProfiles(modDirectory .. "gui/guiProfiles.xml")


function FLSettings.onFontChanged()

	local setting = FLSettings.SETTINGS.font
	local font = setting.values[setting.element:getState()]

	setting.element:getDescendantByName("text"):setTextFont(font)
	setting.element.elements[1]:setTextFont(font)

end


function FLSettings.applyFont()

	local setting = FLSettings.SETTINGS.font
	g_fontManager:setDefaultFont(setting.values[setting.element:getState()])

end


function FLSettings.onClickViewFonts()

	FontViewerDialog.show()

end


FLSettings.SETTINGS = {

	["font"] = {
		["index"] = 1,
		["type"] = "MultiTextOption",
		["default"] = 1,
		["valueType"] = "literal",
		["texts"] = {},
		["values"] = {},
		["callback"] = FLSettings.onFontChanged
	},

	["viewFonts"] = {
		["index"] = 2,
		["type"] = "Button",
		["ignore"] = true,
		["callback"] = FLSettings.onClickViewFonts
	},

	["sizeScale"] = {
		["index"] = 3,
		["type"] = "MultiTextOption",
		["default"] = 12,
		["valueType"] = "float",
		["values"] = { 0, 0.1, 0.2, 0.3, 0.4, 0.5, 0.6, 0.7, 0.8, 0.9, 1, 1.1, 1.2, 1.3, 1.4, 1.5, 1.6, 1.7, 1.8, 1.9, 2.0 },
		["callback"] = FontManager.onSettingChanged
	},
	
	["render2D"] = {
		["index"] = 4,
		["type"] = "BinaryOption",
		["dynamicTooltip"] = true,
		["default"] = 1,
		["binaryType"] = "offOn",
		["values"] = { false, true },
		["callback"] = FontManager.onSettingChanged
	},
	
	["render3D"] = {
		["index"] = 5,
		["type"] = "BinaryOption",
		["dynamicTooltip"] = true,
		["default"] = 2,
		["binaryType"] = "offOn",
		["values"] = { false, true },
		["callback"] = FontManager.onSettingChanged
	}

}

FLSettings.BinaryOption = nil
FLSettings.MultiTextOption = nil
FLSettings.Button = nil


function FLSettings.loadFromXMLFile()

	local path = modSettingsDirectory .. "settings.xml"
	local xmlFile = XMLFile.loadIfExists("flSettings", path)

	if xmlFile ~= nil then

		local key = "settings"
			
		for name, setting in pairs(FLSettings.SETTINGS) do

			if setting.ignore then continue end

			if name == "font" then
				FLSettings.fontId = xmlFile:getString(key .. ".font#value", g_fontManager.defaultFont)
				setting.state = 1
			else
				setting.state = xmlFile:getInt(key .. "." .. name .. "#value", setting.default)
			end

			if setting.state > #setting.values then setting.state = #setting.values end

		end

		xmlFile:delete()

	end

end


function FLSettings.saveToXMLFile(name, state)

	if FLSettings.isSaving then return end

	FLSettings.isSaving = true

	createFolder(modSettingsDirectory)
	local path = modSettingsDirectory .. "settings.xml"
	local xmlFile = XMLFile.create("flSettings", path, "settings")

	if xmlFile ~= nil then

		for settingName, setting in pairs(FLSettings.SETTINGS) do

			if setting.ignore then continue end

			if settingName == "font" then
				xmlFile:setString("settings.font#value", setting.values[setting.state] or g_fontManager.defaultFont)
			else
				xmlFile:setInt("settings." .. settingName .. "#value", setting.state or setting.default)
			end

		end

		local saved = xmlFile:save(false, true)

		xmlFile:delete()

	end

	FLSettings.isSaving = false

end


function FLSettings.initialize()

	FLSettings.loadFromXMLFile()

	local settingsPage = g_inGameMenu.pageSettings
	local scrollPanel = settingsPage.gameSettingsLayout

	local sectionHeader, binaryOptionElement, multiOptionElement, buttonElement

	for _, element in pairs(scrollPanel.elements) do

		if element.name == "sectionHeader" and sectionHeader == nil then sectionHeader = element:clone(scrollPanel) end

		if element.typeName == "Bitmap" then

			if element.elements[1].typeName == "BinaryOption" and binaryOptionElement == nil then binaryOptionElement = element end

			if element.elements[1].typeName == "MultiTextOption" and multiOptionElement == nil then multiOptionElement = element end

			if element.elements[1].typeName == "Button" and buttonElement == nil then buttonElement = element end

		end

		if multiOptionElement and binaryOptionElement and sectionHeader and buttonElement then break end	

	end

	if multiOptionElement == nil or binaryOptionElement == nil or sectionHeader == nil or buttonElement == nil then return end

	FLSettings.BinaryOption = binaryOptionElement
	FLSettings.MultiTextOption  = multiOptionElement
	FLSettings.Button = buttonElement

	local prefix = "fl_settings_"

	sectionHeader:setText(g_i18n:getText("fl_settings"))

	local maxIndex = 0

	for _, setting in pairs(FLSettings.SETTINGS) do maxIndex = maxIndex < setting.index and setting.index or maxIndex end

	for i = 1, maxIndex do

		for name, setting in pairs(FLSettings.SETTINGS) do

			if setting.index ~= i then continue end
	
			setting.state = setting.state or setting.default
			local template = FLSettings[setting.type]:clone(scrollPanel)
			local settingsPrefix = "fl_settings_" .. name .. "_"
			template.id = nil
		
			for _, element in pairs(template.elements) do

				if element.typeName == "Text" then
					element:setText(g_i18n:getText(settingsPrefix .. "label"))
					element.id = nil
				end

				if element.typeName == setting.type then

					if setting.type == "Button" then
						element:setText(g_i18n:getText(settingsPrefix .. "text"))
						element:applyProfile("fl_settingsButton")
						element.isAlwaysFocusedOnOpen = false
						element.focused = false
					else

						local texts = {}

						if setting.binaryType == "offOn" then
							texts[1] = g_i18n:getText("fl_settings_off")
							texts[2] = g_i18n:getText("fl_settings_on")
						else

							for i, value in pairs(setting.values) do

								if setting.valueType == "int" then
									texts[i] = tostring(value)
								elseif setting.valueType == "float" then
									texts[i] = string.format("%.0f%%", value * 100)
								elseif setting.valueType == "literal" then
									texts[i] = setting.texts[i]
								else
									texts[i] = g_i18n:getText(settingsPrefix .. "texts_" .. i)
								end
							end

						end

						element:setTexts(texts)
						element:setState(setting.state)

						if setting.dynamicTooltip then
							element.elements[1]:setText(g_i18n:getText(settingsPrefix .. "tooltip_" .. setting.state))
						else
							element.elements[1]:setText(g_i18n:getText(settingsPrefix .. "tooltip"))
						end

					end

					element.id = "fls_" .. name
					element.onClickCallback = FLSettings.onSettingChanged

					setting.element = element

					if setting.dependancy then
						local dependancy = FLSettings.SETTINGS[setting.dependancy.name]
						if dependancy ~= nil and dependancy.element ~= nil then element:setDisabled(dependancy.state ~= setting.dependancy.state) end
					end

				end
			
			end

		end

	end

	g_fontManager:setSettingsManager(FLSettings)
	FLSettings.applyDefaultSettings()

end


function FLSettings.onSettingChanged(_, state, button)

	if button == nil then button = state end

	if button == nil or button.id == nil then return end

	if not string.contains(button.id, "fls_") then return end

	local name = string.sub(button.id, 5)
	local setting = FLSettings.SETTINGS[name]

	if setting == nil then return end

	if setting.ignore then
		if setting.callback then setting.callback() end
		return
	end

	if setting.callback then setting.callback(name, setting.values[state]) end

	setting.state = state

	for _, s in pairs(FLSettings.SETTINGS) do
		if s.dependancy and s.dependancy.name == name then
			s.element:setDisabled(s.dependancy.state ~= state)
		end
	end

	if setting.dynamicTooltip and setting.element ~= nil then setting.element.elements[1]:setText(g_i18n:getText("fl_settings_" .. name .. "_tooltip_" .. setting.state)) end

	if g_server ~= nil then

		--FLSettings.saveToXMLFile(name, state)

	else

		--FLSettings.sendEvent(name)

	end

end


function FLSettings.addFont(id, name)

	local setting = FLSettings.SETTINGS.font
	local formattedName = string.gsub(name, "_", " ")

	table.insert(setting.values, id)
	table.insert(setting.texts, formattedName)

end


function FLSettings.reloadFonts()

	local setting = FLSettings.SETTINGS.font
	local element = setting.element

	local currentIndex = 1

	for index, id in pairs(setting.values) do

		if id == FLSettings.fontId then
			currentIndex = index
			break
		end

	end

	element:setTexts(setting.texts)
	element:setState(currentIndex)

	g_fontManager:setDefaultFont(FLSettings.fontId)

end


function FLSettings.applyDefaultSettings()

	if g_server == nil then

		--RL_BroadcastSettingsEvent.sendEvent()

	else

		for name, setting in pairs(FLSettings.SETTINGS) do
		
			if setting.ignore or name == "font" then continue end

			if setting.callback ~= nil then setting.callback(name, setting.values[setting.state]) end

			if setting.dynamicTooltip and setting.element ~= nil then setting.element.elements[1]:setText(g_i18n:getText("fl_settings_" .. name .. "_tooltip_" .. setting.state)) end

			for _, s in pairs(FLSettings.SETTINGS) do
				if s.dependancy and s.dependancy.name == name and s.element ~= nil then
					s.element:setDisabled(s.dependancy.state ~= state)
				end
			end
		end

	end

end

FLSettings.initialize()