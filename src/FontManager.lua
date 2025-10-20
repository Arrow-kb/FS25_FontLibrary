FontManager = {}


local FontManager_mt = Class(FontManager)
local modDirectory = g_currentModDirectory


local closestCharacters = {
	[163] = 36,
	[8364] = 36,
	[192] = 65,
	[193] = 65,
	[194] = 65,
	[195] = 65,
	[196] = 65,
	[199] = 67,
	[200] = 69,
	[201] = 69,
	[202] = 69,
	[203] = 69,
	[204] = 73,
	[206] = 73,
	[207] = 73,
	[210] = 79,
	[212] = 79,
	[214] = 79,
	[219] = 85,
	[220] = 85,
	[224] = 97,
	[226] = 97,
	[227] = 97,
	[228] = 97,
	[231] = 99,
	[232] = 101,
	[233] = 101,
	[234] = 101,
	[235] = 101,
	[237] = 105,
	[238] = 105,
	[239] = 105,
	[241] = 110,
	[243] = 111,
	[244] = 111,
	[245] = 111,
	[246] = 111,
	[250] = 117,
	[251] = 117,
	[252] = 117
}


function FontManager.new()

	local self = setmetatable({}, FontManager_mt)

	self.fonts = {}
	self.defaultFont = "arial"
	self.missingFonts = {}
	self.cache2D = {}
	self.cache3D = {}
	self.cachedOverlays = {}

	self.args = {
		["colour"] = { 1, 1, 1, 1 },
		["bold"] = false,
		["alignX"] = RenderText.ALIGN_LEFT,
		["alignY"] = RenderText.VERTICAL_ALIGN_MIDDLE,
		["font"] = self.defaultFont
	}

	self:replaceEngineFunctions()
	self:loadFonts()

	return self

end


