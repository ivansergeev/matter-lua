--[[
* The `Matter.Runner` module is an optional utility which provides a game loop,
* that handles continuously updating a `Matter.Engine` for you within a browser.
* It is intended for development and debugging purposes, but may also be suitable for simple games.
* If you are using your own game loop instead, then you do not need the `Matter.Runner` module.
* Instead just call `Engine.update(engine, delta)` in your own loop.
*
* See the included usage [examples](https:--github.com/liabru/matter-js/tree/master/examples).
*
* @class Runner
]]--


import 'matter/core/Events'
import 'matter/core/Engine'
import 'matter/core/Common'
import 'matter/render/Render'

class('Runner').extends(playdate.graphics.sprite)

function Runner:init(runner, engine, render)

	self.runner = runner
	self.engine = engine
	self.render = render
	self:setSize(1, 1)
	self:addSprite()

	return self
end

function Runner:update()
	-- print(playdate.getCurrentTimeMilliseconds())
	-- Runner.tick(self.runner, self.engine, playdate.getCurrentTimeMilliseconds())
	-- Render.run(self.render)
end


--[[
 * Creates a new Runner. The options parameter is an object that specifies any properties you wish to override the defaults.
 * @method create
 * @param {} options
 ]]--

function Runner.create(options)

	-- print('Runner.create')

	local defaults = {
		fps = 30,
		correction = 1,
		deltaSampleSize = 31,
		counterTimestamp = 0,
		frameCounter = 0,
		deltaHistory = {},
		timePrev = 0,
		timeScalePrev = 1,
		frameRequestId = nil,
		isFixed = false,
		enabled = true,
	}

	local runner = Common.extend(defaults, options)

	runner.delta = runner.delta or 1000 / runner.fps
	runner.deltaMin = runner.deltaMin or 1000 / runner.fps
	runner.deltaMax = runner.deltaMax or 1000 / (runner.fps * 0.5)
	runner.fps = 1000 / runner.delta

	return runner
end

--[[
 * Continuously ticks a `Matter.Engine` by calling `Runner.tick` on the `requestAnimationFrame` event.
 * @method run
 * @param {engine} engine
 ]]--

function Runner.run(runner, engine)

	-- create runner if engine is first argument

	if (type(runner.positionIterations) ~= 'nil') then
		engine = runner
		runner = Runner.create()
	end

--[[
	(function render(time){

		runner.frameRequestId = _requestAnimationFrame(render)

		if (time and runner.enabled) then
			Runner.tick(runner, engine, time)
		end

	})()
]]--

	local time = playdate.getCurrentTimeMilliseconds()

	if (runner.enabled) then

		Runner.tick(runner, engine, time)
	end

	return runner
end


--[[
 * A game loop utility that updates the engine and renderer by one step (a 'tick').
 * Features delta smoothing, time correction and fixed or dynamic timing.
 * Triggers `beforeTick`, `tick` and `afterTick` events on the engine.
 * Consider just `Engine.update(engine, delta)` if you're using your own loop.
 * @method tick
 * @param {runner} runner
 * @param {engine} engine
 * @param {number} time
 ]]--

