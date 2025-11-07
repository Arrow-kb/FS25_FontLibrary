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


TextElement.draw = Utils.overwrittenFunction(TextElement.draw, function(self, superFunc, clipX1, clipY1, clipX2, clipY2)

	TextElement:superClass().draw(self, clipX1, clipY1, clipX2, clipY2)

	if self:getDoRenderText() and self.text ~= nil and self.text ~= "" then

		setTextFont(self.textFont)
		setTextItalic(self.textItalic)
		setTextUnderlined(self.textUnderlined)
		setTextStrikethrough(self.textStrikethrough)

		local xOffset, yOffset = self:getTextOffset()

        if self:getTextLayoutMode() == TextElement.LAYOUT_MODE.SCROLLING and self.scrollingMaxOffset > 0 then
            clipX1 = math.max(self.scrollingClipArea[1] + xOffset, clipX1 or 0)
            clipY1 = math.max(self.scrollingClipArea[2] + yOffset, clipY1 or 0)
            clipX2 = math.min(self.scrollingClipArea[3] + xOffset, clipX2 or math.huge)
            clipY2 = math.min(self.scrollingClipArea[4] + yOffset, clipY2 or math.huge)
        end

        if clipX1 ~= nil then
            setTextClipArea(clipX1, clipY1, clipX2, clipY2)
        end

        setTextAlignment(self.textAlignment)

        local maxWidth = self.absSize[1]
        if self.textMaxWidth ~= nil then
            maxWidth = self.textMaxWidth
        elseif self.textAutoWidth then
            maxWidth = 1
        end

        if self.textMaxNumLines > 1 then
            setTextWrapWidth(maxWidth)
        end

        setTextFirstLineIndentation(self.firstLineIndentation or 0)
        setTextLineBounds((self.currentPage - 1) * self.textLinesPerPage, self.textLinesPerPage)
        setTextLineHeightScale(self.textLineHeightScale)

        local text = self.text

        local bold = self.textBold or self.textSelectedBold and self:getIsSelected() or self.textHighlightedBold and self:getIsHighlighted() or
            self.textFocusedBold and self:getIsFocused()
        setTextBold(bold)

        local xPos, yPos = self:getTextPosition(text)
        local baselineOffset = self.textSize * 0.1
        yPos = yPos + baselineOffset

        if self.text2Size > 0 then
            local x2Offset, y2Offset = self:getText2Offset()
            bold = self.text2Bold or (self.text2SelectedBold and self:getIsSelected()) or (self.text2HighlightedBold and self:getIsHighlighted())
            setTextBold(bold)
            local r,g,b,a = unpack(self:getText2Color())
            setTextColor(r,g,b,a*self.alpha)
            renderText(xPos + x2Offset, yPos + y2Offset, self.text2Size, text)
        end

        local r,g,b,a = unpack(self:getTextColor())
        setTextColor(r,g,b,a*self.alpha)

        renderText(xPos + xOffset, yPos + yOffset, self.textSize, text)

        setTextBold(false)
        setTextAlignment(RenderText.ALIGN_LEFT)
        setTextLineHeightScale(RenderText.DEFAULT_LINE_HEIGHT_SCALE)
        setTextColor(1, 1, 1, 1)
        setTextLineBounds(0, 0)
        setTextWrapWidth(0)
        setTextFirstLineIndentation(0)

        if clipX1 ~= nil then
            setTextClipArea(0, 0, 1, 1)
        end

        if self.debugEnabled or g_uiDebugEnabled then
            setOverlayColor(GuiElement.debugOverlay, 0, 0, 0, 1)

            local x = xPos + xOffset
            if self.textAlignment == RenderText.ALIGN_RIGHT then
                x = x - maxWidth
            elseif self.textAlignment == RenderText.ALIGN_CENTER then
                x = x - maxWidth / 2
            end

            renderOverlay(GuiElement.debugOverlay, x, yPos + yOffset, maxWidth, g_pixelSizeY*2)

            local width = self:getTextWidth()
            x = xPos + xOffset
            if self.textAlignment == RenderText.ALIGN_RIGHT then
                x = x - width
            elseif self.textAlignment == RenderText.ALIGN_CENTER then
                x = x - width * 0.5
            end

            setOverlayColor(GuiElement.debugOverlay, 0, 1, 0, 1)
            renderOverlay(GuiElement.debugOverlay, x, yPos + yOffset, width, 1 * g_pixelSizeY)
            setOverlayColor(GuiElement.debugOverlay, 1, 0.5, 0, 1)
            renderOverlay(GuiElement.debugOverlay, x, yPos + yOffset + getTextHeight(self.textSize, text) * 0.5, width, 1 * g_pixelSizeY)
            setOverlayColor(GuiElement.debugOverlay, 0, 0, 1, 1)
            renderOverlay(GuiElement.debugOverlay, x, yPos + yOffset + getTextHeight(self.textSize, text) * 0.75, width, 1 * g_pixelSizeY)

            if self:getTextLayoutMode() == TextElement.LAYOUT_MODE.SCROLLING and self.scrollingMaxOffset > 0 then
                local debugWidth = self.scrollingClipArea[3] - self.scrollingClipArea[1]
                local debugHeight = self.scrollingClipArea[4] - self.scrollingClipArea[2]

                drawOutlineRect(self.scrollingClipArea[1], self.scrollingClipArea[2], debugWidth, debugHeight, 2*g_pixelSizeX, 2*g_pixelSizeY, 0,0,1,1)
            end
        end

		setTextFont()
		setTextItalic()
		setTextUnderlined()
		setTextStrikethrough()

	end

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