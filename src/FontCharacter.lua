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

	variation.screenWidth, variation.screenHeight = getNormalizedScreenValues(variation.width, variation.height)

	variation.uvs = GuiUtils.getUVs({ variation.x, variation.y, variation.width, variation.height }, { imageWidth, imageHeight })

	return variation

end


function FontCharacter:getVariation(variation)

	return self.variations[variation]

end