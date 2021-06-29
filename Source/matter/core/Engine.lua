--[[
* The `Matter.Engine` module contains methods for creating and manipulating engines.
* An engine is a controller that manages updating the simulation of the world.
* See `Matter.Runner` for an optional game loop utility.
*
* See the included usage [examples](https:--github.com/liabru/matter-js/tree/master/examples).
*
* @class Engine
]]--

import 'matter/body/World'
import 'matter/core/Sleeping'
import 'matter/collision/Resolver'
import 'matter/render/Render'
import 'matter/collision/Pairs'
import 'matter/collision/Grid'
import 'matter/core/Events'
import 'matter/body/Composite'
import 'matter/constraint/Constraint'
import 'matter/core/Common'
import 'matter/body/Body'

Engine = {}
Engine.__index = Engine

--[[
 * Creates a new engine. The options parameter is an object that specifies any properties you wish to override the defaults.
 * All properties have default values, and many are pre-calculated automatically based on other properties.
 * See the properties section below for detailed information on what you can pass via the `options` object.
 * @method create
 * @param {object} [options]
 * @return {engine} engine
 ]]--

function Engine.create(element, options)

	-- options may be passed as the first (and only) argument
	options = Common.isElement(element) and options or element
	element = Common.isElement(element) and element or nil
	options = options or {}

	if (element or options.render) then
		Common.warn('Engine.create: engine.render is deprecated (see docs)')
	end

	local defaults = {
		positionIterations = 6, -- default 6
		velocityIterations = 4, -- default 4
		constraintIterations = 2, -- default 2
		enableSleeping = false, --default false
		events = {},
		plugin = {},
		timing = {
			timestamp = 0,
			timeScale = 1
		},
		broadphase = {
			controller = Grid
		}
	}

	local engine = Common.extend(defaults, options)

	-- @deprecated
	if (element or engine.render) then
		local renderDefaults = {
			element = element,
			controller = Render
		}

		engine.render = Common.extend(renderDefaults, engine.render)
	end

	-- @deprecated
	if (engine.render and engine.render.controller) then
		engine.render = engine.render.controller.create(engine.render)
	end

	-- @deprecated
	if (engine.render) then
		engine.render.engine = engine
	end

	engine.world = options.world or World.create(engine.world)
	engine.pairs = Pairs.create()
	engine.broadphase = engine.broadphase.controller.create(engine.broadphase)

	-- engine.metrics = engine.metrics or { extended = false }

	-- @if DEBUG
	-- engine.metrics = Metrics.create(engine.metrics)
	-- @endif

	return engine
end

--[[
 * Moves the simulation forward in time by `delta` ms.
 * The `correction` argument is an optional `Number` that specifies the time correction factor to apply to the update.
 * This can help improve the accuracy of the simulation in cases where `delta` is changing between updates.
 * The value of `correction` is defined as `delta / lastDelta`, i.e. the percentage change of `delta` over the last step.
 * Therefore the value is always `1` (no correction) when `delta` constant (or when no correction is desired, which is the default).
 * See the paper on <a href="http:--lonesock.net/article/verlet.html">Time Corrected Verlet</a> for more information.
 *
 * Triggers `beforeUpdate` and `afterUpdate` events.
 * Triggers `collisionStart`, `collisionActive` and `collisionEnd` events.
 * @method update
 * @param {engine} engine
 * @param {number} [delta=16.666]
 * @param {number} [correction=1]
 ]]--

function Engine.update(engine, delta, correction)

	-- print('Engine.update', delta)

	delta = delta or 1000 / 30
	correction = correction or 1

	local world = engine.world
	local timing = engine.timing
	local broadphase = engine.broadphase
	local broadphasePairs = {}

	-- increment timestamp
	timing.timestamp += delta * timing.timeScale

	-- create an event object
	local event = {
		timestamp = timing.timestamp
	}

	Events.trigger(engine, 'beforeUpdate', event)

	-- get lists of all bodies and constraints, no matter what composites they are in

	local allBodies = Composite.allBodies(world)
	local allConstraints = Composite.allConstraints(world)


	-- @if DEBUG
	-- reset metrics logging
	-- Metrics.reset(engine.metrics)
	-- @endif

	-- if sleeping enabled, call the sleeping controller
	if (engine.enableSleeping) 	then
		Sleeping.update(allBodies, timing.timeScale)
	end

	-- applies gravity to all bodies
	Engine._bodiesApplyGravity(allBodies, world.gravity)

	-- update all body position and rotation by integration
	Engine._bodiesUpdate(allBodies, delta, timing.timeScale, correction, world.bounds)

	-- update all constraints (first pass)
	Constraint.preSolveAll(allBodies)

	for i = 1, engine.constraintIterations do
		Constraint.solveAll(allConstraints, timing.timeScale)
	end

	Constraint.postSolveAll(allBodies)

	-- broadphase pass: find potential collision pairs
	if (broadphase.controller) then

		-- if world is dirty, we must flush the whole grid

		if (world.isModified) then
			broadphase.controller.clear(broadphase)
		end

		-- update the grid buckets based on current bodies


