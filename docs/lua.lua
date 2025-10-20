-- Documentation for LUA code

---Load custom fonts from a 3rd party mod
-- @param	string	xmlPath		path to the XML file containing your individual font paths
-- @param	string	directory	path to your base mod directory
-- @return	table	fontIds		table of unique ids to names
g_fontManager:loadFontsFromXMLFile(xmlPath, directory) --> table


---Render 2D text in screen-space
-- @param	float	x			x-coordinate [0...1]
-- @param	float	y			y-coordinate [0...1]
-- @param	float	size		text size [0...1]
-- @param	string	text		text to render
-- @param	string?	fontName	id of font to render in (optional)
renderText = function(x, y, size, text, fontName)


---Render 3D text in world-space
-- @param	float	x			x-coordinate
-- @param	float	y			y-coordinate
-- @param	float	z			z-coordinate
-- @param	float	rx			x-rotation
-- @param	float	ry			y-rotation
-- @param	float	rz			z-rotation
-- @param	float	size		text size
-- @param	string	text		text to render
-- @param	string?	fontName	id of font to render in (optional)
renderText3D = function(x, y, z, rx, ry, rz, size, text, fontName)


---Render text as italic
-- @param	bool?	isItalic	whether to render as italic
setTextItalic = function(isItalic)


---Render text underlined (not implemented)
-- @param	bool?	isUnderlined	whether to render underlined
setTextUnderlined = function(isUnderlined)


---Render text with strikethrough (not implemented)
-- @param	bool?	isStrikethrough	whether to render with strikethrough
setTextStrikethrough = function(isStrikethrough)