MultiTextOptionElement.draw = Utils.overwrittenFunction(MultiTextOptionElement.draw, function(self, superFunc, clipX1, clipY1, clipX2, clipY2)

	if not self.autoAddDefaultElements then
		superFunc(self, clipX1, clipY1, clipX2, clipY2)
		return
	end

	if self.newLayer then new2DLayer() end

	local cx1, cy1, cx2, cy2 = self:getClipArea(clipX1, clipY1, clipX2, clipY2)
	self:raiseCallback("onDrawCallback", self)

	local drawLast = {}

	for _, element in ipairs(self.elements) do
		if element:getIsVisibleNonRec() then
			if element:isa(ButtonElement) then
				table.insert(drawLast, element)
			else
				element:draw(element:getClipArea(cx1, cy1, cx2, cy2))
			end
		end
	end

	for _, element in pairs(drawLast) do
		element:draw(element:getClipArea(cx1, cy1, cx2, cy2))
	end

end)