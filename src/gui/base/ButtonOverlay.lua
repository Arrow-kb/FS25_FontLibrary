function ButtonOverlay:setUseEngineRenderer(useEngine)

	self.useEngine = useEngine

end


ButtonOverlay.renderButton = Utils.overwrittenFunction(ButtonOverlay.renderButton, function(self, superFunc, text, posX, posY, height, colorText, clipX1, clipY1, clipX2, clipY2, customOffsetLeft, customButtonInputText)

	setTextUseEngineRenderer(self.useEngine)
	local returnValue = superFunc(self, text, posX, posY, height, colorText, clipX1, clipY1, clipX2, clipY2, customOffsetLeft, customButtonInputText)
	setTextUseEngineRenderer(false)

	return returnValue

end)