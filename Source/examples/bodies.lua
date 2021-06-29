-- Matter
import 'matter/matter'

local clear = playdate.graphics.clear


-- Create an engine
local engine = Engine.create()

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

-- Floor
local path1 = {
	{x=39.5,y=72.5},
	{x=118.5,y=148.5},
	{x=288.5,y=163.5},
	{x=388.5,y=97.5},
	{x=386.5,y=231.5},
	{x=32.5,y=229.5},
}

local path2 = {
	{x=5.5,y=92.5},
	{x=24.5,y=84.5},
	{x=36.5,y=98.5},
	{x=34.5,y=128.5},
	{x=18.5,y=164.5},
	{x=39.5,y=190.5},
	{x=60.5,y=203.5},
	{x=83.5,y=191.5},
	{x=78.5,y=167.5},
	{x=71.5,y=148.5},
	{x=108.5,y=119.5},
	{x=127.5,y=119.5},
	{x=135.5,y=138.5},
	{x=138.5,y=175.5},
	{x=153.5,y=201.5},
	{x=195.5,y=189.5},
	{x=217.5,y=153.5},
	{x=273.5,y=140.5},
	{x=293.5,y=149.5},
	{x=322.5,y=165.5},
	{x=345.5,y=160.5},
	{x=371.5,y=122.5},
	{x=395.5,y=137.5},
	{x=395.5,y=235.5},
	{x=4.5,y=235.5}
}

local terrain = Bodies.fromVertices(190, 170, { path1 }, {isStatic = true, mass = 1001}, true)

World.add(engine.world, {terrain})


-- Create runner
local runner = Runner.create()


-- Tick

playdate.debug.setEnabled(true)

TICK = 1
--
function tick()
	clear()
	Runner.tick(runner, engine, TICK)
	Render.run(render)
	TICK += 1
end

local ft = playdate.frameTimer.new(1, tick)
ft.repeats = true


-- Add a new body

function playdate.AButtonDown()
	World.add(engine.world, { addBody() })
end

function addBody()

	local body
	local x, y = math.random(100,300), 50
	local r, f = math.random(1, 100) * 0.01, math.random(1, 100) * 0.01
	local case = math.random(1, 3)

	if (case == 1) then
		return Bodies.polygon(x, y, 6, Common.random(10, 20), { angle = .1, mass = .3, restitution = r, friction = f })
	elseif 	(case == 2) then
		return Bodies.circle(x, y, Common.random(10, 20), { restitution = r, friction = f})
	elseif	 (case == 3) then
		return Bodies.rectangle(x, y, 20, 20, {angle = .1, mass = .3, restitution = r, friction = f})
	end

end