-- sample('broadphase.update sample', function()
		broadphase.controller.update(broadphase, allBodies, engine, world.isModified)
-- end)


		broadphasePairs = broadphase.pairsList
	else
		-- if no broadphase set, we just pass all bodies

		broadphasePairs = allBodies
	end


	-- clear all composite modified flags
	if (world.isModified) then
		Composite.setModified(world, false, false, true)
	end

	-- narrowphase pass: find actual collisions, then create or update collision pairs
local collisions

		-- LOW LEAK!
-- sample(' broadphase.detector sample', function()
	 collisions = broadphase.detector(broadphasePairs, engine)
-- end)


	-- update collision pairs
	local pairs = engine.pairs
	local timestamp = timing.timestamp

	Pairs.update(pairs, collisions, timestamp)
	Pairs.removeOld(pairs, timestamp)

	-- wake up bodies involved in collisions
	if (engine.enableSleeping) 	then
		Sleeping.afterCollisions(pairs.list, timing.timeScale)
	end

	-- trigger collision events
	if (#pairs.collisionStart > 0) then
		Events.trigger(engine, 'collisionStart', { pairs = pairs.collisionStart })
	end

	-- iteratively resolve position between collisions
	Resolver.preSolvePosition(pairs.list)

	for i = 1, engine.positionIterations do
		Resolver.solvePosition(pairs.list, timing.timeScale)
	end

	Resolver.postSolvePosition(allBodies)

	-- update all constraints (second pass)

	Constraint.preSolveAll(allBodies)

	for i = 1, engine.constraintIterations do
		Constraint.solveAll(allConstraints, timing.timeScale)
	end

	Constraint.postSolveAll(allBodies)

	-- iteratively resolve velocity between collisions
	Resolver.preSolveVelocity(pairs.list)

	-- LOW LEAK!

-- sample('solveVelocity sample', function()
	for i = 1, engine.velocityIterations do
		Resolver.solveVelocity(pairs.list, timing.timeScale)
	end
-- end)
	-- trigger collision events

	if (#pairs.collisionActive > 0)	then
		Events.trigger(engine, 'collisionActive', { pairs = pairs.collisionActive })
	end

	if (#pairs.collisionEnd > 0)	then
		Events.trigger(engine, 'collisionEnd', { pairs = pairs.collisionEnd })
	end

	-- @if DEBUG
	-- update metrics log
	-- Metrics.update(engine.metrics, engine)
	-- @endif

	-- clear force buffers

	Engine._bodiesClearForces(allBodies)

	Events.trigger(engine, 'afterUpdate', event)

	return engine
end

--[[
 * Merges two engines by keeping the configuration of `engineA` but replacing the world with the one from `engineB`.
 * @method merge
 * @param {engine} engineA
 * @param {engine} engineB
 ]]--

function Engine.merge(engineA, engineB)
	Common.extend(engineA, engineB)

	if (engineB.world) then
		engineA.world = engineB.world

		Engine.clear(engineA)

		local bodies = Composite.allBodies(engineA.world)
		local n = #bodies

		for i = 1, n do
			local body = bodies[i]
			Sleeping.set(body, false)
			body.id = Common.nextId()
		end
	end
end

--[[
 * Clears the engine including the world, pairs and broadphase.
 * @method clear
 * @param {engine} engine
 ]]--

function Engine.clear(engine)
	local world = engine.world

	Pairs.clear(engine.pairs)

	local broadphase = engine.broadphase
	if (broadphase.controller) then
		local bodies = Composite.allBodies(world)
		broadphase.controller.clear(broadphase)
		broadphase.controller.update(broadphase, bodies, engine, true)
	end
end

--[[
 * Zeroes the `body.force` and `body.torque` force buffers.
 * @method _bodiesClearForces
 * @private
 * @param {body[]} bodies
 ]]--
function Engine._bodiesClearForces(bodies)
	local n = #bodies
	for i = 1, n do
		local body = bodies[i]

		-- reset force buffers
		body.force.x = 0
		body.force.y = 0
		body.torque = 0
	end
end

--[[
 * Applys a mass dependant force to all given bodies.
 * @method _bodiesApplyGravity
 * @private
 * @param {body[]} bodies
 * @param {vector} gravity
 ]]--

function Engine._bodiesApplyGravity(bodies, gravity)

	local gravityScale = (type(gravity.scale) ~= 'nil' and gravity.scale or 0.001)

	if ((gravity.x == 0 and gravity.y == 0) or gravityScale == 0) then
		return
	end

	local n = #bodies
	for i = 1, n do
		repeat
			local body = bodies[i]

			if (body.isStatic or body.isSleeping) then
				break
			end
			-- apply gravity
			body.force.y += body.mass * gravity.y * gravityScale
			body.force.x += body.mass * gravity.x * gravityScale
		break
		until true
	end
end

--[[
 * Applys `Body.update` to all given `bodies`.
 * @method _bodiesUpdate
 * @private
 * @param {body[]} bodies
 * @param {number} deltaTime
 * The amount of time elapsed between updates
 * @param {number} timeScale
 * @param {number} correction
 * The Verlet correction factor (deltaTime / lastDeltaTime)
 * @param {bounds} worldBounds
 ]]--

function Engine._bodiesUpdate(bodies, deltaTime, timeScale, correction, worldBounds)

	-- print('Engine._bodiesUpdate ', #bodies, deltaTime, timeScale, correction)

	local n = #bodies
	for i = 1, n do
		repeat
			local body = bodies[i]

			if (body.isStatic or body.isSleeping) then
				break
			end

			Body.update(body, deltaTime, timeScale, correction)
		break
		until true
	end
end

--[[
 * An alias for `Runner.run`, see `Matter.Runner` for more information.
 * @method run
 * @param {engine} engine
]]--

--[[
* Fired just before an update
*
* @event beforeUpdate
* @param {} event An event object
* @param {number} event.timestamp The engine.timing.timestamp of the event
* @param {} event.source The source object of the event
* @param {} event.name The name of the event
]]--

--[[
* Fired after engine update and all collision events
*
* @event afterUpdate
* @param {} event An event object
* @param {number} event.timestamp The engine.timing.timestamp of the event
* @param {} event.source The source object of the event
* @param {} event.name The name of the event
]]--

--[[
* Fired after engine update, provides a list of all pairs that have started to collide in the current tick (if any)
*
* @event collisionStart
* @param {} event An event object
* @param {} event.pairs List of affected pairs
* @param {number} event.timestamp The engine.timing.timestamp of the event
* @param {} event.source The source object of the event
* @param {} event.name The name of the event
]]--

--[[
* Fired after engine update, provides a list of all pairs that are colliding in the current tick (if any)
*
* @event collisionActive
* @param {} event An event object
* @param {} event.pairs List of affected pairs
* @param {number} event.timestamp The engine.timing.timestamp of the event
* @param {} event.source The source object of the event
* @param {} event.name The name of the event
]]--

--[[
* Fired after engine update, provides a list of all pairs that have ended collision in the current tick (if any)
*
* @event collisionEnd
* @param {} event An event object
* @param {} event.pairs List of affected pairs
* @param {number} event.timestamp The engine.timing.timestamp of the event
* @param {} event.source The source object of the event
* @param {} event.name The name of the event
]]--

--[[
*
*  Properties Documentation
*
]]--

--[[
 * An integer `Number` that specifies the number of position iterations to perform each update.
 * The higher the value, the higher quality the simulation will be at the expense of performance.
 *
 * @property positionIterations
 * @type number
 * @default 6
 ]]--

--[[
 * An integer `Number` that specifies the number of velocity iterations to perform each update.
 * The higher the value, the higher quality the simulation will be at the expense of performance.
 *
 * @property velocityIterations
 * @type number
 * @default 4
 ]]--

--[[
 * An integer `Number` that specifies the number of constraint iterations to perform each update.
 * The higher the value, the higher quality the simulation will be at the expense of performance.
 * The default value of `2` is usually very adequate.
 *
 * @property constraintIterations
 * @type number
 * @default 2
 ]]--

--[[
 * A flag that specifies whether the engine should allow sleeping via the `Matter.Sleeping` module.
 * Sleeping can improve stability and performance, but often at the expense of accuracy.
 *
 * @property enableSleeping
 * @type boolean
 * @default false
 ]]--

--[[
 * An `Object` containing properties regarding the timing systems of the engine.
 *
 * @property timing
 * @type object
 ]]--

--[[
 * A `Number` that specifies the global scaling factor of time for all bodies.
 * A value of `0` freezes the simulation.
 * A value of `0.1` gives a slow-motion effect.
 * A value of `1.2` gives a speed-up effect.
 *
 * @property timing.timeScale
 * @type number
 * @default 1
 ]]--

--[[
 * A `Number` that specifies the current simulation-time in milliseconds starting from `0`.
 * It is incremented on every `Engine.update` by the given `delta` argument.
 *
 * @property timing.timestamp
 * @type number
 * @default 0
 ]]--

--[[
 * An instance of a `Render` controller. The default value is a `Matter.Render` instance created by `Engine.create`.
 * One may also develop a custom renderer module based on `Matter.Render` and pass an instance of it to `Engine.create` via `options.render`.
 *
 * A minimal custom renderer object must define at least three functions: `create`, `clear` and `world` (see `Matter.Render`).
 * It is also possible to instead pass the _module_ reference via `options.render.controller` and `Engine.create` will instantiate one for you.
 *
 * @property render
 * @type render
 * @deprecated see Demo.js for an example of creating a renderer
 * @default a Matter.Render instance
 ]]--

--[[
 * An instance of a broadphase controller. The default value is a `Matter.Grid` instance created by `Engine.create`.
 *
 * @property broadphase
 * @type grid
 * @default a Matter.Grid instance
 ]]--

--[[
 * A `World` composite object that will contain all simulated bodies and constraints.
 *
 * @property world
 * @type world
 * @default a Matter.World instance
 ]]--

--[[
 * An object reserved for storing plugin-specific properties.
 *
 * @property plugin
 * @type {}
 ]]--