function Runner.tick(runner, engine, time)

	local timing = engine.timing
	local correction = 1
	local delta

	-- create an event object
	local event = {
		timestamp = timing.timestamp
	}

	Events.trigger(runner, 'beforeTick', event)
	Events.trigger(engine, 'beforeTick', event) -- @deprecated

	if (runner.isFixed) then
		-- fixed timestep
		delta = runner.delta
	else
		-- dynamic timestep based on wall clock between calls
		delta = (time - runner.timePrev) or runner.delta
		runner.timePrev = time

		-- optimistically filter delta over a few frames, to improve stability
		table.insert(runner.deltaHistory, delta)

		if(#runner.deltaHistory == runner.deltaSampleSize) then
			table.remove(runner.deltaHistory, 1)
		end

		-- delta = math.min.apply(null, runner.deltaHistory)
		delta = math.min(table.unpack(runner.deltaHistory))

		-- limit delta
		delta = delta < runner.deltaMin and runner.deltaMin or delta
		delta = delta > runner.deltaMax and runner.deltaMax or delta

		-- correction for delta
		correction = delta / runner.delta

		-- update engine timing object
		runner.delta = delta
	end

	-- time correction for time scaling
	if (runner.timeScalePrev ~= 0) then
		correction *= timing.timeScale / runner.timeScalePrev
	end

	if (timing.timeScale == 0) then
		correction = 0
	end

	runner.timeScalePrev = timing.timeScale
	runner.correction = correction

	-- fps counter

	runner.frameCounter += 1

	if (time - runner.counterTimestamp >= 1000) then
		runner.fps = runner.frameCounter * ((time - runner.counterTimestamp) / 1000)
		runner.counterTimestamp = time
		runner.frameCounter = 0
	end

	Events.trigger(runner, 'tick', event)
	Events.trigger(engine, 'tick', event) -- @deprecated

	-- if world has been modified, clear the render scene graph

	if (engine.world.isModified
		and engine.render
		and engine.render.controller
		and engine.render.controller.clear) then

		-- engine.render.controller.clear(engine.render) -- @deprecated

	end


	-- update
	Events.trigger(runner, 'beforeUpdate', event)
	Engine.update(engine, delta, correction)
	Events.trigger(runner, 'afterUpdate', event)

	-- render
	-- @deprecated
	if (engine.render and engine.render.controller) then
		Events.trigger(runner, 'beforeRender', event)
		-- Events.trigger(engine, 'beforeRender', event) -- @deprecated
		engine.render.controller.world(engine.render)
		Events.trigger(runner, 'afterRender', event)
		-- Events.trigger(engine, 'afterRender', event) -- @deprecated
	end

	Events.trigger(runner, 'afterTick', event)
	-- Events.trigger(engine, 'afterTick', event) -- @deprecated
end

--[[
 * Ends execution of `Runner.run` on the given `runner`, by canceling the animation frame request event loop.
 * If you wish to only temporarily pause the engine, see `engine.enabled` instead.
 * @method stop
 * @param {runner} runner
 ]]--

function Runner.stop(runner)
	-- _cancelAnimationFrame(runner.frameRequestId)
end

--[[
 * Alias for `Runner.run`.
 * @method start
 * @param {runner} runner
 * @param {engine} engine
 ]]--

function Runner.start(runner, engine)
	Runner.run(runner, engine)
end


--[[
*
*  Events Documentation
*
]]--

--[[
* Fired at the start of a tick, before any updates to the engine or timing
*
* @event beforeTick
* @param {} event An event object
* @param {number} event.timestamp The engine.timing.timestamp of the event
* @param {} event.source The source object of the event
* @param {} event.name The name of the event
]]--

--[[
* Fired after engine timing updated, but just before update
*
* @event tick
* @param {} event An event object
* @param {number} event.timestamp The engine.timing.timestamp of the event
* @param {} event.source The source object of the event
* @param {} event.name The name of the event
]]--

--[[
* Fired at the end of a tick, after engine update and after rendering
*
* @event afterTick
* @param {} event An event object
* @param {number} event.timestamp The engine.timing.timestamp of the event
* @param {} event.source The source object of the event
* @param {} event.name The name of the event
]]--

--[[
* Fired before update
*
* @event beforeUpdate
* @param {} event An event object
* @param {number} event.timestamp The engine.timing.timestamp of the event
* @param {} event.source The source object of the event
* @param {} event.name The name of the event
]]--

--[[
* Fired after update
*
* @event afterUpdate
* @param {} event An event object
* @param {number} event.timestamp The engine.timing.timestamp of the event
* @param {} event.source The source object of the event
* @param {} event.name The name of the event
]]--

--[[
* Fired before rendering
*
* @event beforeRender
* @param {} event An event object
* @param {number} event.timestamp The engine.timing.timestamp of the event
* @param {} event.source The source object of the event
* @param {} event.name The name of the event
* @deprecated
]]--

--[[
* Fired after rendering
*
* @event afterRender
* @param {} event An event object
* @param {number} event.timestamp The engine.timing.timestamp of the event
* @param {} event.source The source object of the event
* @param {} event.name The name of the event
* @deprecated
]]--

--[[
*
*  Properties Documentation
*
]]--

--[[
 * A flag that specifies whether the runner is running or not.
 *
 * @property enabled
 * @type boolean
 * @default true
 ]]--

--[[
 * A `Boolean` that specifies if the runner should use a fixed timestep (otherwise it is variable).
 * If timing is fixed, then the apparent simulation speed will change depending on the frame rate (but behaviour will be deterministic).
 * If the timing is variable, then the apparent simulation speed will be constant (approximately, but at the cost of determininism).
 *
 * @property isFixed
 * @type boolean
 * @default false
 ]]--

--[[
 * A `Number` that specifies the time step between updates in milliseconds.
 * If `engine.timing.isFixed` is set to `true`, then `delta` is fixed.
 * If it is `false`, then `delta` can dynamically change to maintain the correct apparent simulation speed.
 *
 * @property delta
 * @type number
 * @default 1000 / 60
 ]]--


