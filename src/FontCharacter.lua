FontCharacter = {}

local FontCharacter_mt = Class(FontCharacter)


function FontCharacter.new(font)

	local self = setmetatable({}, FontCharacter_mt)

	self.font = font
	self.variations = {}

	return self

end


function FontCharacter:loadFromXMLFile(xmlFile, key)

	self.character = xmlFile:getString(key .. "#character")
	self.byte = xmlFile:getInt(key .. "#byte")
	self.index = xmlFile:getInt(key .. "#uvIndex")
	self.type = xmlFile:getString(key .. "#type", "alphabetical")

	for _, variationKey, variationName in xmlFile:iteratorChildren(key) do

		local imageWidth, imageHeight = 8192, 256

		if variationName == "italic" or variationName == "boldItalic" then imageHeight = imageHeight * 2 end

		self.variations[variationName] = self:loadVariation(xmlFile, variationKey, imageWidth, imageHeight)

	end

end


function FontCharacter:loadVariation(xmlFile, key, imageWidth, imageHeight)

	local variation = {}

	variation.width = xmlFile:getInt(key .. "#width", 128)
	variation.height = xmlFile:getInt(key .. "#height", 128)

	variation.x = xmlFile:getInt(key .. "#x")
	variation.y = xmlFile:getInt(key .. "#y")

	variation.left = (xmlFile:getFloat(key .. "#left") - 2) / 64
	variation.right = (xmlFile:getFloat(key .. "#right") + 2) / 64

	variation.screenWidth, variation.screenHeight = getNormalizedScreenValues(variation.width, variation.height)
	variation.imageWidth, variation.imageHeight = imageWidth, imageHeight

	variation.uvs = GuiUtils.getUVs({ variation.x, variation.y, variation.width, variation.height }, { imageWidth, imageHeight })

	return variation

end


function FontCharacter:getVariation(variation)

	return self.variations[variation]

end


function FontCharacter:getClippedUVs(variationName, leftX, rightX, bottomY, topY, minX, minY, maxX, maxY)

	local variation = self.variations[variationName]
	local x, y, width, height = variation.x, variation.y, variation.width, variation.height

	if leftX > maxX or rightX < minX or bottomY > maxY or topY < minY then return false, nil, nil, nil end

	if leftX < minX then x = width * ((minX - math.abs(leftX)) / (rightX - leftX)) end
	if rightX > maxX then width = width - width * ((rightX - maxX) / (rightX - leftX)) end

	if bottomY < minY then y = height * ((minY - math.abs(bottomY)) / (topY - bottomY)) end
	if topY > maxY then height = height - height * ((topY - maxY) / (topY - bottomY)) end

	local screenWidth, screenHeight = getNormalizedScreenValues(width, height)

	return true, screenWidth, screenHeight, GuiUtils.getUVs({ x, y, width, height }, { variation.imageWidth, variation.imageHeight })

end