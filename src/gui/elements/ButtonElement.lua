ButtonElement.loadInputGlyph = Utils.appendedFunction(ButtonElement.loadInputGlyph, function(self)

	if not (GS_IS_CONSOLE_VERSION or GS_IS_MOBILE_VERSION) then
		
		local keyName = g_inputDisplayManager:getKeyboardInputActionKey(self.inputActionName, Binding.AXIS_COMPONENT.POSITIVE)

		if keyName ~= nil then
			self.keyOverlay:setUseEngineRenderer(g_inputDisplayManager:getActionGlyphIsInvalid(self.inputActionName, Binding.AXIS_COMPONENT.POSITIVE))
		end

	end

end)