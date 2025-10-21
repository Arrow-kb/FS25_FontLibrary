TextElement.loadFromXML = Utils.appendedFunction(TextElement.loadFromXML, function(self, xmlFile, key)

	self.textFont = getXMLString(xmlFile, key .. "#textFont") or self.textFont
	self.textItalic = getXMLBool(xmlFile, key .. "#textItalic") or false
	self.textUnderlined = getXMLBool(xmlFile, key .. "#textUnderlined") or false
	self.textStrikethrough = getXMLBool(xmlFile, key .. "#textStrikethrough") or false

end)


TextElement.loadProfile = Utils.appendedFunction(TextElement.loadProfile, function(self, profile)

	self.textFont = profile:getBool("textFont", self.textFont)
	self.textItalic = profile:getBool("textFont", self.textItalic)
	self.textUnderlined = profile:getBool("textUnderlined", self.textUnderlined)
	self.textStrikethrough = profile:getBool("textStrikethrough", self.textStrikethrough)

end)


TextElement.draw = Utils.overwrittenFunction(TextElement.draw, function(self, superFunc, x1, y1, x2, y2)

	setTextFont(self.textFont)
	setTextItalic(self.textItalic)
	setTextUnderlined(self.textUnderlined)
	setTextStrikethrough(self.textStrikethrough)

	superFunc(self, x1, y1, x2, y2)

	setTextFont()
	setTextItalic()
	setTextUnderlined()
	setTextStrikethrough()

end)


function TextElement:setTextFont(fontId)

	self.textFont = fontId

end


function TextElement:setTextItalic(isItalic)

	self.textItalic = isItalic or false

end


function TextElement:setTextUnderlined(isUnderlined)

	self.textUnderlined = isUnderlined or false

end


function TextElement:setTextStrikethrough(isStrikethrough)

	self.textStrikethrough = isStrikethrough or false

end