function FontManager:replaceEngineFunctions()

	local engine = {
		["renderText3D"] = renderText3D,
		["renderText"] = renderText,
		["setTextBold"] = setTextBold,
		["setTextColor"] = setTextColor,
		["setTextAlignment"] = setTextAlignment,
		["setTextVerticalAlignment"] = setTextVerticalAlignment,
		["draw"] = draw
	}

	
	draw = function()

		for _, cache in pairs(self.cache3D) do cache.delete = true end
		for _, cache in pairs(self.cache2D) do cache.delete = true end

		engine.draw()

		for i = #self.cache3D, 1, -1 do

			if self.cache3D[i].delete then
				delete(self.cache3D[i].node)
				table.remove(self.cache3D, i)
			end

		end

		for i = #self.cache2D, 1, -1 do
		
			local cache = self.cache2D[i]

			if cache.delete then
				for _, overlay in pairs(cache.overlays) do table.insert(self.cachedOverlays, overlay) end
				table.remove(self.cache2D, i)
			end

		end

	end


	setTextColor = function(r, g, b, a)

		self.args.colour = { r, g, b, a } or { 1, 1, 1, 1 }
		engine.setTextColor(r, g, b, a)

	end


	setTextBold = function(isBold)

		self.args.bold = isBold
		engine.setTextBold(isBold)

	end


	setTextAlignment = function(value)

		self.args.alignX = value
		engine.setTextAlignment(value)

	end

	setTextFont = function(fontName)

		if fontName == nil or self.fonts[fontName] == nil then
			self.args.font = self.defaultFont
		else
			self.args.font = fontName
		end

	end


	setTextItalic = function(isItalic)

		self.args.italic = isItalic or false

	end


	setTextUnderlined = function(isUnderlined)

		self.args.underline = isUnderlined or false

	end


	setTextStrikethrough = function(isStrikethrough)

		self.args.strikethrough = isStrikethrough or false

	end


	setTextVerticalAlignment = function(value)

		self.args.alignY = value
		engine.setTextVerticalAlignment(value)

	end


	renderText3D = function(x, y, z, rx, ry, rz, size, text, fontName)

		fontName = fontName or self.defaultFont

		if self.fonts[fontName] == nil then
			
			if self.missingFonts[fontName] == nil then
				self.missingFonts[fontName] = true
				Logging.error(string.format("FontLibrary - requested font \'%s\' not found (renderText3D)", fontName))
				printCallstack()
			end

			fontName = self.defaultFont

		end


		local args = self.args
		local variationName = "regular"

		if args.bold and args.italic then
			variationName = "boldItalic"
		elseif args.bold then
			variationName = "bold"
		elseif args.italic then
			variationName = "italic"
		end

		for _, cache in pairs(self.cache3D) do

			if cache.x == x and cache.y == y and cache.z == z and cache.rx == rx and cache.ry == ry and cache.rz == rz and cache.size == size and cache.text == text and cache.fontName == fontName then
				cache.delete = false
				return
			end

		end

		local node = clone(self.text, true, false, false)
		setVisibility(node, true)
		
		setTranslation(node, 0.25 * size, 0, 0)
		setWorldTranslation(node, x, y, z)
		setWorldRotation(node, rx, ry, rz)

		local font = self.fonts[fontName]
		local variationNode = font.nodes[variationName]
		local xOffset, yOffset = 0, 0

		local colour = args.colour
		setScale(node, size, size, 0)

		for i = 1, #text do

			local character = self:getCharacter(font, string.sub(text, i, i))

			if character == nil then
				xOffset = xOffset + 0.5
				continue
			end

			local charNode = clone(variationNode, false, false, false)
			link(node, charNode)

			setShaderParameter(charNode, "index", character.index, nil, nil, nil, false)
			setShaderParameter(charNode, "colorScale", colour[1], colour[2], colour[3], colour[4], false)

			setTranslation(charNode, xOffset, 0, 0)
			xOffset = xOffset + character:getVariation(variationName).width / 128

		end

		table.insert(self.cache3D, {
			["delete"] = false,
			["node"] = node,
			["x"] = x,
			["y"] = y,
			["z"] = z,
			["rx"] = rx,
			["ry"] = ry,
			["rz"] = rz,
			["size"] = size,
			["text"] = text,
			["fontName"] = fontName
		})

	end

	local isLoading = g_gameStateManager:getGameState() == GameState.LOADING

	renderText = function(x, y, size, text, fontName)

		if isLoading then

			isLoading = false
			g_mpLoadingScreen.balanceText:setText(g_i18n:formatMoney(g_mpLoadingScreen.missionInfo.money or g_mpLoadingScreen.missionInfo.initialMoney))

		end

		fontName = fontName or self.args.font or self.defaultFont
		
		if self.fonts[fontName] == nil then
			
			if self.missingFonts[fontName] == nil then
				self.missingFonts[fontName] = true
				Logging.error(string.format("FontLibrary - requested font \'%s\' not found (renderText)", fontName))
				printCallstack()
			end

			fontName = self.defaultFont

		end

		local args = self.args
		local variationName = "regular"

		if args.bold and args.italic then
			variationName = "boldItalic"
		elseif args.bold then
			variationName = "bold"
		elseif args.italic then
			variationName = "italic"
		end
	
		local overlays

		for _, cache in pairs(self.cache2D) do

			if cache.x == x and cache.y == y and cache.size == size and cache.text == text and cache.fontName == fontName then
				cache.delete = false
				overlays = cache.overlays
				break
			end

		end
		
		local args = self.args
		local scale = size * 10

		if overlays == nil then

			overlays = {}

			local font = self.fonts[fontName]
			local width, height = size, size
			local xOffset = 0

			if args.alignY == RenderText.VERTICAL_ALIGN_BASELINE then
				-- ?
			elseif args.alignY == RenderText.VERTICAL_ALIGN_TOP then
				y = y + size
			elseif args.alignY == RenderText.VERTICAL_ALIGN_MIDDLE then
				
			elseif args.alignY == RenderText.VERTICAL_ALIGN_BOTTOM then
				y = y - size
			end

			local sizePixels = size * g_referenceScreenWidth * g_aspectScaleX


			local function writeCharacter(character, variation, posX)

				local overlay

				if #self.cachedOverlays > 0 then
					overlay = self.cachedOverlays[1]
					table.remove(self.cachedOverlays, 1)
				else
					overlay = Overlay.new()
				end
			
				overlay:setImage(font.variations[variationName])
				overlay:setDimension(variation.screenWidth * scale, variation.screenHeight * scale)
				overlay:setPosition(posX, y)
				overlay:setUVs(variation.uvs)

				table.insert(overlays, overlay)

			end
		
			if args.alignX ~= RenderText.ALIGN_LEFT then

				local textWidth = 0

				for i = 1, #text do

					local character = self:getCharacter(font, string.sub(text, i, i))

					if character == nil then
						textWidth = textWidth + size * 0.25
						continue
					end

					local variation = character:getVariation(variationName)
					textWidth = textWidth + variation.screenWidth * scale

				end

				if args.alignX == RenderText.ALIGN_CENTER then
					x = x - textWidth / 2
				elseif args.alignX == RenderText.ALIGN_RIGHT then
					x = x - textWidth
				end

			end

			for i = 1, #text do

				local character = self:getCharacter(font, string.sub(text, i, i))

				if character == nil then
					xOffset = xOffset + size * 0.25
					continue
				end

				local variation = character:getVariation(variationName)
				writeCharacter(character, variation, x + xOffset)
				xOffset = xOffset + variation.screenWidth * scale

			end


			table.insert(self.cache2D, {
				["delete"] = false,
				["overlays"] = overlays,
				["x"] = x,
				["y"] = y,
				["size"] = size,
				["text"] = text,
				["fontName"] = fontName
			})

		end

		if overlays == nil then return end

		local colour = args.colour

		for _, overlay in pairs(overlays) do
			overlay:setColor(colour[1], colour[2], colour[3], colour[4])
			overlay:render()
		end

	end

