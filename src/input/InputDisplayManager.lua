function InputDisplayManager:getActionGlyphIsInvalid(inputAction, axis)

	local binding = self:getFirstBindingAxisAndDeviceForActionName(inputAction, axis, false)

	if binding == "" then return false end

	return KeyboardHelper.getDisplayKeyNameIsInvalidGlyph(Input[binding])

end