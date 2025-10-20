FL_FSBaseMission = {}


function FL_FSBaseMission:onStartMission()

	FontViewerDialog.register()

end

FSBaseMission.onStartMission = Utils.prependedFunction(FSBaseMission.onStartMission, FL_FSBaseMission.onStartMission)