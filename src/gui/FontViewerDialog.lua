FontViewerDialog = {}

local FontViewerDialog_mt = Class(FontViewerDialog, MessageDialog)
local modDirectory = g_currentModDirectory

function FontViewerDialog.register()

    local dialog = FontViewerDialog.new()
    g_gui:loadGui(modDirectory .. "gui/FontViewerDialog.xml", "FontViewerDialog", dialog)
    FontViewerDialog.INSTANCE = dialog

end


function FontViewerDialog.new(target, customMt)

    local self = MessageDialog.new(target, customMt or FontViewerDialog_mt)

    self.fonts = {}

    return self

end


function FontViewerDialog.createFromExistingGui(gui)

    FontViewerDialog.register()
    FontViewerDialog.show()

end


function FontViewerDialog:onGuiSetupFinished()

    FontViewerDialog:superClass().onGuiSetupFinished(self)
    g_fontManager:setFontViewerDialog(self)

end


function FontViewerDialog:reloadFonts()

    local texts, indexToId = {}, {}

    for id, name in pairs(self.fonts) do

        local formattedName = string.gsub(name, "_", " ")

        table.insert(texts, formattedName)
        table.insert(indexToId, id)

    end

    self.fontPicker:setTexts(texts)
    self.indexToId = indexToId

    self.fontSizes = {
        "5px",
        "10px",
        "15px",
        "20px",
        "25px",
        "30px",
        "35px"
    }

    self.sizePicker:setTexts(self.fontSizes)

end


function FontViewerDialog:addFont(id, name)

    self.fonts[id] = name

end


function FontViewerDialog.show()

    if FontViewerDialog.INSTANCE == nil then FontViewerDialog.register() end

    g_gui:showDialog("FontViewerDialog")

end


function FontViewerDialog:onOpen()

    FontViewerDialog:superClass().onOpen(self)

    local currentIndex, currentId = 1, g_fontManager.defaultFont

    for index, id in pairs(self.indexToId) do

        if currentId == id then
            currentIndex = index
            break
        end

    end

    self.fontPicker:setState(currentIndex)
    self.sizePicker:setState(4)
    self:onChangeFont(currentIndex)
    self:onChangeFontSize(4)

end


function FontViewerDialog:onChangeFont(state)

    self.fontPicker:getDescendantByName("text"):setTextFont(self.indexToId[state])

    for _, text in pairs(self.exampleTexts) do text:setTextFont(self.indexToId[state]) end

end


function FontViewerDialog:onChangeFontSize(state)

    local size = GuiUtils.getNormalizedYValue(self.fontSizes[state])

    for _, text in pairs(self.exampleTexts) do text.textSize = size end

end