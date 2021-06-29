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
		-- showAngleIndicator = true,
		-- showCollisions = true,
		-- showIds = true,
		-- showAxes = true,
		-- showBounds = true,
		showVelocity = true,
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
-- Walls
World.add(world, {
	Bodies.rectangle(210, 0, 420, 30, { isStatic= true, mass=1000 }),
	Bodies.rectangle(210, 240, 420, 30, { isStatic= true, mass=1000 }),
	Bodies.rectangle(0, 130, 30, 260, { isStatic= true, mass=1000 }),
	Bodies.rectangle(400, 130, 30, 260, { isStatic= true, mass=1000 }),
})

World.add(world, {
	Bodies.rectangle(110, 75, 200, 10, { isStatic = true, angle = math.pi * 0.06, mass=1000 }),
	Bodies.rectangle(110, 175, 200, 10, { isStatic = true, angle = math.pi * 0.04, mass=1000 }),
	Bodies.rectangle(280, 125, 230, 10, { isStatic = true, angle = -math.pi * 0.06, mass=1000 }),
})

-- Bodies
World.add(world, {
	Bodies.circle(30, 30, Common.random(10, 15),{ friction = 0.00001, restitution = 0.5, density = 0.001}),
	Bodies.circle(30, 30, Common.random(5, 10),{ friction = 0.00001, restitution = 0.5, density = 0.001}),
	Bodies.circle(30, 30, Common.random(5, 10),{ friction = 0.00001, restitution = 0.5, density = 0.001}),
	Bodies.circle(30, 30, Common.random(5, 10),{ friction = 0.00001, restitution = 0.5, density = 0.001}),
	Bodies.circle(30, 30, Common.random(5, 10),{ friction = 0.00001, restitution = 0.5, density = 0.001}),
});


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


