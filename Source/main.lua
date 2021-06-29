
-- Playdate CoreLibs
import 'CoreLibs/sprites.lua'
import 'CoreLibs/graphics.lua'
import 'CoreLibs/frameTimer'
import 'CoreLibs/utilities/sampler'

-- Helpers
import 'helpers/string.lua'
import 'helpers/number.lua'
import 'helpers/table.lua'

-- Examples
-- import 'examples/airFriction'
-- import 'examples/avalanche'
import 'examples/bodies'

-- Tests
-- import 'tests/Axes'
-- import 'tests/Bounds'
-- import 'tests/Common'
-- import 'tests/Engine'
-- import 'tests/Vector'
-- import 'tests/polyDecomp.lua'
-- import 'tests/Vertices'

-- Variables
printT = printTable

local gfx = playdate.graphics

-- Fonts
local font = gfx.font.new('fonts/Bitmore-Medieval-table-7-11.png')
gfx.setFont(font, gfx.font.kVariantNormal)


function playdate.update()
	playdate.frameTimer.updateTimers()
	playdate.drawFPS(380, 10)
end