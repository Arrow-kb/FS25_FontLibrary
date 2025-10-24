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
	self.defaultFont = "nunito_sans"
	self.missingFonts = {}
	self.cache2D = {}
	self.cache3D = {}
	self.cache3DLinked = {}
	self.cachedOverlays = {}
	self.cachedLineOverlays = {}

	self.args = {
		["colour"] = { 1, 1, 1, 1 },
		["bold"] = false,
		["italic"] = false,
		["underline"] = false,
		["strikethrough"] = false,
		["useEngineRenderer"] = false,
		["alignX"] = RenderText.ALIGN_LEFT,
		["alignY"] = RenderText.VERTICAL_ALIGN_MIDDLE,
		["font"] = self.defaultFont,
		["clip"] = { 0, 0, 1, 1 },
		["lines"] = {
			["indentation"] = 0,
			["width"] = 0,
			["startLine"] = 0,
			["numLines"] = 0,
			["heightScale"] = RenderText.DEFAULT_LINE_HEIGHT_SCALE
		}
	}

	local _, yOffsetBaseline = getNormalizedScreenValues(0, 8)
	local _, yOffsetMiddle = getNormalizedScreenValues(0, 64)

	self.yOffset = {
		["baseline"] = yOffsetBaseline,
		["middle"] = yOffsetMiddle
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

				for _, line in pairs(cache.lines) do

					if line.underline ~= nil then table.insert(self.cachedLineOverlays, line.underline) end
					if line.strikethrough ~= nil then table.insert(self.cachedLineOverlays, line.strikethrough) end

				end

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


	setTextClipArea = function(x1, y1, x2, y2)

		self.args.clip = { x1, y1, x2, y2 }

	end


	setTextFirstLineIndentation = function(indentation)

		self.args.lines.indentation = indentation or 0

	end


	setTextWrapWidth = function(width)

		self.args.lines.width = width or 0

	end


	setTextLineBounds = function(startLine, numLines)

		self.args.lines.startLine = startLine
		self.args.lines.numLines = numLines

	end


	setTextLineHeightScale = function(heightScale)

		self.args.lines.heightScale = heightScale or 0

	end


	setTextUseEngineRenderer = function(useEngineRenderer)

		self.args.useEngineRenderer = useEngineRenderer

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


	create3DLinkedText = function(parent, x, y, z, rx, ry, rz, size, text, fontName)

		fontName = fontName or self.defaultFont

		if self.fonts[fontName] == nil then
			
			if self.missingFonts[fontName] == nil then
				self.missingFonts[fontName] = true
				Logging.error(string.format("FontLibrary - requested font \'%s\' not found (create3DLinkedText)", fontName))
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

		local node = clone(self.text, false, false, false)
		link(parent, node)
		setVisibility(node, true)

		setTranslation(node, x + 0.25 * size, y, z)
		setRotation(node, rx, ry + math.pi / 2, rz)

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

		self.cache3DLinked[node] = {
			["x"] = x,
			["y"] = y,
			["z"] = z,
			["rx"] = rx,
			["ry"] = ry,
			["rz"] = rz,
			["size"] = size,
			["text"] = text,
			["fontName"] = fontName
		}

		return node

	end


	function delete3DLinkedText(node)

		if self.cache3DLinked[node] ~= nil then delete(node) end

		self.cache3DLinked[node] = nil

	end


	local isLoading = g_gameStateManager:getGameState() == GameState.LOADING

	renderText = function(x, y, size, text, fontName)
	
		local args = self.args

		if args.useEngineRenderer then
			engine.renderText(x, y, size, text)
			return
		end

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

		local variationName = "regular"

		if args.bold and args.italic then
			variationName = "boldItalic"
		elseif args.bold then
			variationName = "bold"
		elseif args.italic then
			variationName = "italic"
		end

		local lineConfig = args.lines
		local cachedRender

		for _, cache in pairs(self.cache2D) do

			if cache.x == x and cache.y == y and cache.size == size and cache.text == text and cache.fontName == fontName then
				cache.delete = false
				cachedRender = cache
				break
			end

		end
		
		local args = self.args
		local scale = size * 10
		local cx1, cy1, cx2, cy2 = unpack(args.clip)

		if cachedRender == nil then

			local overlays = {}
			local font = self.fonts[fontName]
			local width, height = size, size
			local lines = { { ["text"] = "", ["width"] = 0, ["x"] = x } }

			if args.alignY == RenderText.VERTICAL_ALIGN_BASELINE then
				y = y - self.yOffset.baseline * scale
			elseif args.alignY == RenderText.VERTICAL_ALIGN_TOP then
				y = y - self.yOffset.baseline * scale
			elseif args.alignY == RenderText.VERTICAL_ALIGN_MIDDLE then
				y = y - self.yOffset.middle * scale
			elseif args.alignY == RenderText.VERTICAL_ALIGN_BOTTOM then
				y = y - self.yOffset.middle * scale * 2
			end


			local function writeCharacter(character, variation, posX, posY)

				local isRendered, overlayWidth, overlayHeight = true, variation.screenWidth * scale, variation.screenHeight * scale
				local uvs

				if (cx1 == 0 and cy1 == 0 and cx2 == 1 and cy2 == 1) or (posX >= cx1 and posX + overlayWidth <= cx2 and posY >= cy1 and posY + overlayHeight <= cy2) then
					uvs = variation.uvs
				else
					isRendered, overlayWidth, overlayHeight, uvs = character:getClippedUVs(variationName, posX, posX + overlayWidth, posY, posY + overlayHeight, cx1, cy1, cx2, cy2)
					if not isRendered then return end
					overlayWidth, overlayHeight = overlayWidth * scale, overlayHeight * scale
				end

				local overlay

				if #self.cachedOverlays > 0 then
					overlay = self.cachedOverlays[1]
					table.remove(self.cachedOverlays, 1)
				else
					overlay = Overlay.new()
				end
			
				overlay:setImage(font.variations[variationName])
				overlay:setDimension(overlayWidth, overlayHeight)
				overlay:setPosition(posX, posY)
				overlay:setUVs(uvs)

				table.insert(overlays, overlay)

			end

			local textWidth = 0
			local words = string.split(text, " ")
			local line = lines[1]

			for j, word in pairs(words) do

				local wordWidth = 0

				for i = 1, #word do

					local character = self:getCharacter(font, string.sub(word, i, i))

					if character == nil then
						wordWidth = wordWidth + size * 0.25
						continue
					end

					local variation = character:getVariation(variationName)
					wordWidth = wordWidth + variation.screenWidth * scale

				end

				if lineConfig.width ~= 0 and line.width + wordWidth > lineConfig.width then
					table.insert(lines, { ["text"] = "", ["width"] = 0, ["x"] = x })
					line = lines[#lines]
				end

				line.text = line.text .. word
				line.width = line.width + wordWidth

				if j ~= #words then
					line.text = line.text .. " "
					line.width = line.width + size * 0.25
				end

			end

			for j, line in pairs(lines) do

				if args.alignX == RenderText.ALIGN_CENTER then
					line.x = line.x - line.width / 2
				elseif args.alignX == RenderText.ALIGN_RIGHT then
					line.x = line.x - line.width
				end

				local text, xOffset, yOffset = line.text, 0, (j - 1) * size

				for i = 1, #text do

					local character = self:getCharacter(font, string.sub(text, i, i))

					if character == nil then
						xOffset = xOffset + size * 0.25
						continue
					end

					local variation = character:getVariation(variationName)
					writeCharacter(character, variation, line.x + xOffset, (y - yOffset))
					xOffset = xOffset + variation.screenWidth * scale

				end

			end


			cachedRender = {
				["delete"] = false,
				["overlays"] = overlays,
				["x"] = x,
				["y"] = y,
				["size"] = size,
				["text"] = text,
				["fontName"] = fontName,
				["width"] = textWidth,
				["lines"] = {}
			}

			for i, line in pairs(lines) do

				table.insert(cachedRender.lines, {
					["width"] = line.width,
					["x"] = line.x,
					["y"] = y - (i - 1) * size
				})

			end

			table.insert(self.cache2D, cachedRender)

		end

		if cachedRender == nil then return end

		local colour = args.colour

		for _, overlay in pairs(cachedRender.overlays) do
			overlay:setColor(colour[1], colour[2], colour[3], colour[4])
			overlay:render()
		end

		if args.underline or args.strikethrough then

			for _, line in pairs(cachedRender.lines) do

				if args.underline then

					local overlay = line.underline

					if overlay == nil then

						local isRendered, screenWidth, screenHeight = true, line.width, size * 0.075
						isRendered, overlay, screenWidth, screenHeight = self:getLineOverlay(line.x, screenWidth, line.y, screenHeight, cx1, cy1, cx2, cy2)

						if isRendered then

							overlay:setDimension(screenWidth, screenHeight)
							overlay:setPosition(line.x, line.y - size * 0.05)
							line.underline = overlay

						end

					end

					if overlay ~= nil then
						overlay:setColor(colour[1], colour[2], colour[3], colour[4])
						overlay:render()

					end

				end

				if args.strikethrough then

					local overlay = line.strikethrough

					if overlay == nil then

						local isRendered, screenWidth, screenHeight = true, line.width, size * 0.075
						isRendered, overlay, screenWidth, screenHeight = self:getLineOverlay(line.x, screenWidth, line.y, screenHeight, cx1, cy1, cx2, cy2)

						if isRendered then

							overlay:setDimension(screenWidth, screenHeight)
							overlay:setPosition(line.x, line.y + size * 0.5)
							line.strikethrough = overlay

						end

					end

					if overlay ~= nil then

						overlay:setColor(colour[1], colour[2], colour[3], colour[4])
						overlay:render()

					end

				end

			end

		end

	end

end


function FontManager:getLineOverlay(leftX, screenWidth, bottomY, screenHeight, minX, minY, maxX, maxY)

	local uvs
	local rightX, topY = leftX + screenWidth, bottomY + screenHeight

	if (minX == 0 and minY == 0 and maxX == 1 and maxY == 1) or (leftX >= minX and rightX <= maxX and bottomY >= minY and topY <= maxY) then
		uvs = GuiUtils.getUVs({ 0, 0, 3, 3 }, { 4, 4 })
	else

		if leftX > maxX or rightX < minX or bottomY > maxY or topY < minY then return false, nil, nil, nil end

		local x, y, width, height = 0, 0, 3, 3

		if leftX < minX then x = width * ((minX - math.abs(leftX)) / (rightX - leftX)) end
		if rightX > maxX then width = width - width * ((rightX - maxX) / (rightX - leftX)) end

		if bottomY < minY then y = height * ((minY - math.abs(bottomY)) / (topY - bottomY)) end
		if topY > maxY then height = height - height * ((topY - maxY) / (topY - bottomY)) - y end

		uvs = GuiUtils.getUVs({ x, y, width, height }, { 4, 4 })

		screenWidth, screenHeight = screenWidth * (width / 3), screenHeight * (height / 3) 

	end
	

	local overlay

	if #self.cachedLineOverlays > 0 then
		overlay = self.cachedLineOverlays[1]
		table.remove(self.cachedLineOverlays, 1)
	else
		overlay = Overlay.new()
		overlay:setImage("dataS/menu/base/graph_pixel.png")
	end

	overlay:setUVs(uvs)
	return true, overlay, screenWidth, screenHeight

end


function FontManager:loadFonts()

	self.fontHolder = g_i3DManager:loadI3DFile(modDirectory .. "fonts/fontHolder.i3d")
	self.template = I3DUtil.indexToObject(self.fontHolder, "0|0")

	local i3dNode = g_i3DManager:loadI3DFile(modDirectory .. "fonts/text.i3d")
	self.text = getChildAt(i3dNode, 0)
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

	if self.fonts[self.defaultFont] == nil then self.defaultFont = "nunito_sans" end

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