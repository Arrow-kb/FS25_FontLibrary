-- ###########################################

-- This mod requires engine-level functions to be overwritten. Therefore, code must be executed at the root level, not in a contained mod environment.
-- This is so that vanilla/other mod code executes this mod's overwritten engine functions rather than the original engine functions.

-- ###########################################


local files = {
	"gui/base/ButtonOverlay.lua",
	"gui/elements/ButtonElement.lua",
	"gui/elements/TextElement.lua",
	"input/InputDisplayManager.lua",
	"input/KeyboardHelper.lua",
	"FontCharacter.lua",
	"FontManager.lua",
	"I18N.lua"
}


local root = getmetatable(_G).__index
local modDirectory = g_currentModDirectory

for _, file in pairs(files) do root.source(modDirectory .. "src/" .. file) end