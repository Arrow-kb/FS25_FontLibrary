FL_InGameMenuSettingsFrame = {}


function FL_InGameMenuSettingsFrame:onFrameClose()

	FLSettings.saveToXMLFile()
	FLSettings.applyFont()

	--FL_BroadcastSettingsEvent.sendEvent()

end

InGameMenuSettingsFrame.onFrameClose = Utils.appendedFunction(InGameMenuSettingsFrame.onFrameClose, FL_InGameMenuSettingsFrame.onFrameClose)