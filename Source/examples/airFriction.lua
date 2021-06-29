-- Matter
import 'matter/matter'

local clear = playdate.graphics.clear

-- Create an engine
local engine = Engine.create()
local world = engine.world

-- Create a renderer
local render = Render.create({
	element = nil,
	engine = engine,
	options = {
		width = 400,
		height = 240,
		-- showInternalEdges = true,
		-- wireframes = false, -- FIX ME
		showAngleIndicator = true,
		-- showCollisions = true,
		showIds = true,
		-- showAxes = true,
		-- showBounds = true,
		-- showVelocity = true,
		-- showSeparations = true, -- FIX ME
		-- showVertexNumbers = true,
		-- -- grid
		-- showBroadphase = true,
		-- showGridId = false,
	}
})

-- Create runner
local runner = Runner.create()

-- Add bodies
World.add(world, {

	-- Walls
	Bodies.rectangle(210, 0, 420, 30, { isStatic= true }),
	Bodies.rectangle(210, 240, 420, 30, { isStatic= true }),
	Bodies.rectangle(0, 130, 30, 260, { isStatic= true }),
	Bodies.rectangle(400, 130, 30, 260, { isStatic= true }),

	-- Falling blocks
	Bodies.rectangle(100, 50, 30, 30, { frictionAir = 0.005 }),
	Bodies.rectangle(200, 50, 30, 30, { frictionAir = 0.05 }),
	Bodies.rectangle(300, 50, 30, 30, { frictionAir = 0.3 }),
})


-- Tick

TICK = 1

function tick()
	clear()
	Runner.tick(runner, engine, TICK)
	Render.run(render)
	TICK = TICK + 1
end

local ft = playdate.frameTimer.new(1, tick)
ft.repeats = true


