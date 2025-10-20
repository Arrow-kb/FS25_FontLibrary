FL_TextElement = {}


function FL_TextElement:loadFromXML(xmlFile, key)

	self.textFont = getXMLString(xmlFile, key .. "#textFont") or self.textFont
	self.textItalic = getXMLBool(xmlFile, key .. "#textItalic") or false

end

TextElement.loadFromXML = Utils.appendedFunction(TextElement.loadFromXML, FL_TextElement.loadFromXML)


function FL_TextElement:loadProfile(profile)

	self.textFont = profile:getBool("textFont", self.textFont)
	self.textItalic = profile:getBool("textFont", self.textItalic)

end

TextElement.loadProfile = Utils.appendedFunction(TextElement.loadProfile, FL_TextElement.loadProfile)


function FL_TextElement:draw(superFunc, x1, y1, x2, y2)

	setTextFont(self.textFont)
	setTextItalic(self.textItalic)

	superFunc(self, x1, y1, x2, y2)

	setTextFont()
	setTextItalic()

end

TextElement.draw = Utils.overwrittenFunction(TextElement.draw, FL_TextElement.draw)


function TextElement:setTextFont(fontId)

	self.textFont = fontId

end


function TextElement:setTextItalic(isItalic)

	self.textItalic = isItalic or false

end