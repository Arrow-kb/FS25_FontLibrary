FontCharacter = {}

local FontCharacter_mt = Class(FontCharacter)


function FontCharacter.new(font)

	local self = setmetatable({}, FontCharacter_mt)

	self.font = font
	self.variations = {}

	return self

end


function FontCharacter:loadFromXMLFile(xmlFile, key, imageWidth, imageHeight, cellWidth, cellHeight)

	self.character = xmlFile:getString(key .. "#character")
	self.byte = xmlFile:getInt(key .. "#byte")
	self.index = xmlFile:getInt(key .. "#uvIndex")
	self.type = xmlFile:getString(key .. "#type", "alphabetical")

	for _, variationKey, variationName in xmlFile:iteratorChildren(key) do

		self.variations[variationName] = self:loadVariation(xmlFile, variationKey, imageWidth, (variationName == "italic" or variationName == "boldItalic") and (imageHeight * 2) or imageHeight, cellWidth, cellHeight)

	end

end


function FontCharacter:loadVariation(xmlFile, key, imageWidth, imageHeight, cellWidth, cellHeight)

	local variation = {}

	variation.width = xmlFile:getInt(key .. "#width", cellWidth)
	variation.height = xmlFile:getInt(key .. "#height", cellHeight)

	variation.x = xmlFile:getInt(key .. "#x")
	variation.y = xmlFile:getInt(key .. "#y")

	variation.left = (xmlFile:getFloat(key .. "#left") - 2) / (cellWidth / 2)
	variation.right = (xmlFile:getFloat(key .. "#right") + 2) / (cellWidth / 2)

	variation.screenWidth, variation.screenHeight = getNormalizedScreenValues(variation.width, variation.height)
	variation.imageWidth, variation.imageHeight = imageWidth, imageHeight

	variation.uvs = GuiUtils.getUVs({ variation.x, variation.y, variation.width, variation.height }, { imageWidth, imageHeight })

	return variation

end


function FontCharacter:getVariation(variation)

	return self.variations[variation]

end


function FontCharacter:getClippedUVs(variationName, leftX, rightX, bottomY, topY, minX, minY, maxX, maxY, text)

	local variation = self.variations[variationName]
	local width, height = variation.width, variation.height

	local x1, x2, y1, y2 = 0, variation.width, 0, variation.height

	if leftX > maxX or rightX < minX or bottomY > maxY or topY < minY then return false, nil, nil, nil end

	if leftX < minX then x1 = width * ((minX - math.abs(leftX)) / (rightX - leftX)) end
	if rightX > maxX then x2 = width - width * ((rightX - maxX) / (rightX - leftX)) end

	if bottomY < minY then y1 = height * ((minY - math.abs(bottomY)) / (topY - bottomY)) end
	if topY > maxY then y2 = height - height * ((topY - maxY) / (topY - bottomY)) end

	local screenWidth, screenHeight = getNormalizedScreenValues(x2 - x1, y2 - y1)

	return true, screenWidth, screenHeight, GuiUtils.getUVs({ variation.x + width - x2, variation.y + height - y2, x2 - x1, y2 - y1 }, { variation.imageWidth, variation.imageHeight })

end