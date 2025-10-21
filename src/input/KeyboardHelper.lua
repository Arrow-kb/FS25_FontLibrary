KeyboardHelper.INVALID_GYLPHS = {
	["keyGlyph_return"] = true,
	["keyGlyph_enter"] = true,
	["keyGlyph_backspace"] = true,
	["keyGlyph_up"] = true,
	["keyGlyph_down"] = true,
	["keyGlyph_left"] = true
}


function KeyboardHelper.getDisplayKeyNameIsInvalidGlyph(key)

	local name = KeyboardHelper.KEY_GLYPHS[key]
	return name ~= nil and KeyboardHelper.INVALID_GYLPHS[name]

end