end


function FontManager:loadFonts()

	self.fontHolder = g_i3DManager:loadI3DFile(modDirectory .. "fonts/fontHolder.i3d")
	self.template = I3DUtil.indexToObject(self.fontHolder, "0|0")

	self.text = g_i3DManager:loadI3DFile(modDirectory .. "fonts/text.i3d")
	self.textGroup = createTransformGroup("fontLibrary_texts")

	link(getRootNode(), self.textGroup)
	link(self.textGroup, self.text)

	setVisibility(self.text, false)
	setVisibility(self.fontHolder, false)

	self:loadFontsFromXMLFile(modDirectory .. "fonts/fonts.xml", modDirectory)

end


function FontManager:loadFontsFromXMLFile(xmlPath, directory)

	local xmlFile = XMLFile.loadIfExists("fontsXML", xmlPath)
	local fontIds = {}

	if xmlFile == nil then return fontIds end

	xmlFile:iterate("fonts.font", function(_, key)

		local path = directory .. xmlFile:getString(key .. "#path")
		local fontXML = XMLFile.loadIfExists("fontXML", path .. "font.xml")

		if fontXML == nil then
			fontXML = XMLFile.loadIfExists("fontXML", path .. "/font.xml")
			path = path .. "/"
		end

		if fontXML ~= nil then
		
			local id, name = self:loadFont(fontXML, "font", path)
			fontIds[name] = id
			fontXML:delete()

		end

	end)

	xmlFile:delete()

	if self.settingsManager ~= nil then self.settingsManager.reloadFonts() end
	if self.fontViewerDialog ~= nil then self.fontViewerDialog:reloadFonts() end

	return fontIds

end


function FontManager:loadFont(xmlFile, key, directory)

	local transformGroup = clone(self.template, true, false, false)

	local name = xmlFile:getString(key .. "#name")
	local id, i = name, 0

	while self.fonts[id] ~= nil do

		i = i + 1
		id = name .. "_" .. i

	end

	setName(transformGroup, id)
	
	local font = {
		["name"] = name,
		["id"] = id,
		["nodes"] = {},
		["width"] = xmlFile:getInt(key .. "#width", 64),
		["height"] = xmlFile:getInt(key .. "#height", 4),
		["variations"] = {
			["regular"] = string.format("%s%s.dds", directory, name),
			["bold"] = string.format("%s%sBold.dds", directory, name),
			["italic"] = string.format("%s%sItalic.dds", directory, name),
			["boldItalic"] = string.format("%s%sBoldItalic.dds", directory, name)
		},
		["characters"] = {}
	}

	local files = {
		["regular"] = string.format("%s%s_alpha.dds", directory, name),
		["bold"] = string.format("%s%sBold_alpha.dds", directory, name),
		["italic"] = string.format("%s%sItalic_alpha.dds", directory, name),
		["boldItalic"] = string.format("%s%sBoldItalic_alpha.dds", directory, name)
	}


	local templateNode = getChild(transformGroup, "template")


	for variation, file in pairs(files) do

		local node = clone(templateNode, true, false, false)

		setName(node, variation)

		local material = setMaterialCustomMapFromFile(getMaterial(node, 0), "alphaMap", file, false, true, false)
		setMaterial(node, material, 0)
		setShaderParameter(node, "widthAndHeight", font.width, font.height, nil, nil, false)

		font.nodes[variation] = node

	end

	xmlFile:iterate(key .. ".character", function(_, charKey)
		
		local character = FontCharacter.new(font, spacing)

		character:loadFromXMLFile(xmlFile, charKey)

		font.characters[character.byte] = character
		
	end)

	self.fonts[id] = font

	if self.settingsManager ~= nil then self.settingsManager.addFont(id, name) end
	if self.fontViewerDialog ~= nil then self.fontViewerDialog:addFont(id, name) end

	print(string.format("FontLibrary - Loaded font \'%s\' (%s)", name, id))

	return id, name

end


function FontManager:setSettingsManager(manager)

	self.settingsManager = manager

	for id, font in pairs(self.fonts) do manager.addFont(id, font.name) end

	manager.reloadFonts()

end


function FontManager:setFontViewerDialog(dialog)

	self.fontViewerDialog = dialog

	for id, font in pairs(self.fonts) do dialog:addFont(id, font.name) end

	dialog:reloadFonts()

end


function FontManager:setDefaultFont(id)

	self.defaultFont = id or self.defaultFont

end


function FontManager:getCharacter(font, character)

	local byte = string.byte(character)

	if font.characters[byte] ~= nil then return font.characters[byte] end
	if closestCharacters[byte] ~= nil then return font.characters[closestCharacters[byte]] end

	byte = string.byte(character:upper())

	if font.characters[byte] ~= nil then return font.characters[byte] end
	if closestCharacters[byte] ~= nil then return font.characters[closestCharacters[byte]] end

	return nil

end


g_fontManager = FontManager.new()